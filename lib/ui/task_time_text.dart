import '../capacity/slot_check.dart';
import 'format.dart';

/// What the time chosen for a task says about itself, worked out from what stands in its
/// way. Pure, so each sentence is checked by a test rather than put together in a widget.
abstract final class TaskTimeText {
  /// Whether the time is clear, and if not, what is in its way, in a line. [problems] is
  /// null for a day further ahead than the time budget counts.
  static ({String text, bool clear}) check(List<SlotProblem>? problems) {
    if (problems == null) {
      return (clear: true, text: 'Further ahead than the time budget counts, for now.');
    }
    if (problems.isEmpty) return (clear: true, text: 'In your free time.');

    final sentences = [
      for (final problem in problems)
        switch (problem) {
          SlotAsleep() => 'It falls while you are asleep.',
          SlotPastMidnight() => 'It runs past midnight.',
          SlotClash(:final title, :final startMin, :final endMin) =>
            'It clashes with $title, ${Format.clockRange(startMin, endMin)}.',
        },
    ];
    return (clear: false, text: sentences.join(' '));
  }

  /// The button that moves the time to where it fits.
  static String moveTo(int startMin) => 'Move to ${Format.clock(startMin)}';
}
