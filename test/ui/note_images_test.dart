import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glasswork/data/db/database.dart';
import 'package:glasswork/images/device_images.dart';
import 'package:glasswork/images/image_store.dart';
import 'package:glasswork/main.dart';
import 'package:glasswork/state/providers.dart';
import 'package:glasswork/state/sync_controller.dart';
import 'package:glasswork/state/undo_controller.dart';
import 'package:glasswork/ui/screens/app_shell.dart';
import 'package:glasswork/ui/widgets/note_images.dart';
import 'package:glasswork/ui/widgets/note_widgets.dart';

/// A device whose picker hands back whatever the test has put on it.
class FakeDeviceImages extends DeviceImages {
  List<PickedImage> next = const [];

  @override
  Future<List<PickedImage>> pick() async => next;

  @override
  bool get canPaste => false;
}

PickedImage picture(int shade) => PickedImage(
  bytes: Uint8List.fromList(List.filled(32, shade)),
  width: 1200,
  height: 800,
  mime: 'image/jpeg',
);

/// Images in notes: added, shown, removed with a way back.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProviderContainer app;
  late Directory folder;
  late FakeDeviceImages device;

  Future<void> start(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    db = AppDatabase(NativeDatabase.memory());
    folder = (await tester.runAsync(() => Directory.systemTemp.createTemp('glasswork_notes_')))!;
    device = FakeDeviceImages();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) => db),
          syncProvider.overrideWith(() => _Held(const SyncSignedOut())),
          imageFolderProvider.overrideWith((ref) async => folder),
          deviceImagesProvider.overrideWithValue(device),
        ],
        child: const GlassworkApp(),
      ),
    );
    await _settle(tester);
    app = ProviderScope.containerOf(tester.element(find.byType(AppShell)));
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() async {
      await db.close();
      await folder.delete(recursive: true);
    });
  }

  Future<List<NoteImage>> storedImages(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.noteImages).get()))!;

  testWidgets('images added in a new note make the note, keep their files, and can be removed', (
    tester,
  ) async {
    await start(tester);
    try {
      app.read(openNoteProvider.notifier).create();
      await _settle(tester);
      device.next = [picture(1), picture(2)];
      await tester.tap(find.byKey(const ValueKey('note-add-images')));
      await _settle(tester);

      final notes = (await tester.runAsync(() => db.select(db.notes).get()))!;
      expect(notes, hasLength(1), reason: 'the images made the note');
      final images = await storedImages(tester);
      expect([for (final i in images) (i.noteId, i.width, i.height)], [
        (notes.single.id, 1200, 800),
        (notes.single.id, 1200, 800),
      ]);
      for (final image in images) {
        final file = ImageStore.fileIn(folder, image.id, image.mimeType);
        expect(await tester.runAsync(file.exists), isTrue);
      }
      expect(find.byType(NoteImageGrid), findsOneWidget);
      expect(find.byType(NoteImageView), findsNWidgets(2));

      // Taken out, and put back.
      await tester.tap(find.byKey(ValueKey('remove-image-${images.first.id}')));
      await _settle(tester);
      expect(find.byType(NoteImageView), findsOneWidget);
      await tester.runAsync(() => app.read(undoProvider.notifier).undo());
      await _settle(tester);
      expect(find.byType(NoteImageView), findsNWidgets(2));
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('images kept from the quick field become a note with what was typed', (tester) async {
    await start(tester);
    try {
      app.read(destinationProvider.notifier).go(const NotesDestination());
      await _settle(tester);
      await tester.enterText(
        find.descendant(of: find.byType(QuickNoteField), matching: find.byType(TextField)),
        'Whiteboard from the lecture',
      );
      await _settle(tester);
      device.next = [picture(5)];
      await tester.tap(
        find.descendant(of: find.byType(QuickNoteField), matching: find.byKey(const ValueKey('quick-note-images'))),
      );
      await _settle(tester);

      final note = (await tester.runAsync(() => db.select(db.notes).get()))!.single;
      expect(note.title, 'Whiteboard from the lecture');
      expect((await storedImages(tester)).single.noteId, note.id);
      // The card leads with its image.
      expect(
        find.descendant(of: find.byType(NoteCard), matching: find.byType(NoteImageView)),
        findsOneWidget,
      );
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('nothing chosen adds nothing', (tester) async {
    await start(tester);
    try {
      app.read(openNoteProvider.notifier).create();
      await _settle(tester);
      device.next = const [];
      await tester.tap(find.byKey(const ValueKey('note-add-images')));
      await _settle(tester);
      expect(await tester.runAsync(() => db.select(db.notes).get()), isEmpty);
    } finally {
      await finish(tester);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}

/// Lets queries, streams and animations finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _Held extends SyncController {
  _Held(this._state);

  final SyncState _state;

  @override
  SyncState build() => _state;
}
