import 'package:art_platform/screens/event_details_screen.dart';
import 'package:art_platform/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<EventsListScreen> {
  late final Future<List<Map<String, dynamic>>?> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _getEvents();
  }

  Future<List<Map<String, dynamic>>?> _getEvents() async {
    // ... (эта функция остается без изменений) ...
    try {
      final data = await supabase
          .from('events')
          .select('*, event_type(type_name)')
          .order('start_date', ascending: true);
      return data;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки мероприятий: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _signOut() async {
    // ... (эта функция остается без изменений) ...
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          // ... (логика загрузки, ошибок и пустого списка остается без изменений) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Не удалось загрузить данные'));
          }
          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(child: Text('Предстоящих мероприятий нет'));
          }

          // === НАЧАЛО ОБНОВЛЕННОЙ ВЕРСТКИ ===
          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final eventType = event['event_type'];
              final imageUrl = event['cover_image_url'];

              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 16.0),
                // Устанавливаем форму с закругленными углами
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EventDetailsScreen(event: event),
                      ),
                    );
                  },
                  // Используем Stack, чтобы наложить виджеты друг на друга
                  child: Stack(
                    // Выравниваем текст по нижнему краю
                    alignment: Alignment.bottomLeft,
                    children: [
                      // Слой 1: Изображение
                      // Оборачиваем в SizedBox, чтобы задать фиксированную высоту карточке
                      SizedBox(
                        height: 200,
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? Image.network(
                                imageUrl,
                                width: double.infinity,
                                fit: BoxFit
                                    .cover, // BoxFit.cover теперь работает идеально
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 40,
                                      ),
                                    ),
                              )
                            : Container(
                                color: Colors.grey[800],
                              ), // Заглушка, если нет картинки
                      ),

                      // Слой 2: Градиент для затемнения нижней части изображения
                      // Это нужно, чтобы белый текст всегда был читаемым
                      Container(
                        height: 200,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                          ),
                        ),
                      ),

                      // Слой 3: Текст
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          // Выравниваем текст по левому краю
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // mainAxisSize.min чтобы колонка не занимала всю высоту стека
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              event['name'] ?? 'Без названия',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${eventType?['type_name'] ?? 'Событие'} | ${event['location'] ?? 'Место не указано'}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Слой 4: Дата (позиционируем в правом верхнем углу)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            event['start_date'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          // === КОНЕЦ ОБНОВЛЕННОЙ ВЕРСТКИ ===
        },
      ),
    );
  }
}
