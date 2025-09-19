import 'package:flutter/material.dart';

class EventDetailsScreen extends StatelessWidget {
  // Мы будем передавать всю информацию о событии в этот экран
  final Map<String, dynamic> event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Для удобства вытащим вложенный объект с типом события
    final eventType = event['event_type'];

    return Scaffold(
      appBar: AppBar(
        // В заголовок вынесем название события
        title: Text(event['name'] ?? 'Детали события'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Название события
          Text(
            event['name'] ?? 'Без названия',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16.0),

          // Блок с информацией: Тип, Место, Дата
          Row(
            children: [
              const Icon(Icons.category_outlined, size: 16),
              const SizedBox(width: 8),
              Text(eventType?['type_name'] ?? 'Событие'),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16),
              const SizedBox(width: 8),
              Text(event['location'] ?? 'Место не указано'),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16),
              const SizedBox(width: 8),
              Text('Начало: ${event['start_date'] ?? 'не указана'}'),
            ],
          ),
          const SizedBox(height: 24.0),

          // Разделитель
          const Divider(),
          const SizedBox(height: 16.0),

          // Полное описание
          Text(
            'Описание',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            event['description'] ?? 'Описание отсутствует.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32.0),

          // Кнопка регистрации (пока без логики)
          ElevatedButton(
            onPressed: () {
              // TODO: Добавить логику регистрации на мероприятие
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Функция регистрации в разработке'),
                ),
              );
            },
            child: const Text('Зарегистрироваться'),
          ),
        ],
      ),
    );
  }
}
