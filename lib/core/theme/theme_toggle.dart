import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, child) {
        final isDark = mode == ThemeMode.dark ||
            (mode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);

        return IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          onPressed: () => ThemeController.toggleTheme(),
          tooltip: 'Toggle Dark/Light Mode',
        );
      },
    );
  }
}
