import 'package:art_platform/screens/add_project_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:art_platform/screens/project_details_screen.dart';

final supabase = Supabase.instance.client;

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late Future<List<Map<String, dynamic>>?> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = _getProjects();
  }

  Future<List<Map<String, dynamic>>?> _getProjects() async {
    try {
      // Выбираем все проекты и из связанной таблицы users берем full_name
      final data = await supabase
          .from('projects')
          .select('*, users(full_name)')
          .order('created_at', ascending: false); // Новые проекты сверху
      return data;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки проектов: $e')));
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Используем FutureBuilder для асинхронной загрузки
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Не удалось загрузить проекты'));
          }
          final projects = snapshot.data!;
          if (projects.isEmpty) {
            return const Center(
              child: Text('Пока не добавлено ни одного проекта'),
            );
          }

          // Используем GridView для отображения сетки
          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            // Указываем, что в сетке будет 2 колонки
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.8, // Соотношение сторон карточки
            ),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final author = project['users'];
              final imageUrl = project['image_url'];

              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  // === ЗАМЕНЯЕМ ЭТОТ БЛОК ===
                  onTap: () {
                    // Логика перехода на новый экран
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        // Создаем экземпляр ProjectDetailsScreen и передаем ему данные
                        builder: (context) =>
                            ProjectDetailsScreen(project: project),
                      ),
                    );
                  },
                  // === КОНЕЦ БЛОКА ДЛЯ ЗАМЕНЫ ===
                  child: GridTile(
                    footer: Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.black.withOpacity(0.6),
                      child: Text(
                        project['title'] ?? 'Без названия',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.broken_image)),
                          )
                        : Container(color: Colors.grey[800]),
                  ),
                ),
              );
            },
          );
        },
      ),
      // Плавающая кнопка для добавления нового проекта
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddProjectScreen()),
          );
          if (result == true && mounted) {
            setState(() {
              _projectsFuture = _getProjects();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
