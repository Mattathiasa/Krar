import 'package:flutter/material.dart';
import 'screens/studio_screen.dart';

void main() {
  runApp(const KrarApp());
}

class KrarApp extends StatelessWidget {
  const KrarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krar & Begena Studio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B4513),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const StudioScreen(),
    );
  }
}
