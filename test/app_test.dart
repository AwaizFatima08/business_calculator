import 'dart:io';

import 'package:businesscalc/ads/ads.dart';
import 'package:businesscalc/app.dart';
import 'package:businesscalc/core/calculator.dart';
import 'package:businesscalc/services/storage.dart';
import 'package:businesscalc/views/about_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppServices> pumpApp(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final calc = Calculator();
  final services = AppServices(
    calculator: calc,
    settings: await Settings.load(),
    ads: const NoAdService(),
    store: await CalculatorStore.open(calc),
  );
  await tester.pumpWidget(BusinessCalculatorApp(services: services));
  await tester.pumpAndSettle();
  return services;
}

Future<void> press(WidgetTester tester, String keys) async {
  for (final k in keys.split(' ')) {
    await tester.tap(find.byKey(Key('k-$k')));
    await tester.pump();
  }
  // Let the debounced save run.
  await tester.pump(const Duration(milliseconds: 500));
}

String textOf(WidgetTester tester, String key) => tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  testWidgets('the example from the brief on screen', (tester) async {
    await pumpApp(tester);
    await press(tester, '2 add 2 add 2 add 2 add 2 add 2 sub 6 mul 4');
    expect(textOf(tester, 'expression'), '2 + 2 + 2 + 2 + 2 + 2 − 6 × 4');
    expect(textOf(tester, 'total'), '−12');
    await press(tester, 'eq');
    expect(textOf(tester, 'total'), '−12');
    expect(find.text('=', skipOffstage: false), findsWidgets);
  });

  testWidgets('memory and GT indicators', (tester) async {
    final s = await pumpApp(tester);
    await press(tester, '1 5 0 0 mplus');
    expect(find.byKey(const Key('ind-m')), findsOneWidget);
    expect(find.byKey(const Key('ind-gt')), findsOneWidget);
    await press(tester, '2 mul mr eq');
    expect(textOf(tester, 'total'), '3,000');
    expect(s.calculator.grandTotal.toString(), '4500');
    await tester.longPress(find.byKey(const Key('k-gt')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('ind-gt')), findsNothing);
    await press(tester, 'mc');
    expect(find.byKey(const Key('ind-m')), findsNothing);
  });

  testWidgets('tax key uses the rate from settings', (tester) async {
    await pumpApp(tester, prefs: {'taxRate': '17'});
    await press(tester, '2 0 0 taxplus');
    expect(textOf(tester, 'total'), '234');
    expect(find.textContaining('tax 17%'), findsOneWidget);
  });

  testWidgets('decimal places setting', (tester) async {
    await pumpApp(tester, prefs: {'places': 2});
    await press(tester, '1 0 div 4 eq');
    expect(textOf(tester, 'total'), '2.50');
  });

  testWidgets('earlier results stay on the tape and can be reused', (tester) async {
    await pumpApp(tester);
    await press(tester, '7 mul 6 eq 1 add 1 eq');
    expect(find.text('= 42'), findsOneWidget);
    await tester.tap(find.text('= 42'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(textOf(tester, 'expression'), '42');
  });

  testWidgets('tape page lists, and clears with confirmation', (tester) async {
    final s = await pumpApp(tester);
    await press(tester, '9 add 1 eq');
    await tester.tap(find.byKey(const Key('open-tape')));
    await tester.pumpAndSettle();
    expect(find.text('= 10'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tape-clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-clear')));
    await tester.pumpAndSettle();
    expect(s.calculator.history, isEmpty);
    expect(find.textContaining('No calculations yet'), findsOneWidget);
  });

  testWidgets('state is saved and restored', (tester) async {
    final s = await pumpApp(tester);
    await press(tester, '1 2 add 3 eq mplus 5 add');
    await s.store!.flush();
    final prefs = await SharedPreferences.getInstance();
    final again = Calculator();
    await CalculatorStore.open(again);
    expect(again.memory.toString(), '15');
    expect(again.history, hasLength(1));
    expect(again.tokens, hasLength(2));
    expect(prefs.getString(CalculatorStore.key), isNotNull);
  });

  testWidgets('settings and about sheets open', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Decimal places in results'), findsOneWidget);
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-about')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('about-privacy')), findsOneWidget);
  });

  test('about version matches pubspec', () {
    final v = RegExp(r'^version: (\S+)\+', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())!;
    expect(appVersion, v.group(1));
  });
}
