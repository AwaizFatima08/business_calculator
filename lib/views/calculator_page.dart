import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ads/ads.dart';
import '../app.dart';
import '../core/calculator.dart';
import '../core/expression.dart';
import '../core/format.dart';
import '../widgets/display.dart';
import '../widgets/keypad.dart';
import 'about_sheet.dart';
import 'history_page.dart';
import 'settings_sheet.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key, required this.services});

  final AppServices services;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> with WidgetsBindingObserver {
  Calculator get calc => widget.services.calculator;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      widget.services.store?.flush();
    }
  }

  void _feedback() {
    final s = widget.services.settings;
    if (s.haptics) HapticFeedback.lightImpact();
    if (s.clickSound) SystemSound.play(SystemSoundType.click);
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  Future<void> _openTape() async {
    final picked = await Navigator.of(
      context,
    ).push<TapeEntry>(MaterialPageRoute(builder: (_) => HistoryPage(services: widget.services)));
    if (picked != null) calc.insertValue(picked.result);
    if (mounted) await widget.services.ads.maybeShowInterstitial(context, AdPlacement.historyClosed);
  }

  List<List<KeySpec>> _rows() {
    final s = widget.services.settings;
    KeySpec digit(String d) => KeySpec(d, d, style: KeyStyle.digit, onTap: () => calc.digit(d));
    KeySpec op(Op o, String id, String name) =>
        KeySpec(id, o.symbol, style: KeyStyle.op, semantics: name, onTap: () => calc.operator(o));
    return [
      [
        KeySpec(
          'mc',
          'MC',
          style: KeyStyle.memory,
          semantics: 'Memory clear',
          onTap: () {
            if (calc.hasMemory) _toast('Memory cleared');
            calc.memoryClear();
          },
        ),
        KeySpec('mr', 'MR', style: KeyStyle.memory, semantics: 'Memory recall', onTap: calc.memoryRecall),
        KeySpec('mminus', 'M−', style: KeyStyle.memory, semantics: 'Memory minus', onTap: calc.memorySubtract),
        KeySpec('mplus', 'M+', style: KeyStyle.memory, semantics: 'Memory plus', onTap: calc.memoryAdd),
        KeySpec(
          'gt',
          'GT',
          style: KeyStyle.memory,
          semantics: 'Grand total. Long press to clear',
          onTap: calc.grandTotalRecall,
          onLongPress: () {
            calc.grandTotalClear();
            _toast('Grand total cleared');
          },
        ),
      ],
      [
        KeySpec('ac', 'AC', style: KeyStyle.clear, semantics: 'All clear', onTap: calc.clearAll),
        KeySpec(
          'back',
          '⌫',
          style: KeyStyle.fn,
          icon: Icons.backspace_outlined,
          semantics: 'Backspace. Long press to clear',
          onTap: calc.backspace,
          onLongPress: calc.clearAll,
        ),
        KeySpec(
          'taxminus',
          'TAX−',
          style: KeyStyle.tax,
          semantics: 'Remove tax',
          sub: '${formatRate(s.taxRate)}%',
          onTap: () => calc.tax(add: false, rate: s.taxRate),
        ),
        KeySpec(
          'taxplus',
          'TAX+',
          style: KeyStyle.tax,
          semantics: 'Add tax',
          sub: '${formatRate(s.taxRate)}%',
          onTap: () => calc.tax(add: true, rate: s.taxRate),
        ),
        op(Op.divide, 'div', 'Divide'),
      ],
      [
        digit('7'),
        digit('8'),
        digit('9'),
        KeySpec('pct', '%', style: KeyStyle.fn, semantics: 'Percent', onTap: calc.percent),
        op(Op.multiply, 'mul', 'Multiply'),
      ],
      [
        digit('4'),
        digit('5'),
        digit('6'),
        KeySpec('sign', '+/−', style: KeyStyle.fn, semantics: 'Change sign', onTap: calc.toggleSign),
        op(Op.subtract, 'sub', 'Minus'),
      ],
      [
        digit('1'),
        digit('2'),
        digit('3'),
        KeySpec('00', '00', style: KeyStyle.digit, semantics: 'Double zero', onTap: () => calc.digit('00')),
        op(Op.add, 'add', 'Plus'),
      ],
      [
        KeySpec('0', '0', style: KeyStyle.digit, flex: 2, onTap: () => calc.digit('0')),
        KeySpec('dot', '.', style: KeyStyle.digit, semantics: 'Decimal point', onTap: calc.point),
        KeySpec('eq', '=', style: KeyStyle.equals, flex: 2, semantics: 'Equals', onTap: calc.equals),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final services = widget.services;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([calc, services.settings]),
          builder: (context, _) => Column(
            children: [
              Expanded(
                flex: 46,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                  child: CalcDisplay(
                    calculator: calc,
                    settings: services.settings,
                    onTapEntry: (e) => calc.insertValue(e.result),
                    toolbar: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          key: const Key('open-tape'),
                          tooltip: 'Tape',
                          icon: const Icon(Icons.receipt_long_outlined),
                          color: Palette.inkSoft,
                          onPressed: _openTape,
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          key: const Key('open-settings'),
                          tooltip: 'Settings',
                          icon: const Icon(Icons.tune),
                          color: Palette.inkSoft,
                          onPressed: () => showSettingsSheet(context, services.settings),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          key: const Key('open-about'),
                          tooltip: 'About',
                          icon: const Icon(Icons.info_outline),
                          color: Palette.inkSoft,
                          onPressed: () => showAboutSheet(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 54,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                  child: Keypad(rows: _rows(), rowFlex: const [7, 10, 10, 10, 10, 10], onAnyKey: _feedback),
                ),
              ),
              AdBannerSlot(ads: services.ads, placement: AdPlacement.homeBanner),
            ],
          ),
        ),
      ),
    );
  }
}
