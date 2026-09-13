-- Glasswork's sync schema. Applied with the Supabase CLI, never edited in the dashboard.
--
-- Mirrors the local Drift schema (lib/data/db/tables.dart) table for table and column for
-- column. test/sync/server_schema_test.dart fails if the two drift apart.
--
-- Two clocks, never conflated (docs/architecture.md, Sync):
--   updated_at      the pull cursor, stamped here with now() on every write;
--   field_versions  per-field hybrid logical clocks, stamped by devices, which decide
--                   every conflict.
--
-- Devices never write these tables directly. They have no insert, update or delete
-- grants, and every change arrives through public.merge_rows, which merges field by field
-- exactly as lib/sync/field_merge.dart does.

create schema if not exists private;

-- --- tables ------------------------------------------------------------------------------

create table public.workspaces (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  name text not null
);

-- Who may read and write a workspace. Not synced: it is created by merge_rows, never by a
-- device, which is what stops one account writing into another's workspace.
create table public.workspace_members (
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

-- Foreign keys are deferred so a batch can arrive in any order within one call.

create table public.boards (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  name text not null,
  purpose text,
  icon text,
  colour bigint,
  archived boolean not null default false,
  view_default text not null default 'list',
  order_key text not null
);

create table public.lists (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  board_id uuid not null references public.boards (id) deferrable initially deferred,
  name text not null,
  order_key text not null,
  wip_limit integer,
  is_done_column boolean not null default false
);

create table public.tasks (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  list_id uuid not null references public.lists (id) deferrable initially deferred,
  title text not null,
  notes_md text,
  order_key text not null,
  status text not null default 'open',
  priority integer not null default 0,
  due_at timestamptz,
  due_date date,
  start_at timestamptz,
  completed_at timestamptz,
  rrule text,
  parent_task_id uuid,
  estimate_min integer,
  actual_min integer,
  scheduled_for date,
  slip_count integer not null default 0,
  last_deferred_at timestamptz
);

create table public.subtasks (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  task_id uuid not null references public.tasks (id) deferrable initially deferred,
  title text not null,
  done boolean not null default false,
  order_key text not null
);

create table public.labels (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  name text not null,
  colour bigint
);

create table public.task_labels (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  task_id uuid not null references public.tasks (id) deferrable initially deferred,
  label_id uuid not null references public.labels (id) deferrable initially deferred
);

create table public.notes (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  title text not null,
  body_md text not null default '',
  pinned boolean not null default false
);

create table public.capacity_profiles (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  sleep_target_min integer not null default 450,
  sleep_start_min integer not null default 1410,
  meals_min integer not null default 90,
  buffer_min integer not null default 60,
  focus_factor double precision not null default 0.65,
  min_gap_min integer not null default 25
);

create table public.schedules (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  name text not null,
  starts_on date,
  ends_on date,
  is_fallback boolean not null default false,
  order_key text not null
);

create table public.commitments (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  schedule_id uuid,
  title text not null,
  rrule text not null,
  start_min integer not null,
  duration_min integer not null,
  location text,
  kind text not null default 'classes'
);

create table public.field_defs (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  board_id uuid not null references public.boards (id) deferrable initially deferred,
  name text not null,
  type text not null,
  options_json text not null default '[]',
  order_key text not null,
  show_inline boolean not null default true
);

create table public.field_values (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  task_id uuid not null references public.tasks (id) deferrable initially deferred,
  field_id uuid not null references public.field_defs (id) deferrable initially deferred,
  value text
);

create table public.project_views (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  board_id uuid not null references public.boards (id) deferrable initially deferred,
  name text not null,
  kind text not null,
  filter_json text not null default '{}',
  group_by text,
  order_key text not null
);

-- --- helpers -----------------------------------------------------------------------------
-- In the private schema, which the API does not expose, so none of these can be called
-- directly by a device.

-- Every synced table, parents before children. The same list, in the same order, as
-- lib/sync/synced_tables.dart; the schema test compares them.
create function private.synced_tables()
returns text[]
language sql
immutable
set search_path = ''
as $$
  select array[
    'workspaces',
    'boards',
    'lists',
    'tasks',
    'subtasks',
    'labels',
    'task_labels',
    'notes',
    'capacity_profiles',
    'schedules',
    'commitments',
    'field_defs',
    'field_values',
    'project_views'
  ]
$$;

-- The caller's workspaces. Security definer so a policy can read memberships without
-- recursing through workspace_members' own policy.
create function private.my_workspace_ids()
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select workspace_id
  from public.workspace_members
  where user_id = (select auth.uid())
$$;

-- Whether a string is a clock exactly as Hlc.encode writes one: fixed-width digits, so
-- string comparison orders clocks correctly, and a printable-ASCII device id, so it orders
-- them the way Dart does. Hlc.decode uses the same pattern.
create function private.is_clock(clock text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select coalesce(clock collate "C" ~ '^([0-9]{15}):([0-9]{5}):([!-~]+)$', false)
$$;

create function private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- --- what every synced table shares ------------------------------------------------------
-- Applied in a loop over the one list, so no table can be left without its policy,
-- trigger or pull index.

do $$
declare
  t text;
  scope text;
begin
  foreach t in array private.synced_tables() loop
    -- A workspace is scoped by its own id; everything else by the workspace it is in.
    scope := case when t = 'workspaces' then 'id' else 'workspace_id' end;

    execute format('alter table public.%I enable row level security', t);
    execute format(
      'create policy "members can read" on public.%I for select to authenticated '
      || 'using (%I = any (array(select private.my_workspace_ids())))',
      t, scope);

    -- Reads go through row level security. Writes go through merge_rows and nowhere else.
    execute format('revoke all on public.%I from anon', t);
    execute format(
      'revoke insert, update, delete, truncate, references, trigger on public.%I '
      || 'from authenticated',
      t);

    -- The pull: one workspace's rows, changed since a cursor, in (updated_at, id) order.
    if t = 'workspaces' then
      execute 'create index workspaces_pull on public.workspaces (updated_at, id)';
    else
      execute format('create index %I on public.%I (workspace_id, updated_at, id)', t || '_pull', t);
    end if;

    execute format(
      'create trigger touch_updated_at before insert or update on public.%I '
      || 'for each row execute function private.touch_updated_at()',
      t);
  end loop;
end
$$;

alter table public.workspace_members enable row level security;

create policy "members see their own memberships" on public.workspace_members
  for select to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.workspace_members from anon;
revoke insert, update, delete, truncate, references, trigger on public.workspace_members
  from authenticated;

-- Foreign keys the pull index does not already lead with.
create index workspace_members_user on public.workspace_members (user_id);
create index lists_board on public.lists (board_id);
create index tasks_list on public.tasks (list_id);
create index subtasks_task on public.subtasks (task_id);
create index task_labels_task on public.task_labels (task_id);
create index task_labels_label on public.task_labels (label_id);
create index field_defs_board on public.field_defs (board_id);
create index field_values_task on public.field_values (task_id);
create index field_values_field on public.field_values (field_id);
create index project_views_board on public.project_views (board_id);

-- --- the write path ----------------------------------------------------------------------

-- Applies a batch of changes from one device, field by field.
--
-- Each change is {"table", "id", "values": {column: value}, "versions": {column: clock},
-- "client_id"}. A field is taken only if its clock is readable and newer than the one
-- stored: the rules of FieldMerge.apply, restated in SQL. Equal clocks are the same write
-- delivered twice and change nothing, so a retried batch is harmless.
--
-- Security definer because devices have no write grants at all. This function is the
-- write path, and it checks membership itself.
create function public.merge_rows(changes jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  -- Refused beyond this, matching Hlc.defaultMaxDrift on devices.
  horizon_ms bigint := (extract(epoch from now()) * 1000)::bigint + 5 * 60 * 1000;
  change jsonb;
  target text;
  row_id uuid;
  incoming jsonb;
  clocks jsonb;
  sender text;
  table_columns text[];
  stored jsonb;
  stored_clocks jsonb;
  workspace uuid;
  taken jsonb;
  taken_clocks jsonb;
  col text;
  clock text;
  column_list text;
  inserted integer;
begin
  if caller is null then
    raise exception 'sign in to sync' using errcode = '42501';
  end if;
  if jsonb_typeof(changes) is distinct from 'array' then
    raise exception 'changes must be a JSON array' using errcode = '22023';
  end if;
  if jsonb_array_length(changes) > 1000 then
    raise exception 'at most 1000 changes per call' using errcode = '22023';
  end if;

  for change in select value from jsonb_array_elements(changes) loop
    target := change->>'table';
    if target is null or not (target = any (private.synced_tables())) then
      raise exception 'not a synced table: %', target using errcode = '22023';
    end if;

    row_id := (change->>'id')::uuid;
    incoming := coalesce(change->'values', '{}'::jsonb);
    clocks := coalesce(change->'versions', '{}'::jsonb);
    sender := change->>'client_id';

    -- A device with a badly wrong date would otherwise win every conflict from here on.
    -- Refusing the batch makes that device's sync fail visibly, which is where the clock
    -- needs fixing.
    for clock in select value #>> '{}' from jsonb_each(clocks) loop
      if private.is_clock(clock) and left(clock, 15)::bigint > horizon_ms then
        raise exception 'clock ahead of server time: %', clock using errcode = 'GW001';
      end if;
    end loop;

    select array_agg(a.attname::text) into table_columns
    from pg_catalog.pg_attribute a
    where a.attrelid = format('public.%I', target)::regclass
      and a.attnum > 0
      and not a.attisdropped;

    execute format('select to_jsonb(t) from public.%I t where t.id = $1 for update', target)
      into stored
      using row_id;

    if stored is null then
      -- A new row: nothing stored to compare against, so every field with a readable clock
      -- is taken. Columns this schema lacks are ignored, so an older server keeps working
      -- with a newer app.
      taken := '{}'::jsonb;
      taken_clocks := '{}'::jsonb;
      for col in select key from jsonb_each(incoming) loop
        clock := clocks->>col;
        continue when not (col = any (table_columns))
          or col in ('id', 'field_versions', 'client_id', 'updated_at')
          or not private.is_clock(clock);
        taken := taken || jsonb_build_object(col, incoming->col);
        taken_clocks := taken_clocks || jsonb_build_object(col, clock);
      end loop;

      if target <> 'workspaces' then
        workspace := (taken->>'workspace_id')::uuid;
        if workspace is null or not exists (
          select 1 from public.workspace_members m
          where m.workspace_id = workspace and m.user_id = caller
        ) then
          raise exception 'not a member of workspace %', workspace using errcode = '42501';
        end if;
      end if;

      taken := taken || jsonb_build_object(
        'id', row_id,
        'field_versions', taken_clocks,
        'client_id', sender
      );
      select string_agg(format('%I', k), ', ') into column_list
      from jsonb_object_keys(taken) as k;

      execute format(
        'insert into public.%I (%s) select %s from jsonb_populate_record(null::public.%I, $1) '
        || 'on conflict (id) do nothing',
        target, column_list, column_list, target)
        using taken;
      get diagnostics inserted = row_count;

      if inserted = 1 then
        -- Whoever creates a workspace is its member.
        if target = 'workspaces' then
          insert into public.workspace_members (workspace_id, user_id) values (row_id, caller);
        end if;
        continue;
      end if;

      -- Another device inserted the same id in the meantime (a derived id, most likely).
      -- Merge into that row instead.
      execute format('select to_jsonb(t) from public.%I t where t.id = $1 for update', target)
        into stored
        using row_id;
    end if;

    workspace := case
      when target = 'workspaces' then row_id
      else (stored->>'workspace_id')::uuid
    end;
    if not exists (
      select 1 from public.workspace_members m
      where m.workspace_id = workspace and m.user_id = caller
    ) then
      raise exception 'not a member of workspace %', workspace using errcode = '42501';
    end if;

    stored_clocks := coalesce(stored->'field_versions', '{}'::jsonb);
    taken := '{}'::jsonb;
    taken_clocks := '{}'::jsonb;

    for col in select key from jsonb_each(incoming) loop
      clock := clocks->>col;
      -- A row stays in the workspace it was created in.
      continue when not (col = any (table_columns))
        or col in ('id', 'field_versions', 'client_id', 'updated_at', 'workspace_id')
        or not private.is_clock(clock);
      -- Taken if nothing readable is stored for this field, or the incoming clock is
      -- newer. Equal clocks are the same write twice; older ones lose.
      if not private.is_clock(stored_clocks->>col)
        or clock collate "C" > (stored_clocks->>col) collate "C" then
        taken := taken || jsonb_build_object(col, incoming->col);
        taken_clocks := taken_clocks || jsonb_build_object(col, clock);
      end if;
    end loop;

    -- Nothing newer means no write, so updated_at does not move and the row is not sent
    -- again to devices that already have it.
    continue when taken = '{}'::jsonb;

    select string_agg(format('%I', k), ', ') into column_list
    from jsonb_object_keys(taken) as k;

    execute format(
      'update public.%I set (%s) = (select %s from jsonb_populate_record(null::public.%I, $1)), '
      || 'field_versions = field_versions || $2, client_id = $3 where id = $4',
      target, column_list, column_list, target)
      using taken, taken_clocks, sender, row_id;
  end loop;
end;
$$;

-- --- the read path -----------------------------------------------------------------------

-- One page of a table's rows changed at or after `since`, continuing after
-- (after_updated_at, after_id), in (updated_at, id) order.
--
-- Security invoker: row level security decides what the caller sees, exactly as for a
-- plain select. Paging by position rather than by timestamp is what stops a page full of
-- rows sharing one updated_at from being fetched forever.
create function public.pull_rows(
  target text,
  since timestamptz default null,
  after_updated_at timestamptz default null,
  after_id uuid default null,
  max_rows integer default 500
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  page jsonb;
begin
  if target is null or not (target = any (private.synced_tables())) then
    raise exception 'not a synced table: %', target using errcode = '22023';
  end if;

  execute format(
    'select coalesce(jsonb_agg(to_jsonb(p) order by p.updated_at, p.id), ''[]''::jsonb) '
    || 'from (select * from public.%I t '
    || 'where ($1::timestamptz is null or t.updated_at >= $1) '
    || 'and ($2::timestamptz is null or (t.updated_at, t.id) > ($2, $3)) '
    || 'order by t.updated_at, t.id limit $4) p',
    target)
    into page
    using since, after_updated_at, after_id, least(greatest(max_rows, 1), 1000);

  return page;
end;
$$;

-- --- grants ------------------------------------------------------------------------------

grant usage on schema private to authenticated;

revoke all on function private.synced_tables() from public, anon;
revoke all on function private.my_workspace_ids() from public, anon;
revoke all on function private.is_clock(text) from public, anon, authenticated;
revoke all on function private.touch_updated_at() from public, anon, authenticated;
-- Policies and pull_rows run as the caller, so these two must be executable by them.
grant execute on function private.synced_tables() to authenticated;
grant execute on function private.my_workspace_ids() to authenticated;

revoke all on function public.merge_rows(jsonb) from public, anon;
revoke all on function public.pull_rows(text, timestamptz, timestamptz, uuid, integer)
  from public, anon;
grant execute on function public.merge_rows(jsonb) to authenticated;
grant execute on function public.pull_rows(text, timestamptz, timestamptz, uuid, integer)
  to authenticated;
