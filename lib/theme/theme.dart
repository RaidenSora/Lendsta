import 'package:flutter/material.dart';

ThemeData buildLightTheme() {
  final base = ThemeData(
    colorSchemeSeed: const Color(0xFF4F46E5),
    useMaterial3: true,
  );
  return base.copyWith(appBarTheme: const AppBarTheme(centerTitle: false));
}

ThemeData buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true).copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF818CF8),
      brightness: Brightness.dark,
    ),
  );
  return base;
}
