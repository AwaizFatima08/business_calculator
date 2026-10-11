import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../core/calculator.dart';
import '../core/format.dart';
import '../services/storage.dart';

const _tabular = [FontFeature.tabularFigures()];

/// The screen: earlier calculations (the tape) scrolling above, the whole
/// current expression, and the total at the bottom in large figures.
class CalcDisplay extends StatelessWidget {
  const CalcDisplay({super.key, required this.calculator, required this.settings, this.onTapEntry, this.toolbar});

  final Calculator calculator;
  final Settings settings;
  final void Function(TapeEntry entry)? onTapEntry;

  /// Buttons shown at the top right of the display (tape, settings, about).
  final Widget? toolbar;

  @override
  Widget build(BuildContext context) {
    final c = calculator;
    // When a calculation has just finished it is shown as the current one,
    // so the tape above stops at the entry before it.
    final tape = c.done && c.history.isNotEmpty ? c.history.sublist(0, c.history.length - 1) : c.history;
    final current = c.done && c.history.isNotEmpty ? c.history.last : null;
    final expression = formatExpression(current?.tokens ?? c.tokens, grouping: settings.grouping);
    final total = c.liveValue;

    return Container(
      decoration: BoxDecoration(
        color: Palette.display,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.displayBorder, width: 1.2),
      ),
      padding: const EdgeInsets.fromLTRB(14, 6, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _Indicators(calculator: c, settings: settings),
              ),
              ?toolbar,
            ],
          ),
          Expanded(
            child: tape.isEmpty
                ? const SizedBox.shrink()
                : ShaderMask(
                    // Fade the oldest lines out at the top edge.
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0, 0.12],
                    ).createShader(r),
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      key: const Key('tape'),
                      reverse: true,
                      padding: const EdgeInsets.only(right: 4),
                      itemCount: tape.length,
                      itemBuilder: (_, i) {
                        final e = tape[tape.length - 1 - i];
                        return _TapeLine(
                          entry: e,
                          settings: settings,
                          onTap: onTapEntry == null ? null : () => onTapEntry!(e),
                        );
                      },
                    ),
                  ),
          ),
          if (tape.isNotEmpty) const Divider(height: 10, color: Palette.displayBorder),
          // The whole current calculation, every figure.
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 104),
            child: SingleChildScrollView(
              reverse: true,
              child: Text(
                expression.isEmpty ? ' ' : expression,
                key: const Key('expression'),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 28,
                  height: 1.2,
                  color: c.done ? Palette.inkSoft : Palette.ink,
                  fontFeatures: _tabular,
                ),
              ),
            ),
          ),
          if (current != null && current.hasTax) _TaxLine(entry: current, settings: settings, fontSize: 18),
          const SizedBox(height: 2),
          // The total, in large figures.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                c.done ? '=' : 'Total',
                style: TextStyle(
                  fontSize: c.done ? 40 : 15,
                  fontWeight: FontWeight.w600,
                  color: c.done ? Palette.accent : Palette.inkFaint,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 68,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      c.error ?? settings.value(total ?? Decimal.zero),
                      key: const Key('total'),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: c.error != null ? 32 : 62,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: c.error != null
                            ? Palette.error
                            : c.done
                            ? Palette.ink
                            : Palette.ink.withValues(alpha: total == null ? 0.35 : 0.8),
                        fontFeatures: _tabular,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Indicators extends StatelessWidget {
  const _Indicators({required this.calculator, required this.settings});

  final Calculator calculator;
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    Widget chip(String key, String label, String value, Color color) => Container(
      key: Key(key),
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(fontWeight: FontWeight.w800, color: color),
            ),
            TextSpan(text: value),
          ],
        ),
        style: const TextStyle(fontSize: 13, color: Palette.ink, fontFeatures: _tabular),
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (calculator.hasMemory) chip('ind-m', 'M', settings.value(calculator.memory), Palette.opKey),
          if (calculator.hasGrandTotal) chip('ind-gt', 'GT', settings.value(calculator.grandTotal), Palette.accent),
        ],
      ),
    );
  }
}

class _TapeLine extends StatelessWidget {
  const _TapeLine({required this.entry, required this.settings, this.onTap});

  final TapeEntry entry;
  final Settings settings;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatExpression(entry.tokens, grouping: settings.grouping),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 17, color: Palette.inkSoft, fontFeatures: _tabular),
            ),
            if (entry.hasTax) _TaxLine(entry: entry, settings: settings, fontSize: 15),
            Text(
              '= ${settings.value(entry.result)}',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Palette.ink,
                fontFeatures: _tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaxLine extends StatelessWidget {
  const _TaxLine({required this.entry, required this.settings, required this.fontSize});

  final TapeEntry entry;
  final Settings settings;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final rate = formatRate(entry.taxRate!);
    final text = entry.taxAdded
        ? '${settings.value(entry.subtotal)}  + tax $rate%  ${settings.value(entry.taxAmount!)}'
        : '${settings.value(entry.subtotal)}  incl. tax $rate%  ${settings.value(entry.taxAmount!)}';
    return Text(
      text,
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: fontSize, color: Palette.taxText, fontWeight: FontWeight.w600, fontFeatures: _tabular),
    );
  }
}
