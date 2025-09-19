import 'package:art_platform/screens/home_screen.dart';
import 'package:art_platform/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect(); // Вызываем метод перенаправления при инициализации
  }

  Future<void> _redirect() async {
    // Ждем небольшую задержку, чтобы пользователь успел увидеть заставку
    await Future.delayed(Duration.zero);

    final session = Supabase.instance.client.auth.currentSession;

    if (!mounted) return;

    if (session != null) {
      // Если сессия есть, переходим на главный экран
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Если сессии нет, переходим на экран входа
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ), // Простой индикатор загрузки
    );
  }
}
