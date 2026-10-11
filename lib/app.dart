import 'package:flutter/material.dart';

import 'ads/ads.dart';
import 'core/calculator.dart';
import 'services/storage.dart';
import 'views/calculator_page.dart';

const appName = 'Business Calculator';

/// Daylight palette: high contrast on a light, matte background so the
/// display and keys stay readable in sunlight and under office lights.
abstract final class Palette {
  static const background = Color(0xFFE9ECE6);
  static const display = Color(0xFFFBFCF8);
  static const displayBorder = Color(0xFFC4CABD);
  static const ink = Color(0xFF0F1419);
  static const inkSoft = Color(0xFF4A5560);
  static const inkFaint = Color(0xFF7C8791);

  static const digitKey = Color(0xFFFFFFFF);
  static const keyBorder = Color(0xFFC4CABD);
  static const opKey = Color(0xFF1F3A5F);
  static const opText = Color(0xFFFFFFFF);
  static const fnKey = Color(0xFFD9E0E7);
  static const fnText = Color(0xFF1F3A5F);
  static const memKey = Color(0xFFE2E7DD);
  static const taxKey = Color(0xFFFCEBC7);
  static const taxText = Color(0xFF6B4200);
  static const clearText = Color(0xFFB3261E);
  static const equalsKey = Color(0xFF0E7A4F);

  static const accent = Color(0xFF0E7A4F);
  static const error = Color(0xFFB3261E);
}

class AppServices {
  AppServices({required this.calculator, required this.settings, required this.ads, this.store});

  final Calculator calculator;
  final Settings settings;
  final AdService ads;
  final CalculatorStore? store;
}

class BusinessCalculatorApp extends StatelessWidget {
  const BusinessCalculatorApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Palette.opKey,
      brightness: Brightness.light,
      surface: Palette.background,
      primary: Palette.opKey,
      secondary: Palette.accent,
      error: Palette.error,
    );
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      // Daylight theme only, by design.
      themeMode: ThemeMode.light,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: Palette.background,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Palette.background,
          foregroundColor: Palette.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Palette.display),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      home: CalculatorPage(services: services),
    );
  }
}
