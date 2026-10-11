import 'package:businesscalc/core/calculator.dart';
import 'package:businesscalc/core/expression.dart';
import 'package:businesscalc/core/format.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

Decimal d(String s) => Decimal.parse(s);

/// Types [keys] like a user: digits, '.', + - * /, %, n (sign), = .
Calculator type(String keys, [Calculator? c]) {
  c ??= Calculator();
  for (final k in keys.split(' ').where((k) => k.isNotEmpty)) {
    switch (k) {
      case '+':
        c.operator(Op.add);
      case '-':
        c.operator(Op.subtract);
      case '*':
        c.operator(Op.multiply);
      case '/':
        c.operator(Op.divide);
      case '%':
        c.percent();
      case 'n':
        c.toggleSign();
      case '=':
        c.equals();
      case '<':
        c.backspace();
      default:
        for (final ch in k.split('')) {
          ch == '.' ? c.point() : c.digit(ch);
        }
    }
  }
  return c;
}

void main() {
  group('evaluation', () {
    test('standard precedence: the example from the brief', () {
      final c = type('2 + 2 + 2 + 2 + 2 + 2 - 6 * 4 =');
      expect(c.result, d('-12'));
      expect(formatExpression(c.history.last.tokens), '2 + 2 + 2 + 2 + 2 + 2 − 6 × 4');
    });

    test('exact decimals (no floating point drift)', () {
      expect(type('0.1 + 0.2 =').result, d('0.3'));
      expect(type('1.1 * 1.1 =').result, d('1.21'));
      expect(type('100 - 99.99 =').result, d('0.01'));
    });

    test('division rounds to 12 places half-up', () {
      expect(type('1 / 3 =').result, d('0.333333333333'));
      expect(type('2 / 3 =').result, d('0.666666666667'));
    });

    test('divide by zero shows an error and records nothing', () {
      final c = type('5 / 0 =');
      expect(c.error, isNotNull);
      expect(c.history, isEmpty);
      expect(c.grandTotal, Decimal.zero);
      c.backspace();
      expect(c.error, isNull);
      type('2 =', c);
      expect(c.result, d('2.5'));
    });

    test('live value ignores a trailing operator', () {
      final c = type('12 + 30 *');
      expect(c.liveValue, d('42'));
      type('2', c);
      expect(c.liveValue, d('72'));
    });

    test('operator replaces a previous operator', () {
      expect(type('9 + - 4 =').result, d('5'));
    });
  });

  group('percent', () {
    test('add and remove a percentage', () {
      expect(type('500 + 10 % =').result, d('550'));
      expect(type('500 - 10 % =').result, d('450'));
      expect(type('200 + 300 + 10 % =').result, d('550'));
    });
    test('multiply and divide by a percentage', () {
      expect(type('250 * 8 % =').result, d('20'));
      expect(type('50 / 25 % =').result, d('200'));
      expect(type('15 % =').result, d('0.15'));
    });
  });

  group('entry', () {
    test('sign change and leading zeros', () {
      expect(type('0 0 7 =').result, d('7'));
      expect(type('5 n =').result, d('-5'));
      expect(type('10 * n 3 =').result, d('-30'));
    });

    test('00 key and digit limit', () {
      final c = Calculator()
        ..digit('1')
        ..digit('00');
      expect(formatExpression(c.tokens), '100');
      for (var i = 0; i < 20; i++) {
        c.digit('9');
      }
      expect((c.tokens.last as NumToken).digitCount, Calculator.maxDigits);
    });

    test('one decimal point per number', () {
      expect(formatExpression(type('1 . . 5').tokens), '1.5');
      expect(formatExpression(type('.').tokens), '0.');
    });

    test('backspace', () {
      expect(formatExpression(type('123 + <').tokens), '123');
      expect(formatExpression(type('123 <').tokens), '12');
      expect(formatExpression(type('10 % <').tokens), '10');
    });

    test('a digit after = starts fresh, an operator continues', () {
      final c = type('2 + 3 =');
      type('4', c);
      expect(formatExpression(c.tokens), '4');
      final c2 = type('2 + 3 = * 2 =');
      expect(c2.result, d('10'));
      expect(c2.history, hasLength(2));
    });

    test('= twice does not record twice', () {
      final c = type('2 + 3 = =');
      expect(c.history, hasLength(1));
      expect(c.grandTotal, d('5'));
    });
  });

  group('memory and GT', () {
    test('M+ finishes the calculation and adds it', () {
      final c = type('100 + 50');
      c.memoryAdd();
      expect(c.result, d('150'));
      expect(c.memory, d('150'));
      type('20', c);
      c.memorySubtract();
      expect(c.memory, d('130'));
      expect(c.history, hasLength(2));
    });

    test('M+ after = does not finish twice', () {
      final c = type('7 =');
      c.memoryAdd();
      c.memoryAdd();
      expect(c.memory, d('14'));
      expect(c.history, hasLength(1));
    });

    test('MR inserts the memory value', () {
      final c = type('40 =');
      c.memoryAdd();
      type('2 *', c);
      c.memoryRecall();
      expect(c.liveValue, d('80'));
      c.memoryClear();
      expect(c.hasMemory, isFalse);
    });

    test('GT sums every result', () {
      final c = type('10 + 5 = 20 * 2 = 7 =');
      expect(c.grandTotal, d('62'));
      c.grandTotalRecall();
      expect(formatExpression(c.tokens), '62');
      c.grandTotalClear();
      expect(c.hasGrandTotal, isFalse);
    });
  });

  group('tax', () {
    test('Tax+ adds and Tax− removes', () {
      final c = type('1000');
      c.tax(add: true, rate: d('18'));
      expect(c.result, d('1180'));
      expect(c.history.last.taxAmount, d('180'));
      expect(c.grandTotal, d('1180'));

      final c2 = type('1180 =');
      c2.tax(add: false, rate: d('18'));
      expect(c2.result, d('1000'));
      expect(c2.history.last.taxAmount, d('180'));
      expect(c2.grandTotal, d('1000'));
      expect(c2.history, hasLength(1));
    });

    test('tax twice does not compound', () {
      final c = type('100 =');
      c.tax(add: true, rate: d('10'));
      c.tax(add: true, rate: d('10'));
      expect(c.result, d('110'));
      expect(c.grandTotal, d('110'));
    });
  });

  group('persistence', () {
    test('round trip', () {
      final c = type('10 + 5 % =');
      c.memoryAdd();
      c.tax(add: true, rate: d('17.5'));
      type('3 *', c);
      final c2 = Calculator()..restore(c.toJson());
      expect(c2.memory, c.memory);
      expect(c2.grandTotal, c.grandTotal);
      expect(c2.history.single.taxRate, d('17.5'));
      expect(formatExpression(c2.history.single.tokens), '10 + 5%');
      expect(formatExpression(c2.tokens), '3 ×');
    });

    test('corrupt data never crashes', () {
      final c = Calculator()..restore({'tokens': 5, 'memory': 'x'});
      expect(c.isEmpty, isTrue);
    });
  });

  group('format', () {
    test('grouping and places', () {
      expect(formatValue(d('1234567.891')), '1,234,567.891');
      expect(formatValue(d('1234567.891'), places: 2), '1,234,567.89');
      expect(formatValue(d('-0.001'), places: 2), '0.00');
      expect(formatValue(d('-1500')), '−1,500');
      expect(formatValue(d('-1500'), ascii: true), '-1,500');
      expect(formatValue(d('1500'), grouping: false), '1500');
      expect(formatValue(d('0.5'), places: 0), '1');
    });
    test('typed numbers keep what was typed', () {
      expect(formatToken(const NumToken('1234.50')), '1,234.50');
      expect(formatToken(const NumToken('12.')), '12.');
      expect(formatToken(const NumToken('5', negative: true, percent: true)), '−5%');
    });
    test('huge values use exponent form', () {
      expect(formatValue(d('123456789012345678')), contains('e+17'));
    });
  });
}
