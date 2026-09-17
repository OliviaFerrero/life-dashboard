import 'package:flutter/material.dart';

import '../repositories/task_repository.dart';
import 'placeholder_page.dart';
import 'today_page.dart';

class MainScreen extends StatefulWidget {
  final TaskRepository taskRepository;

  const MainScreen({
    super.key,
    required this.taskRepository,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      TodayPage(
        taskRepository: widget.taskRepository,
      ),
      const PlaceholderPage(
        title: 'Abitudini',
        icon: Icons.check_circle_outline,
      ),
      const PlaceholderPage(
        title: 'Casa',
        icon: Icons.home_outlined,
      ),
      const PlaceholderPage(
        title: 'Spese',
        icon: Icons.account_balance_wallet_outlined,
      ),
      const PlaceholderPage(
        title: 'Altro',
        icon: Icons.more_horiz,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Oggi',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Abitudini',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Casa',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Spese',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Altro',
          ),
        ],
      ),
    );
  }
}