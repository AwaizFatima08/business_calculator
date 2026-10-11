import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

/// The four arithmetic operators, with the symbols shown on the tape.
enum Op {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  const Op(this.symbol);
  final String symbol;

  bool get isAdditive => this == add || this == subtract;
}

/// One item of an expression: a number being (or already) typed, or an operator.
sealed class Token {
  const Token();
}

/// A number exactly as the user typed it. [text] holds only digits and at most
/// one '.', so "0", "12.", "0.50" are all kept as typed for the display.
final class NumToken extends Token {
  const NumToken(this.text, {this.negative = false, this.percent = false});

  final String text;
  final bool negative;
  final bool percent;

  /// Digits typed so far, ignoring the decimal point.
  int get digitCount => text.replaceAll('.', '').length;
  bool get hasPoint => text.contains('.');

  Rational get magnitude {
    final t = text.endsWith('.') ? text.substring(0, text.length - 1) : text;
    return Decimal.parse(t.isEmpty ? '0' : t).toRational();
  }

  Rational get signed => negative ? -magnitude : magnitude;

  NumToken copyWith({String? text, bool? negative, bool? percent}) =>
      NumToken(text ?? this.text, negative: negative ?? this.negative, percent: percent ?? this.percent);

  /// Serialised form for saving, e.g. "-12.5%".
  String encode() => '${negative ? '-' : ''}$text${percent ? '%' : ''}';

  static NumToken decode(String s) {
    var t = s;
    final neg = t.startsWith('-');
    if (neg) t = t.substring(1);
    final pct = t.endsWith('%');
    if (pct) t = t.substring(0, t.length - 1);
    return NumToken(t, negative: neg, percent: pct);
  }

  /// A finished value as a token (used for results, memory and GT recall).
  factory NumToken.fromDecimal(Decimal d) {
    final neg = d < Decimal.zero;
    return NumToken(d.abs().toString(), negative: neg);
  }

  @override
  bool operator ==(Object other) =>
      other is NumToken && other.text == text && other.negative == negative && other.percent == percent;

  @override
  int get hashCode => Object.hash(text, negative, percent);
}

final class OpToken extends Token {
  const OpToken(this.op);
  final Op op;

  @override
  bool operator ==(Object other) => other is OpToken && other.op == op;

  @override
  int get hashCode => op.hashCode;
}

class DivideByZero implements Exception {
  const DivideByZero();
  @override
  String toString() => 'Cannot divide by zero';
}

/// Evaluates [tokens] with standard precedence (× and ÷ before + and −).
///
/// A trailing operator is ignored, so a half-typed expression still has a
/// value for the live total. Percent follows business-calculator rules:
///   * `a + b%` adds b percent of a, and `a − b%` takes it off
///     (a is everything to the left: `200 + 300 + 10%` = 550);
///   * `a × b%` and `a ÷ b%` use b/100;
///   * a percent on its own is just b/100.
///
/// Throws [DivideByZero].
Rational evaluate(List<Token> tokens) {
  final list = List<Token>.of(tokens);
  while (list.isNotEmpty && list.last is OpToken) {
    list.removeLast();
  }
  if (list.isEmpty) return Rational.zero;

  var sum = Rational.zero;
  var pendingAdditive = Op.add;
  var i = 0;
  var first = true;
  while (i < list.length) {
    // Read one term: number (op number)* with only × and ÷ between them.
    final start = list[i] as NumToken;
    final hundred = Rational.fromInt(100);
    Rational term;
    // A lone percent directly after + or − is a percent of the running sum.
    final nextIsAdditiveOrEnd = i + 1 >= list.length || (list[i + 1] as OpToken).op.isAdditive;
    if (start.percent && !first && nextIsAdditiveOrEnd) {
      term = sum * start.signed / hundred;
    } else {
      term = start.percent ? start.signed / hundred : start.signed;
    }
    i++;
    while (i < list.length && !(list[i] as OpToken).op.isAdditive) {
      final op = (list[i] as OpToken).op;
      final n = list[i + 1] as NumToken;
      final v = n.percent ? n.signed / hundred : n.signed;
      if (op == Op.multiply) {
        term = term * v;
      } else {
        if (v == Rational.zero) throw const DivideByZero();
        term = term / v;
      }
      i += 2;
    }
    sum = pendingAdditive == Op.add ? sum + term : sum - term;
    first = false;
    if (i < list.length) {
      pendingAdditive = (list[i] as OpToken).op;
      i++;
    }
  }
  return sum;
}

/// Results are kept to 12 decimal places (half-up), far beyond any currency.
const resultScale = 12;

Decimal toDecimal(Rational r) {
  if (r.hasFinitePrecision) {
    final d = r.toDecimal();
    return d.scale > resultScale ? d.round(scale: resultScale) : d;
  }
  return r.toDecimal(scaleOnInfinitePrecision: resultScale, toBigInt: (v) => v.round());
}
