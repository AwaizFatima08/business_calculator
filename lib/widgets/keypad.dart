import 'package:flutter/material.dart';

import '../app.dart';

enum KeyStyle { digit, op, fn, clear, memory, tax, equals }

/// One key on the pad.
class KeySpec {
  const KeySpec(
    this.id,
    this.label, {
    required this.style,
    required this.onTap,
    this.onLongPress,
    this.semantics,
    this.flex = 1,
    this.icon,
    this.sub,
  });

  /// Stable id, used for the widget key `k-<id>` (tests and screenshots).
  final String id;
  final String label;
  final KeyStyle style;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? semantics;
  final int flex;
  final IconData? icon;

  /// Small second line under the label (e.g. the tax rate).
  final String? sub;
}

/// The key grid. Each row is laid out with [Expanded] so the keys grow to
/// fill whatever height the screen gives them.
class Keypad extends StatelessWidget {
  const Keypad({super.key, required this.rows, required this.rowFlex, this.onAnyKey});

  final List<List<KeySpec>> rows;

  /// Relative height of each row.
  final List<int> rowFlex;

  /// Feedback hook (haptics / click) run before every key action.
  final VoidCallback? onAnyKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var r = 0; r < rows.length; r++)
          Expanded(
            flex: rowFlex[r],
            child: Row(
              children: [
                for (final k in rows[r])
                  Expanded(
                    flex: k.flex,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _Key(
                        spec: k,
                        compact: rowFlex[r] < rowFlex.reduce((a, b) => a > b ? a : b),
                        onAnyKey: onAnyKey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.spec, required this.compact, this.onAnyKey});

  final KeySpec spec;
  final bool compact;
  final VoidCallback? onAnyKey;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (spec.style) {
      KeyStyle.digit => (Palette.digitKey, Palette.ink),
      KeyStyle.op => (Palette.opKey, Palette.opText),
      KeyStyle.fn => (Palette.fnKey, Palette.fnText),
      KeyStyle.clear => (Palette.fnKey, Palette.clearText),
      KeyStyle.memory => (Palette.memKey, Palette.fnText),
      KeyStyle.tax => (Palette.taxKey, Palette.taxText),
      KeyStyle.equals => (Palette.equalsKey, Colors.white),
    };
    final size = switch (spec.style) {
      KeyStyle.digit => 34.0,
      KeyStyle.op || KeyStyle.equals => 38.0,
      KeyStyle.memory => 19.0,
      KeyStyle.tax => 18.0,
      _ => spec.label.length > 2 ? 22.0 : 28.0,
    };
    final bordered = spec.style == KeyStyle.digit;
    return Semantics(
      button: true,
      label: spec.semantics ?? spec.label,
      excludeSemantics: true,
      child: Material(
        key: Key('k-${spec.id}'),
        color: bg,
        elevation: bordered ? 1 : 0,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 16),
          side: bordered ? const BorderSide(color: Palette.keyBorder) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            onAnyKey?.call();
            spec.onTap();
          },
          onLongPress: spec.onLongPress == null
              ? null
              : () {
                  onAnyKey?.call();
                  spec.onLongPress!();
                },
          child: Center(
            child: spec.icon != null
                ? Icon(spec.icon, color: fg, size: 30)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            spec.label,
                            maxLines: 1,
                            style: TextStyle(
                              color: fg,
                              fontSize: size,
                              fontWeight: spec.style == KeyStyle.digit ? FontWeight.w500 : FontWeight.w700,
                              height: 1,
                            ),
                          ),
                          if (spec.sub != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                spec.sub!,
                                maxLines: 1,
                                style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w500, height: 1),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
