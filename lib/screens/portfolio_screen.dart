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
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  String? _errorMessage;

  // === 1. ДОБАВЛЯЕМ КОНТРОЛЛЕР ДЛЯ ПОИСКА ===
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 2. СЛУШАЕМ ИЗМЕНЕНИЯ В ПОЛЕ ВВОДА
    _searchController.addListener(_fetchProjectsWithFilter);
    _fetchProjectsWithFilter(); // Первоначальная загрузка
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // === 3. ПЕРЕИМЕНОВЫВАЕМ И ОБНОВЛЯЕМ ФУНКЦИЮ ЗАГРУЗКИ ===
  Future<void> _fetchProjectsWithFilter() async {
    // Не показываем главный индикатор при каждой букве, только при первой загрузке
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final searchQuery = _searchController.text;

      var query = supabase.from('projects_with_authors').select('*');

      // Если в строке поиска что-то есть
      if (searchQuery.isNotEmpty) {
        // Ищем вхождение текста в описании без учета регистра
        query = query.ilike('description', '%$searchQuery%');
      }

      final data = await query.order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _projects = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки проектов: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // === 4. ОБВОРАЧИВАЕМ ВСЕ В COLUMN ===
      body: Column(
        children: [
          // === 5. ДОБАВЛЯЕМ ПОЛЕ ДЛЯ ПОИСКА ===
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по #хэштегу в описании...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
              ),
            ),
          ),

          // === 6. ОБВОРАЧИВАЕМ GRIDVIEW В EXPANDED ===
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _projects.isEmpty
                ? const Center(child: Text('Проектов не найдено'))
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProjectDetailsScreen(project: project),
                              ),
                            );
                            if (result == true) {
                              _fetchProjectsWithFilter(); // Используем новую функцию
                            }
                          },
                          child: GridTile(
                            footer: Container(
                              padding: const EdgeInsets.all(8.0),
                              color: Colors.black.withValues(alpha: .6),
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
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Icon(Icons.broken_image),
                                            ),
                                  )
                                : Container(color: Colors.grey[800]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newProject = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddProjectScreen()),
          );
          if (newProject != null && newProject is Map<String, dynamic>) {
            // === 7. ОБНОВЛЯЕМ ЛОГИКУ ДОБАВЛЕНИЯ ===
            // Вместо ручного добавления, просто перезагружаем список с учетом фильтра
            _fetchProjectsWithFilter();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
