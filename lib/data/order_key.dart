/// Fractional index strings for ordering rows.
///
/// Dragging a card between two neighbours computes a key strictly between theirs, so a
/// reorder writes exactly one row. Integer positions would require rewriting every
/// sibling, and two offline clients doing that produce a merge that cannot be resolved.
///
/// The encoding is the well-known fractional-indexing scheme: a key is an *integer part*
/// followed by an optional *fractional part*. The integer part's first character is a
/// header encoding both sign and length — `a`-`z` for ascending magnitudes and `Z`-`A`
/// for descending ones. That header is what makes the keyspace extensible in **both**
/// directions.
///
/// A naive fixed-width alphabet cannot do this: nothing sorts before `'0'`, so repeatedly
/// inserting at the top of a list hits a floor after about five operations and then has
/// no valid answer. "Add to the top" is an ordinary thing to do, so the floor is not
/// acceptable.
///
/// The alphabet is ASCII-ascending, so plain string comparison is the sort order and
/// SQLite needs no custom collation.
///
/// Two offline clients can still generate the *identical* key between the same pair of
/// neighbours. That is expected and harmless: every query orders by
/// `(orderKey, clientId)`, so the total order stays deterministic.
abstract final class OrderKey {
  static const _digits =
      '0123456789'
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      'abcdefghijklmnopqrstuvwxyz';

  static const _smallestInteger = 'A00000000000000000000000000';

  /// The key for the first row in an empty list.
  static const first = 'a0';

  /// A key strictly between [lower] and [upper].
  ///
  /// Null means unbounded: `between(null, x)` sorts before `x`, `between(x, null)` after.
  static String between(String? lower, String? upper) {
    if (lower != null && upper != null && lower.compareTo(upper) >= 0) {
      throw ArgumentError(
        'lower must sort before upper, got "$lower" >= "$upper"',
      );
    }

    if (lower == null) {
      if (upper == null) return first;

      final intUpper = _integerPart(upper);
      final fracUpper = upper.substring(intUpper.length);

      if (intUpper == _smallestInteger) {
        return intUpper + _midpoint('', fracUpper);
      }
      if (intUpper.compareTo(upper) < 0) return intUpper;

      final decremented = _decrement(intUpper);
      if (decremented == null) {
        throw StateError('order keyspace exhausted below "$upper"');
      }
      return decremented;
    }

    if (upper == null) {
      final intLower = _integerPart(lower);
      final fracLower = lower.substring(intLower.length);
      final incremented = _increment(intLower);
      return incremented ?? intLower + _midpoint(fracLower, null);
    }

    final intLower = _integerPart(lower);
    final fracLower = lower.substring(intLower.length);
    final intUpper = _integerPart(upper);
    final fracUpper = upper.substring(intUpper.length);

    if (intLower == intUpper) {
      return intLower + _midpoint(fracLower, fracUpper);
    }

    final incremented = _increment(intLower);
    if (incremented == null) {
      throw StateError('order keyspace exhausted above "$lower"');
    }
    if (incremented.compareTo(upper) < 0) return incremented;
    return intLower + _midpoint(fracLower, null);
  }

  /// A key sorting after [lower].
  static String after(String lower) => between(lower, null);

  /// A key sorting before [upper].
  static String before(String upper) => between(null, upper);

  // --- encoding internals ---

  /// Length of the integer part, read from its header character.
  static int _integerLength(String head) {
    if (head.compareTo('a') >= 0 && head.compareTo('z') <= 0) {
      return head.codeUnitAt(0) - 'a'.codeUnitAt(0) + 2;
    }
    if (head.compareTo('A') >= 0 && head.compareTo('Z') <= 0) {
      return 'Z'.codeUnitAt(0) - head.codeUnitAt(0) + 2;
    }
    throw ArgumentError('invalid order key header: "$head"');
  }

  static String _integerPart(String key) {
    if (key.isEmpty) throw ArgumentError('empty order key');
    final len = _integerLength(key[0]);
    if (len > key.length) {
      throw ArgumentError('order key "$key" is shorter than its header claims');
    }
    return key.substring(0, len);
  }

  /// Next integer part, or null if the headers are exhausted at the top.
  static String? _increment(String x) {
    final head = x[0];
    final digits = x.substring(1).split('');

    var carry = true;
    for (var i = digits.length - 1; carry && i >= 0; i--) {
      final d = _digits.indexOf(digits[i]) + 1;
      if (d == _digits.length) {
        digits[i] = _digits[0];
      } else {
        digits[i] = _digits[d];
        carry = false;
      }
    }

    if (!carry) return head + digits.join();

    // Overflowed this magnitude — move to the next header up.
    if (head == 'Z') return 'a${_digits[0]}';
    if (head == 'z') return null;

    final next = String.fromCharCode(head.codeUnitAt(0) + 1);
    if (next.compareTo('a') > 0) {
      digits.add(_digits[0]);
    } else {
      digits.removeLast();
    }
    return next + digits.join();
  }

  /// Previous integer part, or null if the headers are exhausted at the bottom.
  static String? _decrement(String x) {
    final head = x[0];
    final digits = x.substring(1).split('');

    var borrow = true;
    for (var i = digits.length - 1; borrow && i >= 0; i--) {
      final d = _digits.indexOf(digits[i]) - 1;
      if (d == -1) {
        digits[i] = _digits[_digits.length - 1];
      } else {
        digits[i] = _digits[d];
        borrow = false;
      }
    }

    if (!borrow) return head + digits.join();

    if (head == 'a') return 'Z${_digits[_digits.length - 1]}';
    if (head == 'A') return null;

    final prev = String.fromCharCode(head.codeUnitAt(0) - 1);
    if (prev.compareTo('Z') < 0) {
      digits.add(_digits[_digits.length - 1]);
    } else {
      digits.removeLast();
    }
    return prev + digits.join();
  }

  /// A fractional part strictly between [a] and [b], never ending in the zero digit.
  ///
  /// [b] null means unbounded above.
  static String _midpoint(String a, String? b) {
    if (b != null && a.compareTo(b) >= 0) {
      throw ArgumentError('midpoint bounds out of order: "$a" >= "$b"');
    }
    if (a.isNotEmpty && a[a.length - 1] == _digits[0]) {
      throw ArgumentError('fractional part "$a" must not end in a zero digit');
    }
    if (b != null && b.isNotEmpty && b[b.length - 1] == _digits[0]) {
      throw ArgumentError('fractional part "$b" must not end in a zero digit');
    }

    if (b != null) {
      // Strip the common prefix and recurse on the remainder.
      var n = 0;
      while (n < b.length) {
        final ca = n < a.length ? a[n] : _digits[0];
        if (ca != b[n]) break;
        n++;
      }
      if (n > 0) {
        final restA = n < a.length ? a.substring(n) : '';
        return b.substring(0, n) + _midpoint(restA, b.substring(n));
      }
    }

    final digitA = a.isNotEmpty ? _digits.indexOf(a[0]) : 0;
    final digitB = b != null && b.isNotEmpty
        ? _digits.indexOf(b[0])
        : _digits.length;

    if (digitB - digitA > 1) {
      final mid = (0.5 * (digitA + digitB)).round();
      return _digits[mid];
    }

    // Digits are adjacent: borrow a place from b, or descend into a.
    if (b != null && b.length > 1) {
      return b.substring(0, 1);
    }
    return _digits[digitA] +
        _midpoint(a.isNotEmpty ? a.substring(1) : '', null);
  }
}
