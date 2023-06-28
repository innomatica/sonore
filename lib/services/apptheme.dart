import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme(ColorScheme? lightDynamic) {
    final scheme = lightDynamic ??
        ColorScheme.fromSeed(
            brightness: Brightness.light, seedColor: Colors.redAccent);
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }

  static ThemeData darkTheme(ColorScheme? darkDynamic) {
    final scheme = darkDynamic ??
        ColorScheme.fromSeed(
            brightness: Brightness.dark, seedColor: Colors.redAccent);
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }
}
