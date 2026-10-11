import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import 'expression.dart';

/// One finished calculation on the tape.
@immutable
class TapeEntry {
  const TapeEntry({
    required this.tokens,
    required this.result,
    required this.at,
    this.taxRate,
    this.taxAmount,
    this.taxAdded = true,
  });

  /// The expression as typed (no trailing operator).
  final List<Token> tokens;
  final Decimal result;
  final DateTime at;

  /// Set when Tax+ or Tax− finished this calculation.
  final Decimal? taxRate;
  final Decimal? taxAmount;
  final bool taxAdded;

  bool get hasTax => taxRate != null;

  /// The value before tax (or the whole result when there is no tax).
  Decimal get subtotal => !hasTax ? result : (taxAdded ? result - taxAmount! : result + taxAmount!);

  TapeEntry withTax({required Decimal rate, required Decimal amount, required bool added, required Decimal result}) =>
      TapeEntry(tokens: tokens, result: result, at: at, taxRate: rate, taxAmount: amount, taxAdded: added);

  Map<String, Object?> toJson() => {
    't': [
      for (final t in tokens)
        switch (t) {
          NumToken() => t.encode(),
          OpToken(:final op) => op.name,
        },
    ],
    'r': result.toString(),
    'at': at.millisecondsSinceEpoch,
    if (hasTax) 'tr': taxRate.toString(),
    if (hasTax) 'ta': taxAmount.toString(),
    if (hasTax) 'tp': taxAdded,
  };

  static TapeEntry fromJson(Map<String, Object?> j) => TapeEntry(
    tokens: decodeTokens((j['t'] as List).cast<String>()),
    result: Decimal.parse(j['r'] as String),
    at: DateTime.fromMillisecondsSinceEpoch(j['at'] as int),
    taxRate: j['tr'] == null ? null : Decimal.parse(j['tr'] as String),
    taxAmount: j['ta'] == null ? null : Decimal.parse(j['ta'] as String),
    taxAdded: (j['tp'] as bool?) ?? true,
  );
}

List<Token> decodeTokens(List<String> raw) => [
  for (final s in raw)
    if (Op.values.any((o) => o.name == s)) OpToken(Op.values.byName(s)) else NumToken.decode(s),
];

List<String> encodeTokens(List<Token> tokens) => [
  for (final t in tokens)
    switch (t) {
      NumToken() => t.encode(),
      OpToken(:final op) => op.name,
    },
];

/// The calculator: current expression, memory, grand total and tape.
///
/// All arithmetic is exact decimal (see [evaluate]); nothing here touches
/// Flutter widgets, so it is fully unit-testable.
class Calculator extends ChangeNotifier {
  Calculator({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// Longest number that can be typed (digits, not counting the point).
  static const maxDigits = 15;

  /// Most entries kept on the saved tape.
  static const maxHistory = 500;

  List<Token> _tokens = [];
  List<Token> get tokens => List.unmodifiable(_tokens);

  /// True right after "=", Tax or M± finished a calculation: the expression on
  /// screen is the finished one and [result] is its total.
  bool _done = false;
  bool get done => _done;

  Decimal? _result;
  Decimal? get result => _result;

  Decimal _memory = Decimal.zero;
  Decimal get memory => _memory;
  bool get hasMemory => _memory != Decimal.zero;

  Decimal _gt = Decimal.zero;
  Decimal get grandTotal => _gt;
  bool get hasGrandTotal => _gt != Decimal.zero;

  final List<TapeEntry> _history = [];

  /// Oldest first.
  List<TapeEntry> get history => List.unmodifiable(_history);

  String? _error;
  String? get error => _error;

  /// The value of the expression so far (ignores a trailing operator), or
  /// null if it is empty or cannot be computed.
  Decimal? get liveValue {
    if (_done) return _result;
    if (_tokens.isEmpty) return null;
    try {
      return toDecimal(evaluate(_tokens));
    } on DivideByZero {
      return null;
    }
  }

  bool get isEmpty => _tokens.isEmpty;

  NumToken? get _lastNum => _tokens.isNotEmpty && _tokens.last is NumToken ? _tokens.last as NumToken : null;

  void _setLast(NumToken t) => _tokens[_tokens.length - 1] = t;

  /// Called before every key: clears an error, and after a finished
  /// calculation a new number starts a new expression.
  void _beginInput({required bool continuesResult}) {
    _error = null;
    if (!_done) return;
    _done = false;
    _tokens = continuesResult && _result != null ? [NumToken.fromDecimal(_result!)] : [];
  }

  void digit(String d) {
    assert(d == '00' || (d.length == 1 && '0123456789'.contains(d)));
    _beginInput(continuesResult: false);
    final last = _lastNum;
    if (last == null) {
      _tokens.add(NumToken(d == '00' ? '0' : d));
    } else {
      if (last.percent) return; // "10%5" makes no sense: ignore
      var text = last.text;
      for (final ch in d.split('')) {
        if (text.replaceAll('.', '').length >= maxDigits) break;
        text = (text == '0') ? ch : text + ch;
      }
      _setLast(last.copyWith(text: text));
    }
    notifyListeners();
  }

  void point() {
    _beginInput(continuesResult: false);
    final last = _lastNum;
    if (last == null) {
      _tokens.add(const NumToken('0.'));
    } else if (!last.hasPoint && !last.percent) {
      _setLast(last.copyWith(text: '${last.text}.'));
    }
    notifyListeners();
  }

  void operator(Op op) {
    _beginInput(continuesResult: true);
    if (_tokens.isEmpty) _tokens.add(const NumToken('0'));
    if (_tokens.last is OpToken) {
      _tokens[_tokens.length - 1] = OpToken(op);
    } else {
      _tokens.add(OpToken(op));
    }
    notifyListeners();
  }

  void percent() {
    _beginInput(continuesResult: true);
    final last = _lastNum;
    if (last == null) return;
    _setLast(last.copyWith(percent: !last.percent));
    notifyListeners();
  }

  void toggleSign() {
    _beginInput(continuesResult: true);
    final last = _lastNum;
    if (last == null) {
      _tokens.add(const NumToken('0', negative: true));
    } else {
      _setLast(last.copyWith(negative: !last.negative));
    }
    notifyListeners();
  }

  void backspace() {
    _error = null;
    // A finished calculation is already on the tape and in GT: not editable.
    if (_done || _tokens.isEmpty) return notifyListeners();
    final last = _tokens.last;
    if (last is OpToken) {
      _tokens.removeLast();
    } else if (last is NumToken) {
      if (last.percent) {
        _setLast(last.copyWith(percent: false));
      } else if (last.text.length > 1) {
        _setLast(last.copyWith(text: last.text.substring(0, last.text.length - 1)));
      } else {
        _tokens.removeLast();
      }
    }
    notifyListeners();
  }

  /// AC: clears the expression. Memory, GT and the tape stay.
  void clearAll() {
    _tokens = [];
    _done = false;
    _result = null;
    _error = null;
    notifyListeners();
  }

  /// "=": finishes the calculation, records it on the tape and adds it to GT.
  /// Returns false if it could not be computed.
  bool equals() {
    _error = null;
    if (_done) return true;
    while (_tokens.isNotEmpty && _tokens.last is OpToken) {
      _tokens.removeLast();
    }
    if (_tokens.isEmpty) {
      notifyListeners();
      return false;
    }
    final Decimal value;
    try {
      value = toDecimal(evaluate(_tokens));
    } on DivideByZero catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
    _record(TapeEntry(tokens: List.of(_tokens), result: value, at: _clock()));
    _gt += value;
    _finish(value);
    return true;
  }

  void _finish(Decimal value) {
    _result = value;
    _done = true;
    notifyListeners();
  }

  void _record(TapeEntry e) {
    _history.add(e);
    if (_history.length > maxHistory) _history.removeRange(0, _history.length - maxHistory);
  }

  /// Tax+ (add [rate] percent) or Tax− (take the tax out of a tax-inclusive
  /// amount). Works on the finished result, or finishes the expression first.
  bool tax({required bool add, required Decimal rate}) {
    if (!_done && !equals()) return false;
    final last = _history.isNotEmpty ? _history.last : null;
    if (last == null || _result == null) return false;
    // Apply tax to the value before any tax already applied, so pressing
    // Tax+ twice does not compound.
    final base = last.subtotal;
    final r = rate.toRational() / Decimal.fromInt(100).toRational();
    final Decimal total;
    final Decimal amount;
    if (add) {
      amount = toDecimal(base.toRational() * r);
      total = base + amount;
    } else {
      total = toDecimal(base.toRational() / (Decimal.one.toRational() + r));
      amount = base - total;
    }
    _gt = _gt - last.result + total;
    _history[_history.length - 1] = last.withTax(rate: rate, amount: amount, added: add, result: total);
    _finish(total);
    return true;
  }

  /// The value M+/M− act on: the finished result, after finishing the
  /// expression if one is being typed.
  Decimal? _valueForMemory() {
    if (_done) return _result;
    if (_tokens.isEmpty) return null;
    return equals() ? _result : null;
  }

  void memoryAdd() {
    final v = _valueForMemory();
    if (v == null) return;
    _memory += v;
    notifyListeners();
  }

  void memorySubtract() {
    final v = _valueForMemory();
    if (v == null) return;
    _memory -= v;
    notifyListeners();
  }

  void memoryRecall() => insertValue(_memory);

  void memoryClear() {
    _memory = Decimal.zero;
    notifyListeners();
  }

  void grandTotalRecall() => insertValue(_gt);

  void grandTotalClear() {
    _gt = Decimal.zero;
    notifyListeners();
  }

  /// Puts [value] into the expression as a number: replaces the number being
  /// typed, follows an operator, or starts a new expression.
  void insertValue(Decimal value) {
    _beginInput(continuesResult: false);
    final t = NumToken.fromDecimal(value);
    if (_lastNum != null) {
      _setLast(t);
    } else {
      _tokens.add(t);
    }
    notifyListeners();
  }

  void deleteEntry(int index) {
    _history.removeAt(index);
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  // ---- persistence ----

  Map<String, Object?> toJson() => {
    'tokens': encodeTokens(_tokens),
    'done': _done,
    'result': _result?.toString(),
    'memory': _memory.toString(),
    'gt': _gt.toString(),
    'history': [for (final e in _history) e.toJson()],
  };

  void restore(Map<String, Object?> j) {
    try {
      _tokens = decodeTokens(((j['tokens'] as List?) ?? const []).cast<String>());
      _result = j['result'] == null ? null : Decimal.parse(j['result'] as String);
      _done = (j['done'] as bool? ?? false) && _result != null;
      _memory = Decimal.parse((j['memory'] as String?) ?? '0');
      _gt = Decimal.parse((j['gt'] as String?) ?? '0');
      _history
        ..clear()
        ..addAll([for (final e in (j['history'] as List? ?? const [])) TapeEntry.fromJson((e as Map).cast())]);
    } catch (_) {
      // A corrupt save must never stop the calculator from opening.
      _tokens = [];
      _done = false;
      _result = null;
    }
    notifyListeners();
  }
}
