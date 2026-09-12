import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/sync/hlc.dart';

const phone = 'phone-0000';
const laptop = 'laptop-0000';

void main() {
  group('encoding', () {
    test('round-trips', () {
      const clock = Hlc(1757000000000, 42, laptop);
      expect(Hlc.decode(clock.encode()), clock);
    });

    test('round-trips a uuid node id', () {
      const clock = Hlc(1, 0, 'f3b1c2a0-9d4e-4b7a-8c61-2e5f0a9b7c13');
      expect(Hlc.decode(clock.encode()), clock);
    });

    /// The server compares encoded clocks as plain strings, so this has to hold or
    /// Postgres and the client would disagree about which edit won.
    test('encoded strings sort exactly as compareTo does', () {
      final rng = Random(3);
      final clocks = [
        for (var i = 0; i < 500; i++)
          Hlc(
            rng.nextInt(1 << 31) * 1000 + rng.nextInt(1000),
            rng.nextInt(Hlc.maxCounter),
            ['a', 'b', 'phone', 'laptop'][rng.nextInt(4)],
          ),
      ];

      final byClock = [...clocks]..sort();
      final byString = [...clocks]..sort((x, y) => x.encode().compareTo(y.encode()));

      expect(byString, byClock);
    });

    test('rejects malformed input', () {
      for (final bad in ['', 'nope', '12', '12:34', ':1:x', 'a:1:x', '1:b:x', '1:2:']) {
        expect(() => Hlc.decode(bad), throwsFormatException, reason: bad);
        expect(Hlc.tryDecode(bad), isNull, reason: bad);
      }
      expect(Hlc.tryDecode(null), isNull);
    });
  });

  group('local events', () {
    test('each send is strictly after the last', () {
      var clock = const Hlc.zero(phone);
      for (var i = 0; i < 50; i++) {
        final next = clock.send(1000);
        expect(next > clock, isTrue, reason: 'event $i');
        clock = next;
      }
    });

    test('a later wall clock resets the counter', () {
      final clock = const Hlc(1000, 7, phone).send(2000);
      expect(clock.wallMs, 2000);
      expect(clock.counter, 0);
    });

    test('a wall clock that jumps backwards cannot produce an earlier clock', () {
      // An NTP correction or a manual time change.
      const before = Hlc(5000, 3, phone);
      final after = before.send(1000);

      expect(after > before, isTrue);
      expect(after.wallMs, 5000);
    });

    test('counter overflow advances the wall clock and stays monotonic', () {
      const edge = Hlc(1000, Hlc.maxCounter, phone);
      final next = edge.send(1000);

      expect(next.wallMs, 1001);
      expect(next.counter, 0);
      expect(next > edge, isTrue);
    });
  });

  group('receiving', () {
    test('the result is after both clocks', () {
      const local = Hlc(1000, 5, phone);
      const remote = Hlc(3000, 2, laptop);
      final merged = local.receive(remote, 2000);

      expect(merged > local, isTrue);
      expect(merged > remote, isTrue);
    });

    /// The causal guarantee. A device with a slow clock that has *seen* an edit must
    /// never write something that sorts before it.
    test('after receiving, a slow-clocked device still writes after what it saw', () {
      const laptopEdit = Hlc(10000, 0, laptop);

      // Phone's own clock says 4000 — six seconds behind.
      final phoneClock = const Hlc(4000, 0, phone).receive(laptopEdit, 4000);
      final phoneEdit = phoneClock.send(4000);

      expect(phoneEdit > laptopEdit, isTrue);
    });

    test('equal wall times take the larger counter and step past it', () {
      final merged = const Hlc(1000, 3, phone).receive(
        const Hlc(1000, 9, laptop),
        1000,
      );
      expect(merged.wallMs, 1000);
      expect(merged.counter, 10);
    });

    test('a real clock ahead of both resets the counter', () {
      final merged = const Hlc(1000, 3, phone).receive(
        const Hlc(1500, 9, laptop),
        9000,
      );
      expect(merged.wallMs, 9000);
      expect(merged.counter, 0);
    });

    test('refuses a clock implausibly far in the future', () {
      // A phone set to the wrong year. Accepting it would drag every clock forward, and
      // a correctly-clocked device's genuinely later edit would then lose.
      final wrongYear = Hlc(
        const Duration(days: 400).inMilliseconds,
        0,
        laptop,
      );

      expect(
        () => const Hlc.zero(phone).receive(wrongYear, 0),
        throwsA(isA<ClockDriftException>()),
      );
    });

    test('tolerates ordinary skew inside the limit', () {
      final slightlyAhead = Hlc(
        const Duration(minutes: 2).inMilliseconds,
        0,
        laptop,
      );
      expect(
        () => const Hlc.zero(phone).receive(slightlyAhead, 0),
        returnsNormally,
      );
    });
  });

  test('clocks differing only by device are ordered, never equal', () {
    const a = Hlc(1000, 0, 'a');
    const b = Hlc(1000, 0, 'b');
    expect(a == b, isFalse);
    expect(a < b, isTrue);
  });
}
