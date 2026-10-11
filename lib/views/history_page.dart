import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../core/format.dart';
import '../core/tape_text.dart';

/// The saved tape: every finished calculation, newest first. Tap one to use
/// its result, long-press to copy, swipe to delete.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.services});

  final AppServices services;

  String _text() {
    final s = services.settings;
    return tapeAsText(
      services.calculator.history,
      expression: (e) => formatExpression(e.tokens, grouping: s.grouping, ascii: true),
      result: (e) => s.value(e.result, ascii: true),
      tax: (e) => taxNote(e, (v) => s.value(v, ascii: true)),
    );
  }

  void _toast(BuildContext context, String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));

  Future<void> _clear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear the tape?'),
        content: const Text('All saved calculations will be deleted. Memory and GT are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            key: const Key('confirm-clear'),
            style: FilledButton.styleFrom(backgroundColor: Palette.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) services.calculator.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final calc = services.calculator;
    final s = services.settings;
    return ListenableBuilder(
      listenable: calc,
      builder: (context, _) {
        final entries = calc.history.reversed.toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tape', style: TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                key: const Key('tape-copy'),
                tooltip: 'Copy all',
                icon: const Icon(Icons.copy_all_outlined),
                onPressed: entries.isEmpty
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: _text()));
                        if (context.mounted) _toast(context, 'Tape copied');
                      },
              ),
              IconButton(
                key: const Key('tape-share'),
                tooltip: 'Share',
                icon: const Icon(Icons.share_outlined),
                onPressed: entries.isEmpty
                    ? null
                    : () => SharePlus.instance.share(ShareParams(text: _text(), subject: 'Business Calculator tape')),
              ),
              IconButton(
                key: const Key('tape-clear'),
                tooltip: 'Clear tape',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: entries.isEmpty ? null : () => _clear(context),
              ),
            ],
          ),
          body: entries.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No calculations yet.\nEvery result you finish with = appears here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, color: Palette.inkSoft, height: 1.4),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final day = formatDay(e.at);
                    final newDay = i == 0 || formatDay(entries[i - 1].at) != day;
                    final index = calc.history.length - 1 - i;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (newDay)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                            child: Text(
                              day,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Palette.inkSoft),
                            ),
                          ),
                        Dismissible(
                          key: ObjectKey(e),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Palette.error.withValues(alpha: 0.12),
                            child: const Icon(Icons.delete_outline, color: Palette.error),
                          ),
                          onDismissed: (_) => calc.deleteEntry(index),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: Palette.display,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Palette.displayBorder),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.pop(context, e),
                              onLongPress: () async {
                                await Clipboard.setData(ClipboardData(text: s.value(e.result, ascii: true)));
                                if (context.mounted) _toast(context, 'Result copied');
                              },
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          formatTime(e.at),
                                          style: const TextStyle(color: Palette.inkFaint, fontSize: 13),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            formatExpression(e.tokens, grouping: s.grouping),
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(fontSize: 17, color: Palette.inkSoft),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (e.hasTax)
                                      Text(
                                        '${s.value(e.subtotal)}  ${taxNote(e, (v) => s.value(v))}',
                                        style: const TextStyle(color: Palette.taxText, fontWeight: FontWeight.w600),
                                      ),
                                    Text(
                                      '= ${s.value(e.result)}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Palette.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}
