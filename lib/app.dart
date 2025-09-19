import 'package:flutter/material.dart';
import 'screens/dashboard.dart';
import 'screens/onboarding.dart';
import 'utils/onboarding.dart';
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
      home: FutureBuilder<bool>(
        future: OnboardingUtils.isDone(),
        builder: (context, snap) {
          final done = snap.data ?? false;
          if (!snap.hasData) {
            return const SizedBox.shrink();
          }
          return done ? const Dashboard() : const OnboardingFlow();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
