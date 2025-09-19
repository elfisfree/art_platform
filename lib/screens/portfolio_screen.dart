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
  // === ИЗМЕНЕНИЕ 1: Убираем Future, работаем с обычным списком и состоянием загрузки ===
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getInitialProjects();
  }

  Future<void> _getInitialProjects() async {
    try {
      final data = await supabase
          .from('projects_with_authors')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _projects = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки проектов: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // === ИЗМЕНЕНИЕ 2: Убираем FutureBuilder, используем простую логику отображения ===
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _projects.isEmpty
          ? const Center(child: Text('Пока не добавлено ни одного проекта'))
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.8,
              ),
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                final project = _projects[index];
                final imageUrl = project['cover_image_url'];

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    // === ВОТ ПРАВИЛЬНЫЙ КОД ДЛЯ onTap ===
                    onTap: () async {
                      // Логика перехода на экран деталей
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ProjectDetailsScreen(project: project),
                        ),
                      );

                      // Эта логика для обновления после удаления, она нам еще понадобится
                      if (result == true) {
                        setState(() {
                          // Это вызовет ошибку, если _getInitialProjects не объявлен.
                          // Убедитесь, что _getInitialProjects существует в вашем классе _PortfolioScreenState.
                          _getInitialProjects();
                        });
                      }
                    },
                    // ===================================
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
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // === ИЗМЕНЕНИЕ 3: Ждем не true, а сам объект проекта ===
          final newProject = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddProjectScreen()),
          );

          // Если вернулся новый проект, добавляем его в начало списка
          if (newProject != null && newProject is Map<String, dynamic>) {
            setState(() {
              _projects.insert(0, newProject);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
