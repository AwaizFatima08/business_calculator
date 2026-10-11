import 'package:decimal/decimal.dart';

import 'calculator.dart';
import 'format.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String two(int n) => n.toString().padLeft(2, '0');

String formatDay(DateTime t) => '${t.day} ${_months[t.month - 1]} ${t.year}';

String formatTime(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

/// The tape as plain text for copying or sharing, grouped by day.
String tapeAsText(
  List<TapeEntry> entries, {
  required String Function(TapeEntry e) expression,
  required String Function(TapeEntry e) result,
  String Function(TapeEntry e)? tax,
}) {
  final b = StringBuffer('Business Calculator tape\n');
  String? day;
  for (final e in entries) {
    final d = formatDay(e.at);
    if (d != day) {
      b.write('\n$d\n');
      day = d;
    }
    b.write('${formatTime(e.at)}  ${expression(e)}');
    if (e.hasTax && tax != null) b.write('  [${tax(e)}]');
    b.write(' = ${result(e)}\n');
  }
  return b.toString();
}

/// Short tax note, e.g. "+ tax 18% 180" or "incl. tax 18% 180".
String taxNote(TapeEntry e, String Function(Decimal v) value) =>
    '${e.taxAdded ? '+ tax' : 'incl. tax'} ${formatRate(e.taxRate!)}% ${value(e.taxAmount!)}';
