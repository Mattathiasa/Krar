import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'theme/studio_theme.dart';

void main() {
  runApp(const KrarApp());
}

class KrarApp extends StatelessWidget {
  const KrarApp({super.key, this.home});

  /// Overrides the shell in tests.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krar & Begena Studio',
      debugShowCheckedModeBanner: false,
      theme: buildStudioTheme(),
      home: home ?? const AppShell(),
    );
  }
}
