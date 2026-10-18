import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ads/ads.dart';
import '../app.dart';
import '../core/format.dart';
import '../services/storage.dart';

Future<void> showSettingsSheet(BuildContext context, Settings settings, [AdService ads = const NoAdService()]) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SettingsSheet(settings: settings, ads: ads),
      ),
    );

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key, required this.settings, this.ads = const NoAdService()});

  final Settings settings;
  final AdService ads;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late final Future<bool> _privacyOptions = widget.ads.privacyOptionsRequired;
  late final _rate = TextEditingController(text: formatRate(widget.settings.taxRate));
  String? _rateError;

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  void _saveRate(String text) {
    final v = Decimal.tryParse(text.trim());
    final ok = v != null && v >= Decimal.zero && v <= Decimal.fromInt(100);
    setState(() => _rateError = ok ? null : 'Enter a rate from 0 to 100');
    if (ok) widget.settings.taxRate = v;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    const label = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Palette.ink);
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              const Text('Decimal places in results', style: label),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                key: const Key('set-places'),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                ),
                segments: [
                  for (final p in Settings.placesChoices)
                    ButtonSegment(value: p ?? -1, label: Text(p == null ? 'Auto' : '$p', maxLines: 1, softWrap: false)),
                ],
                selected: {s.places ?? -1},
                onSelectionChanged: (v) => s.places = v.first < 0 ? null : v.first,
              ),
              const SizedBox(height: 20),
              const Text('Tax rate for TAX+ / TAX−', style: label),
              const SizedBox(height: 8),
              TextField(
                key: const Key('set-tax'),
                controller: _rate,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: InputDecoration(
                  suffixText: '%',
                  border: const OutlineInputBorder(),
                  errorText: _rateError,
                  helperText: 'e.g. 18 for 18% GST / sales tax',
                ),
                onChanged: _saveRate,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                key: const Key('set-grouping'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Thousands separator', style: label),
                subtitle: const Text('1,250,000 instead of 1250000'),
                value: s.grouping,
                onChanged: (v) => s.grouping = v,
              ),
              SwitchListTile(
                key: const Key('set-haptics'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Vibrate on key press', style: label),
                value: s.haptics,
                onChanged: (v) => s.haptics = v,
              ),
              SwitchListTile(
                key: const Key('set-click'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Key click sound', style: label),
                value: s.clickSound,
                onChanged: (v) => s.clickSound = v,
              ),
              // Only where the law requires a way to change ad consent (EEA, UK, CH).
              FutureBuilder<bool>(
                future: _privacyOptions,
                builder: (context, snap) => snap.data != true
                    ? const SizedBox.shrink()
                    : ListTile(
                        key: const Key('set-privacy-options'),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: const Text('Ad privacy options', style: label),
                        subtitle: const Text('Change your consent for personalised ads'),
                        onTap: widget.ads.showPrivacyOptions,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
