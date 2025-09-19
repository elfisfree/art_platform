import 'package:art_platform/screens/events_list_screen.dart';
import 'package:art_platform/screens/login_screen.dart';
import 'package:art_platform/screens/portfolio_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Индекс выбранной вкладки (0 - Афиша, 1 - Портфолио)
  int _selectedIndex = 0;

  // Список заголовков для AppBar
  static const List<String> _appBarTitles = <String>['Афиша', 'Портфолио'];

  // Список экранов, соответствующих вкладкам
  static const List<Widget> _pages = <Widget>[
    EventsListScreen(),
    PortfolioScreen(),
  ];

  // Функция для выхода из аккаунта
  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Удаляем все предыдущие экраны
      );
    }
  }

  // Функция для смены вкладок
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Заголовок меняется в зависимости от выбранной вкладки
        title: Text(_appBarTitles[_selectedIndex]),
        actions: [
          // Кнопка выхода всегда на месте
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
          ),
        ],
      ),
      // Тело экрана - это один из экранов из списка _pages
      body: IndexedStack(index: _selectedIndex, children: _pages),
      // Нижняя навигационная панель
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Афиша',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            activeIcon: Icon(Icons.photo_library),
            label: 'Портфолио',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Функция, которая вызывается при нажатии
      ),
    );
  }
}
