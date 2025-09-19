import 'package:art_platform/screens/splash_screen.dart'; // Мы создадим этот файл следующим
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализируем Supabase с вашими реальными данными
  await Supabase.initialize(
    url: 'https://kcwujrdzeywnhicbjtwn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtjd3VqcmR6ZXl3bmhpY2JqdHduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxMjY0NDYsImV4cCI6MjA3MzcwMjQ0Nn0.A0d-7uvyHZZXESF0RhTHT_D4snVIG0YU5qPXGd2dTcc',
  );
  runApp(const MyApp());
}

// Глобальная переменная для удобного доступа к клиенту Supabase
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Арт-площадка',
      theme: ThemeData.dark().copyWith(
        // Используем темную тему, как на вашей схеме :)
        primaryColor: Colors.deepPurple,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.deepPurple,
          ),
        ),
      ),
      // Наше приложение будет начинаться со Splash экрана
      home: const SplashScreen(),
    );
  }
}
