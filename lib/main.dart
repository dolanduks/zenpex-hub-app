import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  runApp(const ZenpexHubApp());
}

class ZenpexHubApp extends StatelessWidget {
  const ZenpexHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenpex Hub',
      debugShowCheckedModeBanner: false,
      theme: buildZenpexTheme(),
      home: const SplashScreen(),
    );
  }
}
