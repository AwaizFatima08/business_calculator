import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/calculator.dart';
import '../core/format.dart';

/// User preferences, saved on the phone.
class Settings extends ChangeNotifier {
  Settings._(this._prefs);

  final SharedPreferences _prefs;

  static Future<Settings> load() async => Settings._(await SharedPreferences.getInstance());

  static const placesChoices = <Places>[null, 0, 2, 3, 4];
  static final defaultTaxRate = Decimal.fromInt(18);

  /// Digits after the point for results; null = automatic.
  Places get places {
    final v = _prefs.getInt('places') ?? -1;
    return v < 0 ? null : v;
  }

  set places(Places v) {
    _prefs.setInt('places', v ?? -1);
    notifyListeners();
  }

  Decimal get taxRate => Decimal.tryParse(_prefs.getString('taxRate') ?? '') ?? defaultTaxRate;

  set taxRate(Decimal v) {
    _prefs.setString('taxRate', v.toString());
    notifyListeners();
  }

  bool get grouping => _prefs.getBool('grouping') ?? true;

  set grouping(bool v) {
    _prefs.setBool('grouping', v);
    notifyListeners();
  }

  bool get haptics => _prefs.getBool('haptics') ?? true;

  set haptics(bool v) {
    _prefs.setBool('haptics', v);
    notifyListeners();
  }

  bool get clickSound => _prefs.getBool('clickSound') ?? false;

  set clickSound(bool v) {
    _prefs.setBool('clickSound', v);
    notifyListeners();
  }

  /// Formats a result with the user's choices.
  String value(Decimal v, {bool ascii = false}) => formatValue(v, places: places, grouping: grouping, ascii: ascii);
}

/// Saves the calculator (expression, memory, GT, tape) shortly after every
/// change, so nothing is lost if the app is closed.
class CalculatorStore {
  CalculatorStore(this._prefs, this.calculator) {
    calculator.addListener(_schedule);
  }

  static const key = 'calculator';

  final SharedPreferences _prefs;
  final Calculator calculator;
  Timer? _timer;

  static Future<CalculatorStore> open(Calculator calculator) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        calculator.restore((jsonDecode(raw) as Map).cast<String, Object?>());
      } catch (_) {
        // Unreadable save: start clean rather than fail to open.
      }
    }
    return CalculatorStore(prefs, calculator);
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 400), flush);
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    await _prefs.setString(key, jsonEncode(calculator.toJson()));
  }
}
