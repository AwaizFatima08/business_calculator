import 'package:businesscalc/ads/admob_ad_service.dart';
import 'package:businesscalc/ads/ads.dart';
import 'package:businesscalc/services/storage.dart';
import 'package:businesscalc/views/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ConsentRequired extends NoAdService {
  _ConsentRequired();
  int shown = 0;
  @override
  Future<bool> get privacyOptionsRequired async => true;
  @override
  Future<void> showPrivacyOptions() async => shown++;
}

void main() {
  test('debug builds use placeholders and Google test units', () {
    expect(AdService.fromEnvironment(), isA<PlaceholderAdService>());
    expect(AdUnits.banner, AdUnits.testBanner);
    expect(AdUnits.interstitial, AdUnits.testInterstitial);
  });

  test('frequency cap: launch grace, then spacing', () {
    var now = DateTime(2026, 10, 19, 9);
    final cap = FrequencyCap(minInterval: const Duration(minutes: 3), clock: () => now);
    expect(cap.canShow, isFalse);
    now = now.add(const Duration(seconds: 61));
    expect(cap.canShow, isTrue);
    cap.recordShown();
    now = now.add(const Duration(minutes: 2));
    expect(cap.canShow, isFalse);
    now = now.add(const Duration(minutes: 1));
    expect(cap.canShow, isTrue);
  });

  Future<void> pumpSheet(WidgetTester tester, AdService ads) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await Settings.load();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SettingsSheet(settings: settings, ads: ads))));
    await tester.pumpAndSettle();
  }

  testWidgets('privacy options only where consent rules apply', (tester) async {
    await pumpSheet(tester, const NoAdService());
    expect(find.byKey(const Key('set-privacy-options')), findsNothing);

    final ads = _ConsentRequired();
    await pumpSheet(tester, ads);
    await tester.ensureVisible(find.byKey(const Key('set-privacy-options')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('set-privacy-options')));
    expect(ads.shown, 1);
  });
}
