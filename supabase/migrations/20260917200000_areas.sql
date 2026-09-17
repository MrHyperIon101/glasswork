-- Areas: groups of projects, named by the person, which the sidebar lists projects under.
--
-- Additive. merge_rows ignores a column its table lacks, so an app from before this
-- migration keeps syncing its projects, and an area syncs once the app and the server both
-- have areas.

create table public.areas (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  name text not null,
  order_key text not null
);

-- The area a project is listed under. Null for none; an area is tombstoned, never removed,
-- so a project never points at a row that is gone.
alter table public.boards
  add column area_id uuid references public.areas (id) deferrable initially deferred;

create index boards_area on public.boards (area_id);

-- Every synced table, parents before children: areas before the projects in them. The same
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
    'capacity_profiles',
    'schedules',
    'commitments',
    'field_defs',
    'field_values',
    'project_views'
  ]
$$;

-- What the first migration gives every synced table: members read it, nobody writes it but
-- merge_rows, a pull index, and updated_at stamped on every write.
alter table public.areas enable row level security;

create policy "members can read" on public.areas for select to authenticated
  using (workspace_id = any (array(select private.my_workspace_ids())));

revoke all on public.areas from anon, authenticated;
grant select on public.areas to authenticated;

create index areas_pull on public.areas (workspace_id, updated_at, id);

create trigger touch_updated_at before insert or update on public.areas
  for each row execute function private.touch_updated_at();

-- Other devices hear of a change to an area as it happens, as for every synced table.
alter publication supabase_realtime add table public.areas;
