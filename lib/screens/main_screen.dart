import 'package:flutter/material.dart';

import '../repositories/category_repository.dart';
import '../repositories/task_repository.dart';
import '../services/day_settings_controller.dart';
import '../services/day_settings_store.dart';
import 'calendar/calendar_page.dart';
import 'more_page.dart';
import 'placeholder_page.dart';
import 'today_page.dart';

class MainScreen extends StatefulWidget {
  final TaskRepository taskRepository;
  final CategoryRepository categoryRepository;

  const MainScreen({
    super.key,
    required this.taskRepository,
    required this.categoryRepository,
  });

  @override
  State<MainScreen> createState() =>
      _MainScreenState();
}

class _MainScreenState
    extends State<MainScreen> {
  int _selectedIndex = 0;

  late final DaySettingsController
      _daySettingsController;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _daySettingsController =
        DaySettingsController(
      store:
          const JsonDaySettingsStore(),
    );

    _daySettingsController.load();

    _pages = [
      TodayPage(
        taskRepository:
            widget.taskRepository,
        categoryRepository:
            widget.categoryRepository,
        daySettingsController:
            _daySettingsController,
      ),

      CalendarPage(
        taskRepository:
            widget.taskRepository,
        categoryRepository:
            widget.categoryRepository,
      ),

      const PlaceholderPage(
        title: 'Casa',
        icon: Icons.home_outlined,
      ),

      const PlaceholderPage(
        title: 'Spese',
        icon:
            Icons
                .account_balance_wallet_outlined,
      ),

      MorePage(
        daySettingsController:
            _daySettingsController,
      ),
    ];
  }

  @override
  void dispose() {
    _daySettingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: IndexedStack(
        index:
            _selectedIndex,
        children:
            _pages,
      ),

      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            _selectedIndex,

        onDestinationSelected:
            (index) {
          setState(() {
            _selectedIndex =
                index;
          });
        },

        destinations:
            const [
          NavigationDestination(
            icon:
                Icon(
              Icons
                  .calendar_today_outlined,
            ),
            selectedIcon:
                Icon(
              Icons
                  .calendar_today,
            ),
            label:
                'Oggi',
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons
                  .calendar_month_outlined,
            ),
            selectedIcon:
                Icon(
              Icons
                  .calendar_month,
            ),
            label:
                'Calendario',
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons
                  .home_outlined,
            ),
            selectedIcon:
                Icon(
              Icons.home,
            ),
            label:
                'Casa',
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons
                  .account_balance_wallet_outlined,
            ),
            selectedIcon:
                Icon(
              Icons
                  .account_balance_wallet,
            ),
            label:
                'Spese',
          ),

          NavigationDestination(
            icon:
                Icon(
              Icons
                  .more_horiz,
            ),
            selectedIcon:
                Icon(
              Icons
                  .more_horiz,
            ),
            label:
                'Altro',
          ),
        ],
      ),
    );
  }
}
