import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});
  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  List<XFile> _selectedImages = [];

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _publishProject() async {
    if (!_formKey.currentState!.validate() || _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Пожалуйста, заполните все поля и выберите хотя бы одно изображение',
          ),
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser!;
      final userId = user.id;

      // 1. Создаем проект
      final newProject = await supabase
          .from('projects')
          .insert({
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'user_id': userId,
          })
          .select()
          .single();

      final projectId = newProject['id'];
      String? coverImageUrl;

      // 2. Загружаем картинки
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        final file = File(image.path);
        final fileExtension = image.path.split('.').last;
        final filePath =
            '$userId/$projectId/${DateTime.now().millisecondsSinceEpoch}_$i.$fileExtension';

        await supabase.storage.from('project_images').upload(filePath, file);
        final imageUrl = supabase.storage
            .from('project_images')
            .getPublicUrl(filePath);

        await supabase.from('project_images').insert({
          'project_id': projectId,
          'image_url': imageUrl,
        });

        coverImageUrl ??= imageUrl;
      }

      // 3. Обновляем проект, добавляя обложку
      final updatedProject = await supabase
          .from('projects')
          .update({'cover_image_url': coverImageUrl})
          .eq('id', projectId)
          .select()
          .single();

      // 4. СОЗДАЕМ ОБЪЕКТ ДЛЯ ВОЗВРАТА ВРУЧНУЮ
      // Мы берем все данные из обновленного проекта
      // и добавляем full_name из уже известного нам пользователя
      final Map<String, dynamic> projectToReturn = {
        ...updatedProject,
        'full_name': user.userMetadata?['full_name'] ?? '',
      };

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Проект успешно опубликован!')),
        );
        Navigator.of(context).pop(projectToReturn);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при публикации проекта: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // BUILD МЕТОД ОСТАЕТСЯ БЕЗ ИЗМЕНЕНИЙ
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить новый проект')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return InkWell(
                      onTap: _pickImages,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade400,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return Image.file(
                    File(_selectedImages[index].path),
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Название проекта'),
              validator: (v) =>
                  v!.isEmpty ? 'Название не может быть пустым' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Описание проекта'),
              maxLines: 4,
              validator: (v) =>
                  v!.isEmpty ? 'Описание не может быть пустым' : null,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _publishProject,
                    child: const Text('Опубликовать'),
                  ),
          ],
        ),
      ),
    );
  }
}
