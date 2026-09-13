import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/sync_controller.dart';
import '../../state/sync_summary.dart';
import '../../sync/account_link.dart';
import '../../sync/sync_auth.dart';
import '../../theme/tokens.dart';
import '../motion.dart';
import '../surface.dart';
import 'field_controls.dart';
import 'sync_status.dart';

/// Signing in and syncing, in one sheet.
///
/// What it shows follows [SyncState]: an email and password, the one choice a second
/// device has to make, and once syncing, how it stands.
class SyncSheet extends ConsumerWidget {
  const SyncSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(syncSheetOpenProvider)) return const SizedBox.shrink();

    void close() => ref.read(syncSheetOpenProvider.notifier).close();

    return Stack(
      children: [
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.quick,
            builder: (context, t, _) => GestureDetector(
              onTap: close,
              child: ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.62 * t)),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -0.2),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xxl),
            child: SpringIn(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: VibrancyMaterial.sheet(
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.escape): close,
                    },
                    child: _Body(onClose: close),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncProvider);

    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: switch (state) {
        SyncStarting() => _Checking(onClose: onClose),
        final SyncSignedOut s => _AccountStep(notice: s.notice, onClose: onClose),
        final SyncLinking s => _LinkingStep(state: s, onClose: onClose),
        final SyncChoosing s => _ChoiceStep(state: s),
        SyncLinkedElsewhere() => _ElsewhereStep(onClose: onClose),
        final SyncOn s => _OnStep(state: s),
      },
    );
  }
}

/// The sheet's layout: a heading, the step's content, and its buttons along the bottom.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.title,
    required this.subtitle,
    required this.actions,
    this.child,
  });

  final String title;
  final String subtitle;
  final Widget? child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xxl,
            AppSpace.xl,
            AppSpace.xxl,
            AppSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.title),
              const SizedBox(height: AppSpace.xs),
              Text(subtitle, style: AppText.callout),
            ],
          ),
        ),
        if (child case final content?) ...[
          const AppDivider(),
          Padding(padding: const EdgeInsets.all(AppSpace.xxl), child: content),
        ],
        const AppDivider(),
        Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            children: [
              const Spacer(),
              for (final (i, action) in actions.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpace.sm),
                action,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration(String hint, {Widget? suffix}) =>
    InputDecoration(
      filled: true,
      fillColor: AppColour.fill,
      border: const OutlineInputBorder(
        borderRadius: AppRadius.mediumAll,
        borderSide: BorderSide.none,
      ),
      hintText: hint,
      hintStyle: AppText.body.copyWith(color: AppColour.labelTertiary),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.md,
      ),
    );

/// A line under a field: guidance normally, the error in red when there is one.
class _Hint extends StatelessWidget {
  const _Hint({required this.text, this.error});

  final String text;
  final String? error;

  @override
  Widget build(BuildContext context) => Text(
    error ?? text,
    style: AppText.footnote.copyWith(
      color: error == null ? AppColour.labelTertiary : AppColour.red,
    ),
  );
}

class _Checking extends StatelessWidget {
  const _Checking({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => _Frame(
    title: 'Sync',
    subtitle: 'Checking whether this device is signed in…',
    actions: [PrimaryButton(label: 'Done', enabled: true, onTap: onClose)],
  );
}

// --- step: signing in -------------------------------------------------------------------

class _AccountStep extends ConsumerStatefulWidget {
  const _AccountStep({required this.onClose, this.notice});

  final VoidCallback onClose;
  final String? notice;

  @override
  ConsumerState<_AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends ConsumerState<_AccountStep> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// Making an account, rather than signing in to one.
  bool _creating = false;
  bool _revealed = false;
  bool _busy = false;
  String? _error;

  static final _looksLikeEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool get _ready =>
      _looksLikeEmail.hasMatch(_email.text.trim()) &&
      _password.text.length >=
          (_creating ? SyncAuth.minimumPasswordLength : 1);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_ready || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final sync = ref.read(syncProvider.notifier);
    final email = _email.text.trim();
    try {
      if (_creating) {
        await sync.createAccount(email, _password.text);
      } else {
        await sync.signIn(email, _password.text);
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _error = describeSyncError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clearError(String _) {
    if (_error != null) setState(() => _error = null);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final creating = _creating;

    return _Frame(
      title: creating ? 'Create your account' : 'Sync',
      subtitle:
          widget.notice ??
          (creating
              ? 'One account for all your devices. You sign in with it on each of them.'
              : 'Sign in to use your tasks on every device. Everything keeps working offline.'),
      actions: [
        GhostButton(label: 'Cancel', onTap: widget.onClose),
        PrimaryButton(
          label: switch ((creating, _busy)) {
            (true, true) => 'Creating…',
            (true, false) => 'Create account',
            (false, true) => 'Signing in…',
            (false, false) => 'Sign in',
          },
          enabled: _ready && !_busy,
          onTap: _submit,
        ),
      ],
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email', style: AppText.caption),
            const SizedBox(height: AppSpace.sm),
            TextField(
              controller: _email,
              autofocus: true,
              readOnly: _busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textInputAction: TextInputAction.next,
              style: AppText.body,
              cursorColor: AppColour.accent,
              onChanged: _clearError,
              decoration: _fieldDecoration('you@example.com'),
            ),
            const SizedBox(height: AppSpace.lg),
            Text('Password', style: AppText.caption),
            const SizedBox(height: AppSpace.sm),
            TextField(
              controller: _password,
              readOnly: _busy,
              obscureText: !_revealed,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: [
                creating ? AutofillHints.newPassword : AutofillHints.password,
              ],
              textInputAction: TextInputAction.done,
              style: AppText.body,
              cursorColor: AppColour.accent,
              onChanged: _clearError,
              onSubmitted: (_) => _submit(),
              decoration: _fieldDecoration(
                creating
                    ? 'At least ${SyncAuth.minimumPasswordLength} characters'
                    : 'Your password',
                suffix: IconButton(
                  tooltip: _revealed ? 'Hide password' : 'Show password',
                  onPressed: () => setState(() => _revealed = !_revealed),
                  icon: Icon(
                    _revealed
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 17,
                    color: AppColour.labelTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            _Hint(
              text: creating
                  ? 'Use this same email and password on your other devices.'
                  : 'Your tasks stay on this device whether you sign in or not.',
              error: _error,
            ),
            const SizedBox(height: AppSpace.sm),
            GhostButton(
              label: creating
                  ? 'Already have an account? Sign in'
                  : 'New here? Create an account',
              onTap: () => setState(() {
                _creating = !_creating;
                _error = null;
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// --- step: linking ----------------------------------------------------------------------

class _LinkingStep extends ConsumerWidget {
  const _LinkingStep({required this.state, required this.onClose});

  final SyncLinking state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.read(syncProvider.notifier);
    final error = state.error;

    if (error == null) {
      return _Frame(
        title: 'Setting up sync',
        subtitle: 'Getting ${state.account.email ?? 'your account'} ready on this device.',
        actions: [GhostButton(label: 'Close', onTap: onClose)],
        child: Row(
          children: [
            const SizedBox.square(
              dimension: AppSpace.lg,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColour.accent,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                'The first time can take a moment. You can keep working meanwhile.',
                style: AppText.footnote,
              ),
            ),
          ],
        ),
      );
    }

    return _Frame(
      title: "Sync isn't set up yet",
      subtitle: error,
      actions: [
        GhostButton(label: 'Sign out', onTap: sync.signOut),
        PrimaryButton(label: 'Try again', enabled: true, onTap: sync.retry),
      ],
    );
  }
}

// --- step: choosing ---------------------------------------------------------------------

class _ChoiceStep extends ConsumerStatefulWidget {
  const _ChoiceStep({required this.state});

  final SyncChoosing state;

  @override
  ConsumerState<_ChoiceStep> createState() => _ChoiceStepState();
}

class _ChoiceStepState extends ConsumerState<_ChoiceStep> {
  LinkChoice _choice = LinkChoice.combine;

  @override
  Widget build(BuildContext context) {
    final sync = ref.read(syncProvider.notifier);

    return _Frame(
      title: 'This account already has work',
      subtitle:
          'Another device has synced to it. Choose what happens to the work on this device.',
      actions: [
        GhostButton(label: 'Sign out', onTap: sync.signOut),
        PrimaryButton(
          label: 'Continue',
          enabled: true,
          onTap: () => sync.choose(_choice),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('On this device', style: AppText.caption),
          const SizedBox(height: AppSpace.xs),
          Text(
            describeDeviceContent(widget.state.plan.device),
            style: AppText.numeric.copyWith(color: AppColour.label),
          ),
          const SizedBox(height: AppSpace.lg),
          _OptionRow(
            title: "Add this device's work to the account",
            detail:
                'Nothing is removed. A project both devices have will show up twice, and you can delete either.',
            selected: _choice == LinkChoice.combine,
            onTap: () => setState(() => _choice = LinkChoice.combine),
          ),
          _OptionRow(
            title: "Use only the account's work",
            detail:
                'The work on this device is removed from it. A backup copy is saved first.',
            selected: _choice == LinkChoice.replace,
            onTap: () => setState(() => _choice = LinkChoice.replace),
          ),
          if (widget.state.error case final error?) ...[
            const SizedBox(height: AppSpace.sm),
            _Hint(text: '', error: error),
          ],
        ],
      ),
    );
  }
}

class _OptionRow extends StatefulWidget {
  const _OptionRow({
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.quick,
          curve: AppMotion.standard,
          margin: const EdgeInsets.only(bottom: AppSpace.xs),
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColour.accent.withValues(alpha: 0.14)
                : _hovered
                ? AppColour.fill
                : null,
            borderRadius: AppRadius.mediumAll,
            border: Border.all(
              color: widget.selected
                  ? AppColour.accent.withValues(alpha: 0.5)
                  : const Color(0x00000000),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                widget.selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 17,
                color: widget.selected
                    ? AppColour.accent
                    : AppColour.labelTertiary,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppText.headline),
                    const SizedBox(height: 2),
                    Text(widget.detail, style: AppText.footnote),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- step: another account --------------------------------------------------------------

class _ElsewhereStep extends ConsumerWidget {
  const _ElsewhereStep({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Frame(
    title: 'This device syncs with another account',
    subtitle:
        "Its work already belongs to that account, so it can't join this one. Sign in with the account this device used before.",
    actions: [
      GhostButton(label: 'Close', onTap: onClose),
      PrimaryButton(
        label: 'Sign out',
        enabled: true,
        onTap: ref.read(syncProvider.notifier).signOut,
      ),
    ],
  );
}

// --- step: syncing ----------------------------------------------------------------------

class _OnStep extends ConsumerWidget {
  const _OnStep({required this.state});

  final SyncOn state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.read(syncProvider.notifier);
    final summary = summarizeSync(state, DateTime.now());

    return _Frame(
      title: 'Sync',
      subtitle: state.account.email ?? 'Signed in',
      actions: [
        GhostButton(label: 'Sign out', onTap: sync.signOut),
        PrimaryButton(
          label: state.syncing ? 'Syncing…' : 'Sync now',
          enabled: !state.syncing,
          onTap: sync.syncNow,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                syncIcon(state),
                size: 17,
                color: syncToneColour(summary.tone),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.title, style: AppText.headline),
                    Text(summary.detail, style: AppText.footnote),
                  ],
                ),
              ),
            ],
          ),
          // The specifics, only when they help: an unexplained failure.
          if (state.problem == SyncProblem.failed && state.detail != null) ...[
            const SizedBox(height: AppSpace.md),
            SelectableText(
              state.detail!,
              style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          Text(
            'Signing out stops syncing. Everything stays on this device.',
            style: AppText.footnote.copyWith(color: AppColour.labelTertiary),
          ),
        ],
      ),
    );
  }
}
