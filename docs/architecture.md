# Glasswork

Personal task app. Local-first, cloud-synced. Linux + Android for v1 (web is post-v1, do not add it).

The app name lives in `lib/app_config.dart` and nowhere else. Nothing else depends on it.

---

## Non-negotiables

**Local-first is absolute.** No UI path awaits a network call. Every write hits Drift, renders
immediately, then queues in the outbox. If a repository method can throw on network failure, it's
wrong.

**One `GlassSurface` widget.** No ad-hoc `BackdropFilter` anywhere else in the tree.

**Two radii: `20` and `999`.** Surfaces get 20, controls get 999. Nothing in between, no exceptions.

**All colours and spacing come from `lib/theme/tokens.dart`.** No literal hex, no magic padding
numbers in widget files.

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

## Glass

Both v1 targets run Impeller, so `ui.ImageFilter.shader` (live backdrop sampling) *is* available —
verified at runtime via `ui.ImageFilter.isShaderFilterSupported`. We still don't use it as the primary
path, for cost rather than compatibility: every one of those costs a backdrop capture.

Instead the backdrop is a **procedural mesh gradient**, and the glass shader evaluates that same
gradient function at the refracted UV rather than sampling a captured texture. Measured at raster p50
0.6ms for four surfaces at 1920x1116 — about 4% of a 60fps budget.

The rule that follows:

> **Glass on the backdrop uses the cheap procedural path. Glass over content uses the capture path,
> and there should be very few of those on screen at once.**

Hence two modes, and they are not interchangeable:

- `GlassSurface.onBackdrop` — procedural refraction. The common case: cards, panels, sidebar.
- `GlassSurface.overContent` — real `BackdropFilter` blur plus the same edge treatment. Only for
  sheets and modals that genuinely overlap a list.

`GlassQuality.{full, blurOnly, flat}` degrades gracefully. `flat` is a tinted solid and **must still
look deliberate** — it is a supported appearance, not a broken one.

Cap at ~4 simultaneous glass surfaces on screen.

---

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

- The write path is an **RPC** (`merge_task(payload jsonb)`) that merges field-by-field. Not a
  PostgREST upsert.
- The outbox stores **changed fields, not row snapshots**. A full-row write clobbers fields the
  device never touched.
- Delta pull reads from `cursor - 60s`, because `now()` is transaction-*start* time and a long
  transaction can commit with a timestamp behind a cursor you've already passed. The HLC merge is
  idempotent, so the overlap is free.

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
- Nothing is called done on a claim. Every gate is a command run or a screenshot taken.

---

## Out of scope for v1

Web target. Teams and multi-user sharing (the schema allows it; the UI does not ship it). iOS, macOS,
Windows. Attachments. Light mode.
