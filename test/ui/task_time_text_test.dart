import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/capacity/slot_check.dart';
import 'package:glasswork/ui/task_time_text.dart';

void main() {
  test('a clear time says so, and a day beyond the budget says that', () {
    expect(TaskTimeText.check(const []), (clear: true, text: 'In your free time.'));
    expect(TaskTimeText.check(null).clear, isTrue);
  });

  test('everything in the way is named, in order', () {
    expect(
      TaskTimeText.check(const [
        SlotAsleep(),
        SlotClash(title: 'OS lab', startMin: 14 * 60, endMin: 17 * 60),
      ]),
      (
        clear: false,
        text: 'It falls while you are asleep. It clashes with OS lab, 14:00–17:00.',
      ),
    );
    expect(TaskTimeText.check(const [SlotPastMidnight()]).text, 'It runs past midnight.');
  });

  test('the way out names the time it moves to', () {
    expect(TaskTimeText.moveTo(17 * 60), 'Move to 17:00');
  });
}
