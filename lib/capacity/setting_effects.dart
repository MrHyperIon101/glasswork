import 'ledger.dart';
import 'timetable.dart';

/// What each capacity setting is doing to the figures, and what one step more would change.
///
/// Worked out by running the ledger again with the setting moved, never by a formula of its
/// own: a description that did its own arithmetic could drift from the arithmetic it
/// describes, and then it would be explaining numbers the app does not produce.
///
/// Averaged over a week, because one day misleads: a Saturday with no classes and a Monday
/// packed with them respond to the same setting very differently.
class SettingEffects {
  const SettingEffects({
    required this.usablePerDay,
    required this.overheadPerDay,
    required this.discardedPerDay,
    required this.mealsStep,
    required this.bufferStep,
    required this.focusStep,
    required this.minGapStep,
    required this.shortNights,
  });

  /// How far one step of each setting moves.
  static const mealsStepMin = 15;
  static const bufferStepMin = 15;
  static const focusStepPercent = 5;
  static const minGapStepMin = 5;

  /// Minutes to spend on an average day of the week measured.
  final int usablePerDay;

  /// Meals and buffer as actually taken out on an average day. Less than the two settings
  /// together when a day has less free time than they ask for.
  final int overheadPerDay;

  /// Free minutes an average day loses to stretches shorter than the shortest usable gap.
  final int discardedPerDay;

  /// How the minutes to spend on an average day change with one step more of each setting.
  /// Negative is less time to spend.
  final int mealsStep;
  final int bufferStep;
  final int focusStep;
  final int minGapStep;

  /// Nights shorter than the sleep target, by the day they follow, with their length.
  final Map<int, int> shortNights;

  /// The effects of [settings] over [days] days from [from], with [timetable].
  static SettingEffects of(
    CapacitySettings settings,
    Timetable timetable,
    DateTime from, {
    int days = 7,
  }) {
    final base = CapacityLedger.forRange(from, days, settings, timetable);
    final baseUsable = base.fold(0, (sum, d) => sum + d.usableMin);

    int perDay(num total) => (total / days).round();
    int step(CapacitySettings changed) => perDay(
      CapacityLedger.forRange(
            from,
            days,
            changed,
            timetable,
          ).fold(0, (sum, d) => sum + d.usableMin) -
          baseUsable,
    );

    return SettingEffects(
      usablePerDay: perDay(baseUsable),
      overheadPerDay: perDay(base.fold(0, (sum, d) => sum + d.overheadMin)),
      discardedPerDay: perDay(base.fold(0, (sum, d) => sum + d.discardedGapMin)),
      mealsStep: step(
        settings.copyWith(mealsMin: settings.mealsMin + mealsStepMin),
      ),
      bufferStep: step(
        settings.copyWith(bufferMin: settings.bufferMin + bufferStepMin),
      ),
      focusStep: step(
        settings.copyWith(
          focusFactor: (settings.focusFactor + focusStepPercent / 100).clamp(
            0.0,
            1.0,
          ),
        ),
      ),
      minGapStep: step(
        settings.copyWith(minGapMin: settings.minGapMin + minGapStepMin),
      ),
      shortNights: {
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          if (settings.nightAfter(day) < settings.sleepTargetMin)
            day: settings.nightAfter(day),
      },
    );
  }
}
