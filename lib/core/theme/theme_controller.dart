import 'package:flutter/material.dart';
import '../data_repository.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  static final DataRepository _repo = DataRepository();

  static Future<void> initialize() async {
    themeMode.value = await _repo.getTheme();
  }

  static void toggleTheme() {
    themeMode.value = themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _repo.saveTheme(themeMode.value);
  }

  static void setTheme(ThemeMode mode) {
    themeMode.value = mode;
    _repo.saveTheme(mode);
  }
}
