import 'package:decimal/decimal.dart';

import 'expression.dart';

/// The minus sign used on screen (a true minus, not a hyphen).
const minus = '−';

/// Digits after the decimal point when showing results. `null` = automatic
/// (as many as needed, up to [autoPlaces]).
typedef Places = int?;

const autoPlaces = 10;

/// Inserts thousands separators into a plain digit string.
String groupDigits(String digits, {bool grouping = true}) {
  if (!grouping || digits.length <= 3) return digits;
  final b = StringBuffer();
  final lead = digits.length % 3;
  if (lead > 0) b.write(digits.substring(0, lead));
  for (var i = lead; i < digits.length; i += 3) {
    if (b.isNotEmpty) b.write(',');
    b.write(digits.substring(i, i + 3));
  }
  return b.toString();
}

/// Formats a finished value, e.g. `1,234,567.89`.
///
/// [ascii] uses '-' instead of '−' (for copying and sharing as text).
String formatValue(Decimal value, {Places places, bool grouping = true, bool ascii = false}) {
  final neg = value < Decimal.zero;
  final abs = value.abs();
  String body;
  if (abs >= Decimal.parse('1e15')) {
    body = abs.toStringAsExponential(8).replaceFirst(RegExp(r'0+e'), 'e').replaceFirst('.e', 'e');
  } else {
    var s = abs.toStringAsFixed(places ?? autoPlaces);
    if (places == null && s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
    final dot = s.indexOf('.');
    final intPart = dot < 0 ? s : s.substring(0, dot);
    final frac = dot < 0 ? '' : s.substring(dot);
    body = groupDigits(intPart, grouping: grouping) + frac;
  }
  // Never show "−0" after rounding.
  final isZero = RegExp(r'^[0.,]+$').hasMatch(body);
  return (neg && !isZero ? (ascii ? '-' : minus) : '') + body;
}

/// Formats a number token as typed, keeping a trailing '.' or zeros.
String formatToken(NumToken t, {bool grouping = true, bool ascii = false}) {
  final dot = t.text.indexOf('.');
  final intPart = dot < 0 ? t.text : t.text.substring(0, dot);
  final frac = dot < 0 ? '' : t.text.substring(dot);
  final sign = t.negative ? (ascii ? '-' : minus) : '';
  return '$sign${groupDigits(intPart.isEmpty ? '0' : intPart, grouping: grouping)}$frac${t.percent ? '%' : ''}';
}

/// The whole expression as one line, e.g. `2 + 2 − 6 × 4`.
String formatExpression(List<Token> tokens, {bool grouping = true, bool ascii = false}) {
  final b = StringBuffer();
  for (final t in tokens) {
    switch (t) {
      case NumToken():
        b.write(formatToken(t, grouping: grouping, ascii: ascii));
      case OpToken(:final op):
        final sym = ascii ? const {Op.subtract: '-', Op.multiply: 'x', Op.divide: '/'}[op] ?? op.symbol : op.symbol;
        b.write(' $sym ');
    }
  }
  return b.toString().trimRight();
}

/// A tax rate such as 18 or 17.5, shown without trailing zeros.
String formatRate(Decimal rate) => formatValue(rate, grouping: false);
