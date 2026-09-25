import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/id/id_generator.dart';
import 'core/time/app_clock.dart';
import 'database/app_database.dart';
import 'repositories/category_repository.dart';
import 'repositories/task_repository.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  final database = AppDatabase();

  final taskRepository =
      TaskRepository(database);

  final categoryRepository =
      CategoryRepository(database);

  final appClock =
      AppClock();

  final idGenerator =
      IdGenerator();

  runApp(
    IdGeneratorScope(
      generator:
          idGenerator,
      child:
          LifeDashboardApp(
        taskRepository:
            taskRepository,
        categoryRepository:
            categoryRepository,
        appClock:
            appClock,
      ),
    ),
  );
}

class LifeDashboardApp
    extends StatelessWidget {
  final TaskRepository taskRepository;
  final CategoryRepository categoryRepository;
  final AppClock appClock;

  const LifeDashboardApp({
    super.key,
    required this.taskRepository,
    required this.categoryRepository,
    required this.appClock,
  });

  @override
  Widget build(BuildContext context) {
    return AppClockScope(
      clock:
          appClock,
      child:
          MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Life Dashboard',

      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      builder: (context, child) {
        final brightness =
            Theme.of(context).brightness;

        final isDark =
            brightness == Brightness.dark;

        final overlayStyle =
            SystemUiOverlayStyle(
          statusBarColor:
              Colors.transparent,

          statusBarIconBrightness:
              isDark
                  ? Brightness.light
                  : Brightness.dark,

          statusBarBrightness:
              isDark
                  ? Brightness.dark
                  : Brightness.light,

          systemNavigationBarColor:
              Colors.transparent,

          systemNavigationBarDividerColor:
              Colors.transparent,

          systemNavigationBarIconBrightness:
              isDark
                  ? Brightness.light
                  : Brightness.dark,

          systemNavigationBarContrastEnforced:
              false,
        );

        return AnnotatedRegion<
            SystemUiOverlayStyle>(
          value: overlayStyle,
          child:
              child ?? const SizedBox.shrink(),
        );
      },

      home: MainScreen(
        taskRepository: taskRepository,
        categoryRepository:
            categoryRepository,
      ),
          ),
    );
  }
}