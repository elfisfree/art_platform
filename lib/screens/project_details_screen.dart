import 'package:flutter/material.dart';

class ProjectDetailsScreen extends StatelessWidget {
  // Мы будем передавать всю информацию о проекте в этот экран
  final Map<String, dynamic> project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    // Для удобства вытащим вложенный объект с данными автора
    final author = project['users'];
    final imageUrl = project['image_url'];

    return Scaffold(
      appBar: AppBar(
        // В заголовок вынесем название проекта
        title: Text(project['title'] ?? 'Детали проекта'),
      ),
      body: ListView(
        // Убираем внутренние отступы у ListView, чтобы картинка прилегала к краям
        padding: EdgeInsets.zero,
        children: [
          // === Большое изображение проекта ===
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              // Можно задать высоту или использовать AspectRatio
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 300,
                child: Center(child: Icon(Icons.broken_image, size: 50)),
              ),
            ),

          // === Контент с отступами ===
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Название проекта
                Text(
                  project['title'] ?? 'Без названия',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12.0),

                // Автор проекта
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      author?['full_name'] ?? 'Автор не указан',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),

                // Разделитель
                const Divider(),
                const SizedBox(height: 16.0),

                // Полное описание
                Text(
                  'Описание проекта',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  project['description'] ?? 'Описание отсутствует.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
