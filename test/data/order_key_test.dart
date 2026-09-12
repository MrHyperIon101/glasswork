import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/order_key.dart';

void main() {
  test('first key leaves room to insert above it', () {
    final f = OrderKey.first;
    expect(OrderKey.before(f).compareTo(f), lessThan(0));
    expect(OrderKey.after(f).compareTo(f), greaterThan(0));
  });

  test('between lands strictly inside the bounds', () {
    final a = OrderKey.first;
    final b = OrderKey.after(a);
    final mid = OrderKey.between(a, b);

    expect(a.compareTo(mid), lessThan(0));
    expect(mid.compareTo(b), lessThan(0));
  });

  test('rejects bounds given in the wrong order', () {
    expect(() => OrderKey.between('b', 'a'), throwsArgumentError);
    expect(() => OrderKey.between('a', 'a'), throwsArgumentError);
  });

  test('repeated insertion at the same point stays ordered', () {
    // The pathological case: always inserting between the first two keys. Keys get
    // longer, but the order must never break.
    var lo = OrderKey.first;
    final hi = OrderKey.after(lo);

    final generated = <String>[];
    for (var i = 0; i < 200; i++) {
      final k = OrderKey.between(lo, hi);
      expect(lo.compareTo(k), lessThan(0), reason: 'iteration $i');
      expect(k.compareTo(hi), lessThan(0), reason: 'iteration $i');
      generated.add(k);
      lo = k;
    }

    final sorted = [...generated]..sort();
    expect(generated, sorted, reason: 'generated keys must already be in order');
  });

  test('survives random interleaved insertions', () {
    final rng = Random(7);
    final keys = <String>[OrderKey.first];

    for (var i = 0; i < 400; i++) {
      final at = rng.nextInt(keys.length + 1);
      final lower = at == 0 ? null : keys[at - 1];
      final upper = at == keys.length ? null : keys[at];
      keys.insert(at, OrderKey.between(lower, upper));
    }

    final sorted = [...keys]..sort();
    expect(keys, sorted);
    expect(keys.toSet(), hasLength(keys.length), reason: 'keys must be unique');
  });

  test('inserting before the smallest key keeps working', () {
    // Prepending repeatedly is the operation most likely to hit the bottom of the
    // keyspace. It must not.
    var top = OrderKey.first;
    for (var i = 0; i < 100; i++) {
      final next = OrderKey.before(top);
      expect(next.compareTo(top), lessThan(0), reason: 'iteration $i');
      top = next;
    }
  });

  test('prepending 1000 times never exhausts the keyspace', () {
    // The header character is what makes this possible; a fixed-width alphabet hits a
    // floor after about five prepends.
    var top = OrderKey.first;
    final all = <String>[top];
    for (var i = 0; i < 1000; i++) {
      final next = OrderKey.before(top);
      expect(next.compareTo(top), lessThan(0), reason: 'iteration $i');
      top = next;
      all.add(top);
    }
    final sorted = [...all]..sort();
    expect(all.reversed.toList(), sorted);
  });

  test('appending 1000 times never exhausts the keyspace', () {
    var end = OrderKey.first;
    for (var i = 0; i < 1000; i++) {
      final next = OrderKey.after(end);
      expect(next.compareTo(end), greaterThan(0), reason: 'iteration $i');
      end = next;
    }
  });

  test('rejects malformed keys', () {
    expect(() => OrderKey.after('!'), throwsArgumentError);
    expect(() => OrderKey.after(''), throwsArgumentError);
  });
}
