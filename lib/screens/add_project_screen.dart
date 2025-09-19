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

  // Переменная для хранения выбранного файла изображения
  XFile? _selectedImage;

  // Функция для выбора изображения из галереи
  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final image = await imagePicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  // Основная функция публикации проекта
  Future<void> _publishProject() async {
    // Проверяем, что форма заполнена и изображение выбрано
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пожалуйста, выберите изображение проекта'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
      final file = File(_selectedImage!.path);
      final fileExtension = _selectedImage!.path.split('.').last;
      // Создаем уникальное имя файла: user_id/текущее_время.расширение
      final filePath =
          '$userId/${DateTime.now().toIso8601String()}.$fileExtension';

      // 1. Загружаем изображение в Supabase Storage
      await supabase.storage.from('project_images').upload(filePath, file);

      // 2. Получаем публичную ссылку на загруженное изображение
      final imageUrl = supabase.storage
          .from('project_images')
          .getPublicUrl(filePath);

      // 3. Сохраняем данные проекта в таблицу 'projects'
      await supabase.from('projects').insert({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
        'user_id': userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Проект успешно опубликован!')),
        );
        // Возвращаемся на предыдущий экран
        Navigator.of(context).pop(true);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить новый проект')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // === Блок выбора изображения ===
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImage != null
                    // Если изображение выбрано, показываем его
                    ? Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                    // Если нет - показываем приглашение
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text('Нажмите, чтобы выбрать фото'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            // === Поля для ввода текста ===
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Название проекта'),
              validator: (value) =>
                  value!.isEmpty ? 'Название не может быть пустым' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Описание проекта'),
              maxLines: 4,
              validator: (value) =>
                  value!.isEmpty ? 'Описание не может быть пустым' : null,
            ),
            const SizedBox(height: 24),
            // === Кнопка публикации ===
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
