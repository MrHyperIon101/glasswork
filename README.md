# Glasswork

[![Checks](https://github.com/MrHyperIon101/glasswork/actions/workflows/checks.yml/badge.svg)](https://github.com/MrHyperIon101/glasswork/actions/workflows/checks.yml)

A task app that plans against the hours you actually have, rather than the ones you wish you
had. Local-first, cloud-synced, Linux and Android.

![The home screen](docs/screenshots/today.png)

## Why it exists

Every task app I tried would happily accept "finish the report by Friday" without ever asking
whether Friday had room in it. They keep a list of promises and leave the arithmetic to you —
which means the arithmetic arrives the night before three things are due at once.

Glasswork does the arithmetic. It knows when I sleep, what my week already has in it and how
long my work takes, so it can say what is genuinely left while a task is being added, not
afterwards. Everything else in the app exists so that answer is always to hand: the same work on
the laptop and the phone, and every screen fully usable with no signal at all.

I use it every day, which is the only reason it has as few rough edges as it does.

## What it does

- **Today** — one screen: what is due, where the day stands right now, this week's load, the
  next reminder, and somewhere to put a note. Every figure traces back to a tested function.
- **Time budget** — sleep, classes and fixed blocks taken out of the day, then meals and a
  buffer, and what is left multiplied by a focus factor *per gap*, because six free hours in one
  block is not six hours in twenty-minute slivers. Tasks are then allocated from one shared pool
  in deadline order, so two of them can never both claim the same Wednesday.
- **Tasks with a time** — give a task a time and it lands on the time budget for that day,
  counts in its figures, and sits beside your classes. One field, nothing to keep in step.
- **Timetables** — a set of blocks per semester, with dates, so a horizon that crosses a
  changeover gets the right classes on each side of it.
- **Projects and areas** — boards with sections, custom fields, saved views and labels; projects
  grouped into areas you name, each with an icon or emoji of your choosing.
- **Notes** — quick notes with images, kept with the rest of your work.
- **Reminders** — exact alarms on Android; on Linux the app raises them while it is open and
  writes a systemd timer for while it is closed.
- **Sync** — optional, through a Supabase project of your own. Every write hits the device first
  and reconciles later, so nothing ever waits on a network.
- **Undo** — anything destructive can be taken back for five seconds.

<p align="center">
  <img src="docs/screenshots/time-budget.png" width="49%" alt="The time budget">
  <img src="docs/screenshots/notes.png" width="49%" alt="Notes">
</p>

## Under the hood

The parts I would point at first.

**Two clocks, never conflated.** `updated_at` is the server's, and it does exactly one job: it
is a pull cursor. Conflicts are ordered by a hybrid logical clock the client stamps per field.
Order them by server time instead and they resolve *backwards* — a stale offline edit that syncs
on Wednesday beats the fresher edit that synced on Tuesday. Writes go through a single
`merge_rows` RPC that merges field by field, and devices hold no write grant on any table at
all. The outbox carries changed fields, never row snapshots, because a full-row write clobbers
fields the device never touched. Delta pull reads from `cursor - 60s`, since `now()` is
transaction-*start* time and a long transaction can commit behind a cursor you have already
passed; the merge is idempotent, so the overlap is free.

**The capacity engine is a pure function.** `(tasks, commitments, profile, today) -> Schedule`:
no I/O, no clock of its own, every number golden-tested. It is one forward pass in deadline
order over a shared pool (Jackson's rule), not a per-task backward walk — a backward walk
double-counts the moment two tasks want the same Wednesday. Sleep is a floor and not a resource:
no code path may schedule into it or offer it as a fix. When the only way to fit everything is
to eat sleep, the app says so and asks what comes off the list instead.

**Local-first is absolute.** No UI path awaits a network call. Every write hits SQLite, renders
immediately, and queues in an outbox; other devices hear about it over realtime, with an
interval pull as the safety net. Nothing synced is ever hard-deleted. Ordering is a fractional
index string with a client-id tiebreak, because two offline devices inserting between the same
neighbours generate the identical key. Rows that can exist only once take a derived id, so both
devices create the same row offline and the merge folds them into one.

**The architecture is held up by tests, not by discipline.** `test/sync/write_path_test.dart`
reads the source and fails if a repository writes a synced table outside `SyncWriter` — the bug
it prevents is an edit that works on this device and silently never reaches another, which no
behavioural test would catch. The layout harness renders every screen and sheet at four sizes
with realistic data and fails on an overflow, or on text squeezed into a column of single
letters; it also writes the screenshots in this file. Another test reads the Linux runner to
check the tray is built before the Flutter view, because a realised `FlView` answers the close
request first — an edit that reordered them would quietly turn "keep in the tray" back into
"quit".

**The native side is mine too.** The Linux runner is a single-instance GTK application in C,
with a tray that `dlopen`s AppIndicator rather than linking it, so the app still starts on a
desktop that has none. It ships as one file: a small GTK installer program with the app appended
as a tarball, which unpacks beside an existing installation and swaps the two with renames, so a
failed update leaves the working app exactly where it was — and the same file uninstalls, from
the app grid entry's own menu. Images are turned upright, downscaled and encoded in platform
code, on both platforms, before Dart sees a byte of them.

**Apple's dark palette, used honestly.** The real system colours rather than an approximation of
them, depth from layered greys instead of shadow, two surface primitives and exactly one
`BackdropFilter` in the whole tree, and every colour, space, radius and control height out of a
single tokens file.

`docs/architecture.md` is the long version, including the rules I hold myself to.

## Install

**Linux** — download `Glasswork-Setup-<version>-x86_64` from
[Releases](../../releases), make it executable and open it:

```bash
chmod +x Glasswork-Setup-*-x86_64 && ./Glasswork-Setup-*-x86_64
```

It installs into `~/.local/opt/dev.mrhyperion.glasswork` with an app grid entry, or updates
what is already there. Nothing needs root, and your data is never touched. The same file
uninstalls it from the app entry's menu.

**Android** — download the `arm64-v8a` APK from the same release and open it. It is signed
with a debug key, so Android will ask you to allow installing from an unknown source.

The binaries on the releases page are built without any server configuration, so they keep
everything on the device and nothing of yours goes anywhere. Sync needs a Supabase project
of your own — see below.

## Building it yourself

You need Flutter 3.47 or newer, and on Linux the GTK 3 development files
(`gtk3` on Arch, `libgtk-3-dev` on Debian).

```bash
flutter pub get
flutter run -d linux            # or: flutter run -d <your phone>
```

To package the Linux installer, which builds the release app first:

```bash
linux/packaging/build_installer.sh
# → build/linux/installer/Glasswork-Setup-<version>-x86_64
```

It picks up `backend.json` if you have one; `GLASSWORK_NO_BACKEND=1` leaves it out, which is
how the released file is built.

For the phone:

```bash
flutter build apk --release --split-per-abi \
  --android-project-arg=force-version-code-ignoring-abi=true
```

Bump the version in `pubspec.yaml` **and** `AppConfig.version` for every release — a test
holds the two together, and the installer uses it to tell an update from a reinstall.

## Syncing with your own Supabase project

Skip this and the app still works; it simply keeps everything on the one device.

1. Create a project on Supabase. The free plan is enough.
2. Apply the schema, which creates every table, its row level security, the realtime
   publication and the private bucket that note images live in:

   ```bash
   supabase link --project-ref <your project ref>
   supabase db push
   ```

3. Point the app at it:

   ```bash
   cp backend.example.json backend.json     # then fill in your URL and publishable key
   ```

   `backend.json` is ignored by git, and the build scripts pick it up. For a one-off run:
   `flutter run -d linux --dart-define-from-file=backend.json`.

4. Check the server agrees with the app:

   ```bash
   supabase db query --linked -f supabase/checks/sync_schema_checks.sql
   ```

   A good run ends with `ALL SYNC SCHEMA CHECKS PASSED`.

Sign in on each device with the same email and password. The first device claims the account;
the second is asked whether to combine its work with what is already there or take the
account's instead.

## Tests

```bash
flutter analyze
flutter test
```

807 of them, and they are where the design is enforced rather than merely described: the
capacity arithmetic against golden schedules, the sync merge across two simulated devices and a
fake server, the repositories, every pure text and layout function, and the harness above. The
server has its own — `supabase/checks/sync_schema_checks.sql` asserts the tables, policies and
grants against a real Postgres, in a transaction that always rolls back.

## Where it stops

Linux and Android. No web, no iOS, no Windows, no teams or sharing — the schema allows other
people, the app does not ship it. Images are the only attachment. Light mode is not built,
though the palette is structured for it.

The list is short on purpose. I would rather five things worked properly than fifteen nearly
did.

## Licence

[MIT](LICENSE). Take anything in here that is useful to you.
