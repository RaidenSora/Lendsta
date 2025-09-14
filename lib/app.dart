import 'package:flutter/material.dart';
import 'screens/dashboard.dart';
import 'theme/theme.dart';

class ListahApp extends StatelessWidget {
  const ListahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lendsta',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const Dashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}
