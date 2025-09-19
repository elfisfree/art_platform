import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ProjectDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  const ProjectDetailsScreen({super.key, required this.project});
  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  late final Future<List<Map<String, dynamic>>> _imagesFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imagesFuture = _getProjectImages();
  }

  Future<List<Map<String, dynamic>>> _getProjectImages() async {
    try {
      final response = await supabase
          .from('project_images')
          .select('image_url')
          .eq('project_id', widget.project['id']);
      return response;
    } catch (e) {
      return [];
    }
  }

  Future<void> _deleteProject() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projectId = widget.project['id'];
      final imagesResponse = await supabase
          .from('project_images')
          .select('image_url')
          .eq('project_id', projectId);
      final List<String> pathsToDelete = [];
      for (final image in imagesResponse) {
        final imageUrl = image['image_url'];
        final path = Uri.parse(imageUrl).pathSegments.sublist(5).join('/');
        pathsToDelete.add(path);
      }
      if (pathsToDelete.isNotEmpty) {
        await supabase.storage.from('project_images').remove(pathsToDelete);
      }
      await supabase.from('projects').delete().match({'id': projectId});

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Проект успешно удален')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при удалении проекта: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Подтверждение'),
          content: const Text(
            'Вы уверены, что хотите удалить этот проект? Все связанные с ним изображения будут удалены безвозвратно.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteProject();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = supabase.auth.currentUser!.id;
    final isAuthor = currentUserId == widget.project['user_id'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project['title'] ?? 'Детали проекта'),
        actions: [
          if (isAuthor)
            IconButton(
              onPressed: _showDeleteConfirmationDialog,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Удалить проект',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.project['title'] ?? 'Без названия',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.project['full_name'] ?? 'Автор не указан',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          widget.project['description'] ??
                              'Описание отсутствует.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24.0),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Галерея проекта',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _imagesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(child: Text('Изображения не найдены.')),
                      );
                    }
                    final images = snapshot.data!;
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final imageUrl = images[index]['image_url'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  const AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Center(
                                      child: Icon(Icons.broken_image, size: 40),
                                    ),
                                  ),
                            ),
                          ),
                        );
                      }, childCount: images.length),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
