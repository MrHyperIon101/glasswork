# How Glasswork is built

The decisions behind the app, and the rules I hold it to. Read this before changing anything
in `lib/sync` or `lib/capacity`.

Personal task app. Local-first, cloud-synced. Linux + Android for v1 (web is post-v1, do not add it).

The app name lives in `lib/app_config.dart`. The platform files that have to spell it out for
themselves — the Android launcher label, the Linux window title and app grid entry — are held to it
by `test/app_identity_test.dart`.

The app icon is generated. `tool/app_icon.py` cuts a disc from `assets/branding/app_icon_source.png`
and writes every platform's PNGs; change the source and rerun it, never edit the outputs.

**Linux ships as one installer file.** `linux/packaging/build_installer.sh` builds the release app and
writes `build/linux/installer/Glasswork-Setup-<version>-<arch>`: a small GTK program
(`linux/installer/installer.c`) with the app appended as a tarball. Opened, it installs into
`~/.local/opt/dev.mrhyperion.glasswork` with an app grid entry and icons, or updates what is there:
it unpacks beside the installed app and swaps the two with renames, so a failed update leaves the
old app working. It closes a running app first and opens it again after. The app's data is never
touched, and a copy of the program kept as `uninstall` removes the app from the entry's menu.
`linux/packaging/install.sh` runs the same installer without a window. **Bump the version in
`pubspec.yaml` and `AppConfig.version` for every release** (a test holds the two together): it is
what tells an update from a reinstall, and Android refuses a build whose number went down.

---

## Non-negotiables

**Local-first is absolute.** No UI path awaits a network call. Every write hits Drift, renders
immediately, then queues in the outbox. If a repository method can throw on network failure, it's
wrong.

**One surface, `GlassSurface`.** `AppSurface` (a card) and `VibrancyMaterial` (a sidebar or a sheet)
draw through it, and it is the only `BackdropFilter` in the tree. No ad-hoc blur or filter anywhere
else. See Materials below.

**All colours, spacing, radii and control heights come from `lib/theme/tokens.dart`.** No literal
hex, no magic padding numbers, no bare pixel heights in widget files. Controls that sit side by side
in a toolbar take an explicit height from `AppSize` — padding plus line-height is not enough to align
a text field against a button, because each computes its height from a different font size and they
land a pixel or two apart.

**Ordering is always a fractional index string.** Never an int column, never a reindex loop. Sort by
`(order_key, client_id)` — the client_id tiebreak is required, because two offline clients inserting
between the same neighbours generate the identical key.

**That order only means anything inside one section.** Order keys from different sections are not
comparable, so anything that collects tasks from several — a smart view, a search, a project's
completed work — orders them itself, newest added first, through `TaskOrder` (`lib/data/task_order.dart`).
`created_at` is kept to the second, which a pasted list of tasks all share, so the order key breaks
that tie (within a section it is the order they were appended in) and the id breaks the last one: the
comparison is total, and every device lands on the same answer. A project view can ask for another
order — added, due, priority — and a saved view keeps it.

**Never hard-delete a synced row.** Set `deleted_at`.

**Every destructive action is undoable for 5 seconds.**

**Smart views are saved queries.** Adding a view must not require a new table or a new screen class.

**No LLM API key ships in the client, ever.** Model calls go through the `triage` edge function.

**Schema changes are migration files** applied by the Supabase CLI. Nothing is changed in the
dashboard. RLS is enabled on every table in the same migration that creates it.

---

## Materials and surfaces

The design language is **Apple's, dark, in liquid glass**. The palette in `theme/tokens.dart` is
Apple's real dark-mode system palette, not an approximation of it — people have seen `#0A84FF` ten
thousand times, and an *almost* right version of it reads as wrong in a way nobody can name.

Every screen is laid on the **ambient backdrop** (`lib/ui/glass/ambient_backdrop.dart`): a few large,
dim fields of Apple's hues on `AppColour.ground`, drifting slowly. Glass over a flat colour shows
nothing, so this is what gives every surface something to catch. It is painted, never captured, and
it steps at 15 a second on a `Timer` — a `Ticker` would ask for a frame on every vsync whether or not
anything moved, keeping the GPU awake for nothing. It stops while the window is in the background,
stands still under reduce-motion, and holds still under the solid look.

Surfaces are **`GlassSurface`** (`lib/ui/glass/glass_surface.dart`), in one of three looks, a
device-local preference (Settings → Appearance), Liquid by default:

- **Liquid** runs `shaders/liquid_glass.frag` as a backdrop filter: what is behind is pulled in from
  further inside along a band at the edge, the way a lens's rim bends it, with the three colours
  bending slightly apart there; its colour is lifted a little; the tint is laid over; the rim
  catches a light from the top left. Only Impeller runs shader filters, so `LiquidGlass.load()`
  happens before the first frame, and where it cannot run Liquid is drawn as Frosted, and says so.
- **Frosted** is the blur and the tint, and a drawn rim.
- **Solid** is an opaque card.

What the shader is given was found by measuring, not from the documentation, and both facts matter:

- Its coordinates are **the window's pixels**, not the surface's, and the backdrop it samples is the
  whole window. So each surface tells it where it is (`_RenderLiquid` sets its rect, radius and tint
  each time it paints, from its transform to the screen), and anything that can move a surface
  without repainting it — the scroll views it is in — makes it paint again, or the bend would be
  drawn where the surface used to be.
- The backdrop arrives **the right way up** on OpenGL ES. The documented flip for that backend
  mirrors it: the top of the window appears at the bottom of every surface.

All the glass on a screen shares **one capture**: `BackdropFilter.grouped` under the `BackdropGroup`
at the root. A sheet takes its own group, since surfaces that overlap must not share one. Cards have
**no blur**: all that lies behind a card is the backdrop, which is soft already, and a blur per card
was most of the cost while changing nothing visible. Surfaces that float over real content — sheets,
the drawer — blur it. Measured in profile mode at 1920×1048 on a 165 Hz monitor with every home card
glass: raster p50 3.4 ms, p95 5.0–5.7 ms against a 6.1 ms budget.

Rows are never glass. A list has dozens of them; hover fill gives the depth instead.

Every sheet is a `ModalSheet`, which gives it its own focus scope and moves keyboard focus into it
as it opens. Without that, the screen behind kept focus: a field's `autofocus` was refused, and Esc
went to the screen rather than the sheet.

### Motion

Everything that moves goes through `lib/ui/motion.dart` and the `AppMotion` tokens, and every
duration passes through `AppMotion.of(context, …)`, which is zero when the system asks for less
motion. Things arrive fast and land softly (`AppMotion.enter`) and leave faster than they came
(`AppMotion.exit`); nothing bounces.

- A sheet is shown with `SheetPresence`, never `if (open)`: it animates out as well as in, still
  showing what it showed while it leaves. The drawer does the same with `Presence`.
- Dialogs open with `showAppDialog`, not `showDialog`, so they move the way sheets do.
- Screens fade through (`ScreenSwitcher`): the old one is gone before the new one is legible.
- Anything pressable gives under a press (`Pressable`); counts count (`AnimatedCount`); short lists
  animate what arrives and leaves (`AnimatedItems`); a task's circle fills and draws its tick
  (`AnimatedCheck`).

### The two glass shaders

The first version refracted a procedural mesh gradient. It was retired when the design moved to
Apple's language, whose materials are a blur of real content rather than a refraction of a decorative
gradient; that version is in git history. Liquid glass came back in Apple's own form — a filter over
whatever really is behind — once there was a backdrop worth bending and a way to afford it on every
card. The radius scale stayed: Apple uses a considered one, and matching it matters more than a
simpler rule — see `AppRadius`. Those are the only values, and each has a fixed job.

### Building for Linux: Flutter 3.47.4 until 3.50.1

Flutter 3.50.0 draws every frame half a window out of place on NVIDIA's Linux drivers: they make the
engine composite without `glBlitFramebuffer`, and its fallback quad was offset by a whole extra
viewport (flutter/flutter#196083, cherry-picked for 3.50.1). Linux builds are made with 3.47.4 —
the version CI uses — from `~/.local/share/flutter-3.47.4`; `build_installer.sh` takes it as
`FLUTTER=…/bin/flutter` and refuses 3.50.0 outright.

## Sync (phase 4 — read this before writing any of it)

`updated_at` and field-conflict ordering are **two different clocks** and must not be conflated:

| purpose | column | assigned by |
|---|---|---|
| delta-pull cursor | `updated_at` | server trigger, `now()` |
| field conflict order | `field_versions` | **client**, hybrid logical clock |

A server timestamp assigned at merge time resolves conflicts backwards: a stale offline edit that
syncs late would beat a fresher edit that synced earlier. The HLC is `(wall_ms, counter, client_id)`,
advanced to `max(local, last_seen_remote) + 1`.

Consequences:

- The write path is an **RPC** (`merge_rows(changes jsonb)`) that merges field-by-field. Not a
  PostgREST upsert. Devices have no direct write grants; the migration in `supabase/migrations`
  is the reference.
- The outbox stores **changed fields, not row snapshots**. A full-row write clobbers fields the
  device never touched.
- Delta pull reads from `cursor - 60s`, because `now()` is transaction-*start* time and a long
  transaction can commit with a timestamp behind a cursor you've already passed. The HLC merge is
  idempotent, so the overlap is free.
- **Changes arrive as they happen.** Every synced table is in the `supabase_realtime` publication,
  and a signed-in device listens (`ChangeFeed`). Word of another device's change only prompts a
  pull; rows still come through `pull_rows`, so a lost message costs a round trip, never data.
  While listening, the interval pull is a five-minute safety net; without it, every 30 seconds.
  A pull asks for every table at once, and an edit goes out 0.8 seconds after typing pauses.

**Synced rows are written only through `SyncWriter`**, which stamps the clocks and queues the
outbox in the same transaction as the write. A repository that writes a synced table directly
makes an edit that works on this device and never reaches another — and no behavioural test
notices, so `test/sync/write_path_test.dart` reads the source for it.

**Nothing assumes a row is unique unless its primary key says so.** After sync, both devices'
offline creations exist. A row that can only exist once per key — a label on a task, a field's
value, a workspace's profile — takes a derived id from `NaturalId`, so both devices create the
same row and the merge folds them together. Every other "find the one" lookup orders by
`(created_at, id)` and takes the first, so it cannot throw and every device picks the same row.

**Sign-in is email and password, and the project's auth settings live in `supabase/config.toml`.**
The free plan refuses changes to email templates, and its built-in emails carry only links the app
cannot open, so no flow depends on an email: confirmation is off, and the password minimum is
`SyncAuth.minimumPasswordLength` (a test holds the app and the file together). Before any
`supabase config push`, pull the live config into a scratch copy and diff it against the repo.
`supabase config diff` has reported nothing while values differed, and a push without a terminal
proceeds on its own, writing every value the file declares over the live one.

---

## Capacity engine

**Pure Dart, offline, deterministic.** It never calls the network and never calls a model. Signature
is `(tasks, commitments, profile, today) -> Schedule` with no I/O, so it can be golden-tested.

**The algorithm is a forward pass, not a per-task backward walk.** Sort by deadline, allocate from one
shared capacity pool (Jackson's rule — minimises maximum lateness):

```
sort open estimated tasks by (due_at asc, priority desc)
cursor = today;  remaining = usable(cursor)
for each task:
    consume estimate_min from the pool, advancing cursor across days
    finish = last day touched
    if finish > due_date  ->  infeasible by (finish - due_date)
```

One pass yields feasibility *and* `latest_start`. A per-task backward walk double-counts — two tasks
each claim the same Wednesday.

**`focus_factor` is computed per gap, not as one global multiplier.** Six hours in one block is not
six hours in three gaps between classes. Discard gaps under ~25 minutes.

**`sleep_target_min` is a floor, not a resource.** No code path may schedule into it or offer it as a
fix. If the only way to fit everything is to eat sleep, report the deficit and ask what comes off the
list.

**Sleep is set per day:** when you get up, and when you go to bed that night (`wake_<day>_min`,
`bedtime_<day>_min`), a bedtime at or before getting up being after midnight. A date's waking hours
come from that day and the night before it, so the small hours after a late night count towards the
date they fall on. `BlockCheck` refuses a block that falls in sleep, past midnight, or on top of
another, and offers the nearest free time; blocks already there are flagged, never counted.
`sleep_target_min` only marks short nights. Two columns a day, not one list, so edits to different
days on different devices merge — and `setSleep` writes only the times that change. Time budget
lists sleep a night at a time, to bed on a day and up the next morning: rows of days, getting up
first, read as sleeping from morning until night. A night's "Up at" writes the next day's wake.

**The profile explains itself.** Each setting says what it is and what one step more would do to an
average day this week. Those figures come from `SettingEffects`, which reruns the ledger with the
setting moved rather than doing arithmetic of its own.

**A task can be given a time**, and that is how a task reaches the time budget: `tasks.start_at`, lasting
its estimate (an hour without one), so there is one field and nothing to keep in step with a block.
`TaskSlots` places it on its day; the scheduler takes its minutes from that day before the forward
pass places anything else (`PlannedTask.plannedDay`), a time already gone is placed like any other
task, and a task with a time and no deadline counts on its day and has no feasibility of its own.
The day's timeline draws it as a white pill, a colour no block wears; `DayAgenda` lists it and gives
it its part of the free time; `DayNow` is busy with it. Choosing a time checks it against that day's
blocks, sleep and other tasks (`SlotCheck`) and offers the next free time. Typed, it is
`plan fri 4pm`, read like a reminder.

**Never let a model compute a number the ledger can compute.** The LLM reads the arithmetic's output
and talks about it. It does not decide what is feasible.

---

## Dates

All-day tasks store a `due_date` (date), **not** a timestamp. A timestamp for an all-day task breaks
"due today" the moment the server is UTC or you travel. Timed tasks use `due_at timestamptz`.

---

## Reminders

A task's reminder is `tasks.remind_at` (UTC), synced like any field, so every device with the task
raises it. `ReminderPlan` (pure) picks the next `ReminderPlan.limit` of them; `ReminderService` hands
the plan to the platform only when it changes, once edits pause, and never throws.

A reminder is set wherever a task is made or edited: typed into the title (`remind tomorrow 9am`,
`remind in 2h`, `remind fri 6pm`, read by `QuickAddParser` before anything else so its time is not
taken for the due date), picked from presets that suit the task, or chosen in `ReminderDialog` as a
day and a typed time. Each says in words when it is and how long until it (`ReminderChoice.describe`),
so a reminder set for the wrong day is caught while setting it. "Add several at once" takes a pasted
list, one task a line, each line read the way a single title is.

- **Android:** exact alarms through `flutter_local_notifications` (`USE_EXACT_ALARM` on 13 and later),
  put back after a restart by the plugin's boot receiver. Notification permission is asked the first
  time a reminder is set, not at launch. The small icon, `res/drawable/ic_notification.xml`, is kept
  from resource shrinking by `res/raw/keep.xml`.
- **Linux:** while the app is open it raises reminders itself. For while it is closed it writes a
  systemd user timer, `dev.mrhyperion.glasswork-reminders.timer` (one `OnCalendar=` per reminder,
  `Persistent=true`), running a POSIX script that calls `notify-send`. The script stays quiet while
  the app is open — the app writes its pid to `XDG_RUNTIME_DIR` — and records what it showed, so
  nothing shows twice. `LinuxReminderFiles` holds every byte written, and its test runs the script.
- A reminder's buttons (Mark done, Snooze) open the app, which does the write. Handled in a
  background isolate instead, they would be a second writer to the database beside the app.

---

## Home, notes and the timetable's colours

- **Today** is a dashboard of cards that fills the window. Where there is height enough, the cards
  share it and a list longer than its card scrolls inside it, fading at the edge that has more;
  in a shorter window, or on a phone, the page scrolls instead. Its figures come from `TaskStats`
  (today, the week coming up, the last week's completions, the next reminder), `DayNow` (where the
  day stands against the ledger's blocks), `DayAgenda` (those blocks and the free time between
  them, which is the ledger's own gaps) and the schedule; its sentences come from `HomeText`. All
  are pure and tested. The layout harness renders it at 1920x1000, a maximised window on a 1080p
  screen, because a dashboard that stops short of the window only shows there.
- **Notes** are the synced `notes` table: a title and a body, pinned or not. `NoteText` says how one
  reads — its heading, a preview, when it was last written (the newest field clock, since the row
  keeps no edit time). A new note in the editor has no row until something is typed, so opening
  one and closing it leaves nothing behind. Deleting is a tombstone with undo, like tasks.
- **Images in notes** are the synced `note_images` table, a row an image, and the image's bytes: a
  file on each device that has them (`ImageStore`, in the app's data folder) and an object in the
  private `note-images` storage bucket, under the workspace's own folder, which only its members can
  read or add to. The platform makes each image ready before Dart sees it — upright, no longer than
  2048 pixels, a JPEG or a PNG with transparency — in `linux/runner/image_prep.cc` and
  `MainActivity.kt`, from the file chooser or clipboard and the photo picker. Adding one is
  local-first: the file and the row first, then `ImageSync` sends it after the rows have synced,
  and fetches other devices' images once their rows arrive, waiting a little for one whose bytes
  have not been sent yet. `ImageFiles`, local-only, says which files this device holds and which
  storage has. Deleting an image is a tombstone with undo; its bytes stay in storage, so an undo on
  any device still finds them.
- **A timetable block wears the same colour and short name everywhere** — the time budget's bars,
  its list of blocks, the home screen's strip. `BlockStyle.assign` gives every title in the
  timetables its own colour while there are colours enough, the same on every device; a phone's
  bar, too narrow for names, is named in a key beneath it.

---

## Projects and areas

- **Finished work is shown in one place, not moved there.** Ticking a task off writes nothing but
  its status: the row keeps the section it was filed under, and the views draw it under the project's
  completed column instead — `CompletedSection.of` (`lib/data/completed.dart`) picks that column by
  the `lists.is_done_column` flag, falling back to a section named for it, and the board adds a
  column of its own where a project has neither. So reopening a task puts it straight back where it
  came from with nothing remembered, and renaming or deleting a Done section loses no work. Dropping
  a card on that column ticks it off; dragging one out reopens it. Every way of completing a task
  goes through `setTaskDone` (`lib/ui/task_actions.dart`), which offers the same five seconds of undo
  as a deletion — ticking the wrong line is as easy as deleting it, and on a board it happens with a
  drag. Which projects show their completed work folded away is this device's own, kept in
  `LocalSettings` beside the closed areas.

- **A project's icon** is its `icon` text: `sym:` and a name for one of `ProjectIcon.symbols`, drawn
  in the project's colour, and anything else is an emoji or letters typed in, kept as the first two
  characters a person would count (`ProjectIcon.typed`). A symbol a device does not know draws as
  the empty circle, so a newer version's symbols never break an older one. `ProjectGlyph` draws
  both kinds at the same size wherever a project is named.
- **Areas** are the synced `areas` table: named groups of projects, and `boards.area_id` says which
  one a project is listed under. The sidebar lists projects in no area under Projects, then each
  area with its own (`ProjectGroups`); a project whose area is deleted, or has not arrived yet,
  lists under Projects rather than nowhere. Deleting an area is a tombstone with undo and writes
  nothing to its projects, so undoing puts them back. A project moves by being dragged onto an
  area (or onto Projects), or from its settings. Which areas are closed is this device's own, kept
  in `LocalSettings`.

---

## Spotlight

Glasswork can be searched from outside itself. The runner serves `dev.mrhyperion.glasswork.Spotlight`
at `/dev/mrhyperion/glasswork/Spotlight` on the app's own bus name (`linux/runner/spotlight_service.cc`):
`Query`, `Recents`, `Actions`, `PreviewAdd`, `AddTask`, `Activate` and `SetDesktopGlass`. Each call goes to Dart over the
`dev.mrhyperion.glasswork/spotlight` channel (`SpotlightChannel`) and is answered when Dart replies; the
phone's Spotlight asks the same `SpotlightService` directly.

- **What it finds** is ranked by `SpotlightIndex` (`lib/search/spotlight_index.dart`, pure and total):
  the whole title, then a title starting with the query, then a word in it, then every word of the query
  starting a word, then the query anywhere, then its letters in order; finished work below what is
  still to do, and what was opened lately nudged up — never past a better kind of match.
- **Recents** are the last 20 tasks, notes and projects opened on this device (`lib/data/recents.dart`,
  in `LocalSettings`), recorded where the task sheet, the note editor and a project open.
- **Adding from it** goes through `addTaskFromLine` (`lib/state/quick_add.dart`), the one way a typed
  line becomes a task, shared with the composer's list of several.
- **Waking it.** The installer writes `~/.local/share/dbus-1/services/dev.mrhyperion.glasswork.service`,
  so a call to the bus name when Glasswork is not running starts it with `--background`: it serves the
  call and keeps its window hidden. The interface is exported from `dbus_register`, before the app owns
  its name, and calls that arrive before Dart can answer wait in the runner until Dart says `ready`, up
  to eight seconds. The tray's "a hidden window comes back when the tray is turned off" only means a
  window closed into the tray (`in_tray`), not one that was never shown.

Two things about Riverpod 3 this rests on, both found the hard way:

- **A provider nothing listens to is paused**, and so is everything it listens to. The shell holds a
  subscription to `spotlightServiceProvider` (`listenManual`, not `read`), and the service keeps its
  data providers listened for as long as it exists. Read alone, Recents answered with what it held
  before the last task was opened.
- **A stream provider's `.future` answers with the first value it ever had** until the provider
  rebuilds. The service reads each provider's current value instead (`_load`), waiting only when there
  is none yet.

### Glasswork Spotlight, the GNOME Shell extension

`linux/gnome-extension/spotlight@glasswork.mrhyperion.dev` is Spotlight for the whole desktop, on
Super+Space, laid out and moving as macOS Tahoe's does. Only the shell can blur what is behind a
surface on Wayland, so it is an extension rather than a window of the app's.

- **The bar** is a capsule a little under a quarter of the way down the monitor in use. Once the
  pointer moves over an empty bar, four round buttons — Applications, Files, Actions, Clipboard —
  bud out of its rounded end and draw back in when typing starts. They share the bar's width, as
  in Tahoe: the bar draws its end in to make room as they come out, and stretches back as they
  go, so the whole of it — bar, buttons and results — stays one width, centred. Ctrl+1 to Ctrl+4 (or Super) choose
  them from the keyboard, as Command+1 to 4 do on a Mac, and so do slash filters: `/apps`, `/pdf`,
  `/images`, `kind:folders`, taken out of the line once their word is finished (`lib/modes.js`).
- **What it finds** comes from every source at once, each answering as it can: apps through GNOME's
  own `AppSearchProvider`, files from LocalSearch (`gi://Tsparql`), every installed search provider
  except Files' (files are not listed twice), actions, the web, and Glasswork over D-Bus. Each scores
  its results on the same scale as `SpotlightIndex` (`lib/ranking.js`), so the best of all of them
  is the top hit and Glasswork's sit among the rest at their true rank. Under the bar, the kinds
  found are chips to narrow by; Tab steps through them.
- **The browse modes**: Applications is every app in a grid (or a list), in Tahoe's categories read
  from each desktop file (`lib/app_categories.js`), Ctrl+Left and Right between them. Files is the
  files opened lately — GNOME's own recent list — and Glasswork's recents, by kind. Actions is every
  action: Glasswork's (from `Actions` over D-Bus, named in title case as on a Mac); the system's
  under Tahoe's names — Lock Screen, Take a Screenshot, Record the Screen, Sleep, Switch User,
  Log Out, Restart, Shut Down — each only where GNOME offers it, the ones that end the session
  asking first as GNOME's own do; the desktop's controls, each named for what it will do from
  where things are (Turn Off Wi-Fi, Turn On Bluetooth, Airplane Mode, Night Light, Dark Style,
  Do Not Disturb); and Spotlight's. Each answers to the words people use for it, and every word
  of a query found among them, in any order, is a match: "turn off pc" is Shut Down
  (`SYSTEM_ACTIONS` and `matchAction` in `lib/quick_keys.js`). Some have a quick key: `nt` makes
  New Task the top hit. An action with fields is
  filled in in the bar — New task asks what, then optionally when, Tab between them, the line read
  as the composer reads one and previewed by `PreviewAdd` as it is typed. Clipboard is what was
  copied: text, links, images and files.
- **The clipboard history** is held in memory only, never written down, and forgotten on logging
  out; it keeps 30 minutes, 8 hours (the default) or 7 days of it, and nothing a password manager
  marks as secret (`x-kde-passwordManagerHint`). It can be turned off, which clears it.
- **Up**, before anything else is chosen, brings back earlier searches, as in macOS — the only thing
  it keeps between sessions, in `~/.local/state/glasswork-spotlight/history.json`, readable by the
  user alone. Esc steps back one thing at a time: the text, the action, the mode, then Spotlight.
  Holding Alt shows the selected file's path; Alt+Return shows it in Files.

The glass (`lib/ui/glass.js`) is a clone of the window group, blurred as the surface's own content,
then cut to its shapes by a shader that bends the blur along a band inside each edge, splits its
colours slightly there, lights the rim from the top left and lays a shadow under it. A blur in
background mode cannot be rounded, which is why it is not that. The bar and its buttons are **one
glass**: their distances are joined with a smooth minimum, so a button leaving the bar draws out of
it like a drop and parts from it only once it is clear — Liquid Glass's own behaviour.

It moves on springs (`lib/spring.js`, Apple's response-and-damping form, tested for overshoot):
opening grows from 94% with under 2% overshoot, the buttons bud out on a looser one, 35 ms apart,
and the results spring to the height of what is in them; rows fade in as they arrive and the
highlight slides between them. Closing is faster and has no spring. All of it stops when GNOME is
asked for less motion.

Found the hard way, and each guarded by a test or by a comment where it is done:

- **The field moves its cursor on Left and Right before it emits a key press**, so a handler on its
  key presses never sees the grid's arrows. Keys are read in Spotlight's own capture phase instead.
- **An input method takes each key and sends it back** marked `FLAG_INPUT_METHOD`, later. With one
  running, that returned copy is the one read, or a Tab typed straight after a word is read before
  the word's last letters arrive.
- **A viewport lays its content out at its least width**, and an ellipsizing label's is a few pixels:
  the chips' labels never ellipsize, and the row scrolls with its ends faded instead.
- **A row's allocation notifies before the scroll view updates its page size**, so scrolling a row
  into view measures the scroll view itself.

It also makes Glasswork's window glass: `lib/window_glass.js` puts a blur of the desktop under the
window and calls `SetDesktopGlass`, and the app turns its own ground see-through over it (an RGBA
visual in the runner, `desktopGlassProvider` in Dart), frosted rather than clear. Without the
extension the app draws its own backdrop as before.

**Testing it.** The pure parts are tested with `gjs -m linux/gnome-extension/tests/run.js`, in CI
too, with the schema compiled strictly. The rest is checked in a throwaway headless GNOME Shell:
`tool/nested_session/run.sh` with `NESTED_EXTENSION=1` loads it with its own home, settings and bus,
and the harness extension there presses keys, holds them, moves the pointer and copies text over
D-Bus (`dev.glasswork.Harness`), while `Describe` reads back what Spotlight shows. Hot corners are off
in that session: the virtual pointer starts in one. Nothing of the real session is touched.

**Installing it.** The installer puts it in `~/.local/share/gnome-shell/extensions`, its schema
compiled, adds it to `org.gnome.shell enabled-extensions` beside whatever is there, and takes both
away again on uninstall — only where GNOME Shell is. GNOME on Wayland loads an extension, new or
updated, only as a session starts, so the installer says to log out once. It takes Super+Space,
which GNOME otherwise gives to switching keyboard layouts; the shortcut is in its settings.

## Desktop: the window and the tray

**The window has no title bar.** A strip in the desktop's theme sitting on top of a window drawn in
Apple's is exactly the seam the rest of the app avoids, so `my_application.cc` gives the window an
empty title bar instead of a header bar — empty rather than undecorated, because that still asks GTK
for client-side decorations and keeps the shadow, the resize edges and the desktop's snapping. Minimise,
maximise and close are drawn in the app (`WindowControls`, one capsule at the top-right of every
header, the same pill Voxtrona draws), the title and the space beside it are the handle the window is
dragged by (`WindowDrag`), and a double click there maximises it. All of it goes over the same
desktop channel; closing this way is `gtk_window_close`, so "Keep in the tray" still decides what
closing means. The window's title is still set — it is what the switcher and the taskbar read — and
`test/desktop/runner_order_test.dart` reads the runner to keep a header bar from coming back with a
template update.

The Linux runner is a single-instance GTK application, so launching Glasswork again brings its one
window forward instead of starting a second copy beside it. `linux/runner/desktop_shell.cc` holds
the tray: with "Keep in the tray" on (a `Preferences` value), closing the window hides it, and an
AppIndicator icon offers Open, New task, New note and Quit. AppIndicator is loaded with `dlopen`,
not linked, so the app still starts on a desktop without it; Settings then says there is no tray.
Dart talks to it over the `dev.mrhyperion.glasswork/desktop` channel (`DesktopShell`).

The shell is made before the window has its Flutter view. A realised `FlView` stops a close
request at its own `delete-event` handler and asks Dart to exit, so a handler connected after it
never runs and closing the window quits whatever the setting says. `test/desktop/runner_order_test.dart`
reads the runner for that order.

---

## Settings

`SettingsScreen` (the foot of the sidebar, or Ctrl+,) holds everything that can be set. As on the
profile, each setting says what it is and what it does in the person's own figures ("Tomorrow you
get up at 07:00, so a morning reminder comes 2h after that"), and those sentences come from
`SettingsText`, which is pure and tested.

- **Choices about the app on this device** — when a morning and an evening reminder are, how long
  Snooze waits, which project a task added outside one goes to — are `Preferences`, kept in
  `LocalSettings` by `PreferencesRepository` and never synced.
- **Settings that shape the work** — sleep, meals, buffer, focus — sync in the capacity profile and
  are changed on Time budget, beside the figures they change. Settings sums them up and links there;
  it does not keep a second copy.
- A setting goes in only once everything it names follows it. The morning reaches the presets, the
  reminder dialog and a typed `remind fri`; Snooze reaches the snooze and the words on its button,
  on both platforms.

---

## Definition of done

- `flutter analyze` clean.
- Capacity engine changes have golden tests. The linter is not the gate there — the numbers are the
  entire value of the feature, and untested arithmetic is a confident liar.
- Runs on Linux **and** a physical Android device. The emulator lies about fill rate; don't accept it
  as evidence for anything performance-related.
- Numbers shown in the UI come from a tested pure function, never from arithmetic inline in a
  widget. A dashboard figure nobody can trace is worse than no figure.
- Nothing is called done on a claim. Every gate is a command run or a screenshot taken.
- Server schema changes pass `supabase/checks/sync_schema_checks.sql` against the linked project
  (`supabase db query --linked -f ...` ends with "ALL SYNC SCHEMA CHECKS PASSED"), and
  `supabase db advisors --linked` shows nothing new. The one expected warning is signed-in users
  being able to call `merge_rows`, a security definer function: that is the design.

---

## Out of scope for v1

Web target. Teams and multi-user sharing (the schema allows it; the UI does not ship it). iOS, macOS,
Windows. Attachments other than images in notes. Light mode (the palette is structured for it, but it
is not built).
