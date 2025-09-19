import 'package:art_platform/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:art_platform/screens/event_details_screen.dart';

// Для удобства вынесем переменную supabase в глобальную область (если еще не сделали в main.dart)
final supabase = Supabase.instance.client;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Эта переменная будет хранить Future (обещание) с нашими данными
  late final Future<List<Map<String, dynamic>>?> _eventsFuture;

  @override
  void initState() {
    super.initState();
    // Запускаем загрузку данных при инициализации экрана
    _eventsFuture = _getEvents();
  }

  // Асинхронная функция для получения данных из Supabase
  Future<List<Map<String, dynamic>>?> _getEvents() async {
    try {
      final data = await supabase
          .from('events')
          .select('*, event_type(type_name)')
          .order('start_date', ascending: true); // Сортируем по дате начала
      return data;
    } catch (error) {
      // Обработка ошибок
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ошибка загрузки мероприятий'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _signOut() async {
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
      appBar: AppBar(
        title: const Text('Афиша'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
          ),
        ],
      ),
      // FutureBuilder следит за состоянием Future и перерисовывает UI
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          // 1. Пока ждем данные, показываем индикатор загрузки
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Если произошла ошибка
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Не удалось загрузить данные'));
          }
          // 3. Если данные пришли, но список пуст
          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(child: Text('Предстоящих мероприятий нет'));
          }

          // 4. Если все хорошо, строим список
          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final eventType = event['event_type']; // Это вложенный объект

              return InkWell(
                onTap: () {
                  // Логика перехода на новый экран
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      // Создаем экземпляр EventDetailsScreen и передаем ему данные
                      builder: (context) => EventDetailsScreen(event: event),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    title: Text(event['name'] ?? 'Без названия'),
                    subtitle: Text(
                      '${eventType?['type_name'] ?? 'Событие'} | ${event['location'] ?? 'Место не указано'}',
                    ),
                    trailing: Text(event['start_date'] ?? ''),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
