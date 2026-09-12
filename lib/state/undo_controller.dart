import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';

/// A destructive action that can still be taken back.
class UndoOffer {
  const UndoOffer({required this.label, required this.revert});

  /// What happened, in plain words. Shown in the toast: "Task deleted".
  final String label;

  /// Puts it back. Must be safe to call once.
  final Future<void> Function() revert;
}

/// Holds the single pending undo, if any.
///
/// Every destructive action in the app goes through here — `docs/architecture.md` requires that
/// they all be undoable for five seconds, and routing them through one controller is
/// what stops that from being a thing each screen remembers to do separately.
class UndoController extends Notifier<UndoOffer?> {
  Timer? _timer;

  @override
  UndoOffer? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  /// Replaces any pending offer — the newest destructive action is the one a user means
  /// to undo, and stacking them would make the toast lie about which.
  void offer(String label, Future<void> Function() revert) {
    _timer?.cancel();
    state = UndoOffer(label: label, revert: revert);
    _timer = Timer(AppMotion.undoWindow, () {
      if (ref.mounted) state = null;
    });
  }

  Future<void> undo() async {
    final pending = state;
    if (pending == null) return;
    _timer?.cancel();
    state = null;
    await pending.revert();
  }

  void dismiss() {
    _timer?.cancel();
    state = null;
  }
}

final undoProvider = NotifierProvider<UndoController, UndoOffer?>(
  UndoController.new,
);
