-- Focus sessions: the focus timer's, and the time they track.
--
-- A row per session — focus on a task or on nothing in particular, or a break — which
-- syncs like any other, so a session started on one device runs on every other one too.
-- Running while ended_at is null.
--
-- Additive. An app from before this migration keeps syncing, and simply has no timer.

create table public.focus_sessions (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  task_id uuid references public.tasks (id) deferrable initially deferred,
  started_at timestamptz not null,
  ended_at timestamptz,
  planned_min integer not null,
  kind text not null default 'focus' check (kind in ('focus', 'break'))
);

create index focus_session_task on public.focus_sessions (task_id);
create index focus_session_started on public.focus_sessions (started_at);

-- Every synced table, parents before children: a session after the task it is on. The same
-- list, in the same order, as lib/sync/synced_tables.dart.
create or replace function private.synced_tables()
returns text[]
language sql
immutable
set search_path = ''
as $$
  select array[
    'workspaces',
    'areas',
    'boards',
    'lists',
    'tasks',
    'subtasks',
    'labels',
    'task_labels',
    'notes',
    'note_images',
    'focus_sessions',
    'capacity_profiles',
    'schedules',
    'commitments',
    'field_defs',
    'field_values',
    'project_views'
  ]
$$;

-- What the first migration gives every synced table.
alter table public.focus_sessions enable row level security;

create policy "members can read" on public.focus_sessions for select to authenticated
  using (workspace_id = any (array(select private.my_workspace_ids())));

revoke all on public.focus_sessions from anon, authenticated;
grant select on public.focus_sessions to authenticated;

create index focus_sessions_pull on public.focus_sessions (workspace_id, updated_at, id);

create trigger touch_updated_at before insert or update on public.focus_sessions
  for each row execute function private.touch_updated_at();

alter publication supabase_realtime add table public.focus_sessions;
