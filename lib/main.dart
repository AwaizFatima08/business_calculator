import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads/ads.dart';
import 'app.dart';
import 'core/calculator.dart';
import 'services/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final calculator = Calculator();
  final store = await CalculatorStore.open(calculator);
  final settings = await Settings.load();
  runApp(
    BusinessCalculatorApp(
      services: AppServices(calculator: calculator, settings: settings, ads: AdService.fromEnvironment(), store: store),
    ),
  );
}
