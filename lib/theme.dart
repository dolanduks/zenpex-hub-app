import 'package:flutter/material.dart';

/// Paleta do Manual de Marca Zenpex 2025.
abstract final class ZenpexColors {
  static const black = Color(0xFF060608);
  static const navy = Color(0xFF002555);
  static const blue = Color(0xFF576AFF);
  static const lightBlue = Color(0xFFD0DBFE);
  static const offWhite = Color(0xFFF5F7FE);

  // Superfícies do tema escuro, derivadas do preto e do marinho da marca.
  static const surface = Color(0xFF0D1018);
  static const surfaceHigh = Color(0xFF151A27);
  static const outline = Color(0xFF232A3D);
  static const textMuted = Color(0xFF8A93AD);

  static const ok = Color(0xFF3CC48A);
}

/// Fonte "mono" do app: algarismos da JetBrains Mono (ZenpexDigits) e todo o
/// resto da Aber Mono, via fallback.
const monoFamily = 'ZenpexDigits';
const monoFallback = ['AberMono'];

ThemeData buildZenpexTheme() {
  const scheme = ColorScheme.dark(
    primary: ZenpexColors.blue,
    onPrimary: Colors.white,
    secondary: ZenpexColors.lightBlue,
    surface: ZenpexColors.surface,
    onSurface: ZenpexColors.offWhite,
    outline: ZenpexColors.outline,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: ZenpexColors.black,
    fontFamily: 'PPMori',
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: ZenpexColors.offWhite,
      displayColor: ZenpexColors.offWhite,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ZenpexColors.black,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    dividerColor: ZenpexColors.outline,
  );
}
