# Glasswork

Personal task app. Local-first, cloud-synced. Linux + Android for v1 (web is post-v1, do not add it).

The app name lives in `lib/app_config.dart` and nowhere else. Nothing else depends on it.

---

## Non-negotiables

**Local-first is absolute.** No UI path awaits a network call. Every write hits Drift, renders
immediately, then queues in the outbox. If a repository method can throw on network failure, it's
wrong.

**Two surface primitives only** — `AppSurface` and `VibrancyMaterial`. No ad-hoc `BackdropFilter`
anywhere else in the tree. See Materials below.

**All colours, spacing, radii and control heights come from `lib/theme/tokens.dart`.** No literal
hex, no magic padding numbers, no bare pixel heights in widget files. Controls that sit side by side
in a toolbar take an explicit height from `AppSize` — padding plus line-height is not enough to align
a text field against a button, because each computes its height from a different font size and they
land a pixel or two apart.

**Ordering is always a fractional index string.** Never an int column, never a reindex loop. Sort by
`(order_key, client_id)` — the client_id tiebreak is required, because two offline clients inserting
between the same neighbours generate the identical key.

**Never hard-delete a synced row.** Set `deleted_at`.

**Every destructive action is undoable for 5 seconds.**

**Smart views are saved queries.** Adding a view must not require a new table or a new screen class.

**No LLM API key ships in the client, ever.** Model calls go through the `triage` edge function.

**Schema changes are migration files** applied by the Supabase CLI. Nothing is changed in the
dashboard. RLS is enabled on every table in the same migration that creates it.

---

## Materials and surfaces

The design language is **Apple's, dark**. The palette in `theme/tokens.dart` is Apple's real
dark-mode system palette, not an approximation of it — people have seen `#0A84FF` ten thousand
times, and an *almost* right version of it reads as wrong in a way nobody can name.

Depth comes from **layered greys**, not shadow. `base` → `surface` → `elevated`; a lighter
surface reads as nearer. Shadow barely registers on a dark ground and mostly looks like grime.

Two primitives, and reach for the first one:

- `AppSurface` — an opaque card. The default. Almost everything is this.
- `VibrancyMaterial` — blurred translucency, as macOS does a sidebar or a sheet. **The only
  `BackdropFilter` in the app.** Each one forces the compositor to capture and blur what is
  behind it, so it is reserved for surfaces that genuinely float above scrolling content. A
  card in a grid is not one of those.

Rows are never vibrancy. A list has dozens of them; hover fill gives the depth instead.

### What replaced the glass shader

An earlier version used a procedural mesh gradient with a refraction shader. It was retired
when the design moved to Apple's language: Apple's materials are a **blur of real content**,
not a refraction of a decorative gradient, and against a calm neutral ground there is nothing
worth refracting. The shader is in git history if it is ever wanted.

That change also retired the "two radii only" rule. Apple uses a considered radius scale
instead, and matching it matters more than the simpler constraint — see `AppRadius`. The
discipline is that those are the only values and each has a fixed job.

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

**Never let a model compute a number the ledger can compute.** The LLM reads the arithmetic's output
and talks about it. It does not decide what is feasible.

---

## Dates

All-day tasks store a `due_date` (date), **not** a timestamp. A timestamp for an all-day task breaks
"due today" the moment the server is UTC or you travel. Timed tasks use `due_at timestamptz`.

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
Windows. Attachments. Light mode (the palette is structured for it, but it is not built).
