// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isLoading = true;
  bool _isRegistered = false;
  int _registrationCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final userId = supabase.auth.currentUser!.id;
    final eventId = widget.event['id'];

    try {
      final responses = await Future.wait([
        supabase
            .from('event_users')
            .select()
            .eq('user_id', userId)
            .eq('event_id', eventId),
        supabase.rpc(
          'get_event_registrations_count',
          params: {'p_event_id': eventId},
        ),
      ]);

      final registrationStatusResponse = responses[0] as List;
      final registrationCountResponse = responses[1];

      if (mounted) {
        setState(() {
          _isRegistered = registrationStatusResponse.isNotEmpty;
          _registrationCount = registrationCountResponse;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных о событии: $e')),
      );
    }
  }

  Future<void> _toggleRegistration() async {
    setState(() {
      _isLoading = true;
    });

    final userId = supabase.auth.currentUser!.id;
    final eventId = widget.event['id'];

    try {
      if (_isRegistered) {
        await supabase.from('event_users').delete().match({
          'user_id': userId,
          'event_id': eventId,
        });
        if (mounted) setState(() => _registrationCount--);
      } else {
        await supabase.from('event_users').insert({
          'user_id': userId,
          'event_id': eventId,
        });
        if (mounted) setState(() => _registrationCount++);
      }

      if (mounted) {
        setState(() {
          _isRegistered = !_isRegistered;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось выполнить действие')),
      );
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
    final eventType = widget.event['event_type'];
    final imageUrl = widget.event['cover_image_url'];

    return Scaffold(
      appBar: AppBar(title: Text(widget.event['name'] ?? 'Детали события')),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 200,
                child: Center(child: Icon(Icons.hide_image_outlined, size: 50)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event['name'] ?? 'Без названия',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 16),
                    const SizedBox(width: 8),
                    Text('Идут: $_registrationCount'),
                  ],
                ),
                const SizedBox(height: 8.0),

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
                    Text(widget.event['location'] ?? 'Место не указано'),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Начало: ${widget.event['start_date'] ?? 'не указана'}',
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                const Divider(),
                const SizedBox(height: 16.0),
                Text(
                  'Описание',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  widget.event['description'] ?? 'Описание отсутствует.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32.0),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _toggleRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRegistered
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(
                      _isRegistered
                          ? 'Вы зарегистрированы (Отменить)'
                          : 'Зарегистрироваться',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
