import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary =
      Color(0xFF6750A4);

  static const Color lightBackground =
      Color(0xFFF8F8FB);

  static const Color lightSurface =
      Color(0xFFFFFFFF);

  static const Color darkBackground =
      Color(0xFF111116);

  static const Color darkSurface =
      Color(0xFF1A1A21);

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      surface: lightSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          lightBackground,

      appBarTheme: const AppBarTheme(
        backgroundColor:
            lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),

      navigationBarTheme:
          NavigationBarThemeData(
        backgroundColor:
            lightSurface,
        indicatorColor:
            Colors.transparent,
        elevation: 0,
        height: 72,

        iconTheme:
            WidgetStateProperty.resolveWith(
          (states) {
            final selected =
                states.contains(
              WidgetState.selected,
            );

            return IconThemeData(
              size: 24,
              color: selected
                  ? colorScheme.primary
                  : colorScheme
                      .onSurfaceVariant,
            );
          },
        ),

        labelTextStyle:
            WidgetStateProperty.resolveWith(
          (states) {
            final selected =
                states.contains(
              WidgetState.selected,
            );

            return TextStyle(
              fontSize: 12,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: selected
                  ? colorScheme.primary
                  : colorScheme
                      .onSurfaceVariant,
            );
          },
        ),
      ),

      floatingActionButtonTheme:
          FloatingActionButtonThemeData(
        backgroundColor:
            colorScheme.primary,
        foregroundColor:
            colorScheme.onPrimary,
        elevation: 2,
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme
            .outlineVariant
            .withValues(
          alpha: 0.7,
        ),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
      seedColor:
          const Color(0xFFD0BCFF),
      brightness: Brightness.dark,
    ).copyWith(
      surface: darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          darkBackground,

      appBarTheme: const AppBarTheme(
        backgroundColor:
            darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),

      navigationBarTheme:
          NavigationBarThemeData(
        backgroundColor:
            darkSurface,
        indicatorColor:
            Colors.transparent,
        elevation: 0,
        height: 72,

        iconTheme:
            WidgetStateProperty.resolveWith(
          (states) {
            final selected =
                states.contains(
              WidgetState.selected,
            );

            return IconThemeData(
              size: 24,
              color: selected
                  ? colorScheme.primary
                  : colorScheme
                      .onSurfaceVariant,
            );
          },
        ),

        labelTextStyle:
            WidgetStateProperty.resolveWith(
          (states) {
            final selected =
                states.contains(
              WidgetState.selected,
            );

            return TextStyle(
              fontSize: 12,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: selected
                  ? colorScheme.primary
                  : colorScheme
                      .onSurfaceVariant,
            );
          },
        ),
      ),

      floatingActionButtonTheme:
          FloatingActionButtonThemeData(
        backgroundColor:
            colorScheme.primary,
        foregroundColor:
            colorScheme.onPrimary,
        elevation: 2,
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme
            .outlineVariant
            .withValues(
          alpha: 0.65,
        ),
        thickness: 1,
        space: 1,
      ),
    );
  }
}