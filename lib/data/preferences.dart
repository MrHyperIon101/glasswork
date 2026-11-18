/// How the app's surfaces are drawn on this device.
///
/// [liquid] bends what is behind each surface at its edges and catches the light along its
/// rim; [frosted] only blurs it; [solid] draws plain opaque surfaces, which costs the GPU
/// least. Liquid needs a renderer that runs shaders as filters, and reads as frosted where
/// there is none.
enum Glass {
  liquid,
  frosted,
  solid;

  /// The stored value, or null for anything unrecognised — a value written by a newer
  /// version must not stop an older one opening.
  static Glass? named(String? name) {
    for (final glass in values) {
      if (glass.name == name) return glass;
    }
    return null;
  }
}

/// How Glasswork behaves on this device, as chosen in Settings.
///
/// Choices about the app rather than the work, so they are kept on the device they were
/// made on (`LocalSettings`), not synced. Settings that shape the work itself — sleep,
/// meals, focus — are synced with it, in the capacity profile.
///
/// Every value is kept inside its bounds, however it was stored: a value from a damaged or
/// hand-edited database reads as the nearest one allowed, or as the default.
class Preferences {
  const Preferences({
    this.morningMin = defaultMorningMin,
    this.eveningMin = defaultEveningMin,
    this.snoozeMin = defaultSnoozeMin,
    this.captureProjectId,
    this.keepInTray = false,
    this.glass,
  });

  /// When a "morning" reminder is: "Tomorrow morning", "The morning it is due", and a
  /// typed "remind fri" that names no time. Minutes past midnight.
  final int morningMin;

  /// When an "evening" reminder is: "This evening" and "The evening before".
  final int eveningMin;

  /// How long Snooze on a reminder waits, in minutes.
  final int snoozeMin;

  /// The project a task added from outside any project goes to. Null for the first
  /// project, and ignored once that project is gone.
  final String? captureProjectId;

  /// On a desktop, whether closing the window leaves Glasswork running in the tray.
  final bool keepInTray;

  /// How surfaces are drawn, as chosen here. Null until a choice is made, when the device's
  /// own default applies — see `glassProvider`.
  final Glass? glass;

  static const defaultMorningMin = 9 * 60;
  static const defaultEveningMin = 18 * 60;
  static const defaultSnoozeMin = 10;

  static const earliestMorningMin = 4 * 60;
  static const latestMorningMin = 12 * 60;
  static const earliestEveningMin = 12 * 60;
  static const latestEveningMin = 23 * 60 + 45;
  static const shortestSnoozeMin = 1;
  static const longestSnoozeMin = 4 * 60;

  /// The lengths Snooze steps through.
  static const snoozeSteps = [5, 10, 15, 30, 60, 120];

  Duration get snooze => Duration(minutes: snoozeMin);

  static int clampMorning(int minutes) =>
      minutes.clamp(earliestMorningMin, latestMorningMin);

  static int clampEvening(int minutes) =>
      minutes.clamp(earliestEveningMin, latestEveningMin);

  static int clampSnooze(int minutes) =>
      minutes.clamp(shortestSnoozeMin, longestSnoozeMin);

  /// The snooze length one step from [minutes] in [direction], -1 or 1. From a length
  /// between steps, the next step that way.
  static int stepSnooze(int minutes, int direction) {
    if (direction > 0) {
      return snoozeSteps.firstWhere(
        (s) => s > minutes,
        orElse: () => snoozeSteps.last,
      );
    }
    return snoozeSteps.lastWhere(
      (s) => s < minutes,
      orElse: () => snoozeSteps.first,
    );
  }

  /// Preferences from what `LocalSettings` holds under each key.
  factory Preferences.fromStored(Map<String, String> stored) {
    int read(String key, int fallback, int Function(int) clamp) =>
        switch (int.tryParse(stored[key] ?? '')) {
          final value? => clamp(value),
          null => fallback,
        };

    final project = stored[captureProjectKey];
    return Preferences(
      morningMin: read(morningKey, defaultMorningMin, clampMorning),
      eveningMin: read(eveningKey, defaultEveningMin, clampEvening),
      snoozeMin: read(snoozeKey, defaultSnoozeMin, clampSnooze),
      captureProjectId: project == null || project.isEmpty ? null : project,
      keepInTray: stored[keepInTrayKey] == 'true',
      glass: Glass.named(stored[glassKey]),
    );
  }

  static const morningKey = 'pref.morning_min';
  static const eveningKey = 'pref.evening_min';
  static const snoozeKey = 'pref.snooze_min';
  static const captureProjectKey = 'pref.capture_project_id';
  static const keepInTrayKey = 'pref.keep_in_tray';
  static const glassKey = 'pref.glass';

  static const keys = {
    morningKey,
    eveningKey,
    snoozeKey,
    captureProjectKey,
    keepInTrayKey,
    glassKey,
  };

  @override
  bool operator ==(Object other) =>
      other is Preferences &&
      other.morningMin == morningMin &&
      other.eveningMin == eveningMin &&
      other.snoozeMin == snoozeMin &&
      other.captureProjectId == captureProjectId &&
      other.keepInTray == keepInTray &&
      other.glass == glass;

  @override
  int get hashCode =>
      Object.hash(morningMin, eveningMin, snoozeMin, captureProjectId, keepInTray, glass);

  @override
  String toString() =>
      'Preferences(morning: $morningMin, evening: $eveningMin, snooze: $snoozeMin, '
      'project: $captureProjectId, tray: $keepInTray, glass: $glass)';
}
