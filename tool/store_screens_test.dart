// ignore_for_file: invalid_use_of_visible_for_testing_member
// Renders the real app UI in its key states for the Play screenshots.
//
//   flutter test tool/store_screens_test.dart && flutter test tool/make_graphics_test.dart
//
// Writes store-assets/raw/*.png (1080 px wide); make_graphics_test.dart then
// frames and captions them into store-assets/screenshots/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:businesscalc/ads/ads.dart';
import 'package:businesscalc/app.dart';
import 'package:businesscalc/core/calculator.dart';
import 'package:businesscalc/services/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const logical = Size(411, 890);
const ratio = 1080 / 411;
final boundary = GlobalKey();

Future<void> loadFonts() async {
  const dir = '/mnt/storage/projects/flutter/bin/cache/artifacts/material_fonts';
  ByteData read(String f) => ByteData.sublistView(File('$dir/$f').readAsBytesSync());
  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black', 'Light']) {
    roboto.addFont(Future.value(read('Roboto-$w.ttf')));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(Future.value(read('MaterialIcons-Regular.otf')))).load();
}

Future<AppServices> pump(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
  tester.view.physicalSize = logical * ratio;
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  var t = DateTime(2026, 10, 12, 9, 14);
  final calc = Calculator(clock: () => t = t.add(const Duration(minutes: 3)));
  final services = AppServices(calculator: calc, settings: await Settings.load(), ads: const NoAdService());
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundary,
      child: BusinessCalculatorApp(services: services),
    ),
  );
  await tester.pumpAndSettle();
  return services;
}

Future<void> press(WidgetTester tester, String keys) async {
  for (final k in keys.split(' ')) {
    await tester.tap(find.byKey(Key('k-$k')));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// "1250" -> "1 2 5 0".
String n(String digits) => digits.split('').map((c) => c == '.' ? 'dot' : c).join(' ');

Future<void> shoot(WidgetTester tester, String name) async {
  final ro = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final img = await ro.toImage(pixelRatio: ratio);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('store-assets/raw/$name.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// A morning of shop sums, so the tape has something on it.
Future<void> morning(WidgetTester tester) async {
  await press(tester, '${n('1250')} add ${n('480')} add ${n('75.50')} eq');
  await press(tester, '${n('36')} mul ${n('12')} eq');
  await press(tester, '${n('5000')} sub ${n('10')} pct eq');
}

void main() {
  setUpAll(loadFonts);

  testWidgets('expression', (tester) async {
    await pump(tester, prefs: {'places': 2});
    await morning(tester);
    await press(tester, '2 add 2 add 2 add 2 add 2 add 2 sub 6 mul 4');
    await shoot(tester, '01-expression');
  });

  testWidgets('tax', (tester) async {
    await pump(tester, prefs: {'places': 2, 'taxRate': '18'});
    await morning(tester);
    await press(tester, '${n('8450')} add ${n('1200')} taxplus');
    await shoot(tester, '02-tax');
  });

  testWidgets('memory', (tester) async {
    await pump(tester, prefs: {'places': 2});
    await press(tester, '${n('24')} mul ${n('350')} mplus');
    await press(tester, '${n('12')} mul ${n('1150')} mplus');
    await press(tester, '${n('6')} mul ${n('95')} mminus');
    await press(tester, 'ac mr');
    await shoot(tester, '03-memory');
  });

  testWidgets('tape', (tester) async {
    await pump(tester, prefs: {'places': 2, 'taxRate': '18'});
    await morning(tester);
    await press(tester, '${n('2360')} taxminus');
    await press(tester, '${n('640')} div 8 eq');
    await tester.tap(find.byKey(const Key('open-tape')));
    await tester.pumpAndSettle();
    await shoot(tester, '04-tape');
  });

  testWidgets('settings', (tester) async {
    await pump(tester, prefs: {'places': 2, 'taxRate': '17'});
    await morning(tester);
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    await shoot(tester, '05-settings');
  });
}
