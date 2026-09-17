-- Images in notes.
--
-- A row per image, which syncs like any other, and its bytes in the note-images storage
-- bucket, under the workspace's own folder: "<workspace id>/<image id>.jpg". A device sends
-- an image's bytes after its row, and other devices fetch them once the row arrives.
--
-- Additive. An app from before this migration keeps syncing, and simply has no images.

create table public.note_images (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  client_id text,
  field_versions jsonb not null default '{}'::jsonb,
  workspace_id uuid not null references public.workspaces (id) deferrable initially deferred,
  note_id uuid not null references public.notes (id) deferrable initially deferred,
  storage_path text not null,
  mime_type text not null,
  width integer not null,
  height integer not null,
  byte_count integer not null,
  order_key text not null
);

create index note_images_note on public.note_images (note_id);

-- Every synced table, parents before children: an image after the note it is in. The same
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
    'capacity_profiles',
    'schedules',
    'commitments',
    'field_defs',
    'field_values',
    'project_views'
  ]
$$;

-- What the first migration gives every synced table.
alter table public.note_images enable row level security;

create policy "members can read" on public.note_images for select to authenticated
  using (workspace_id = any (array(select private.my_workspace_ids())));

revoke all on public.note_images from anon, authenticated;
grant select on public.note_images to authenticated;

create index note_images_pull on public.note_images (workspace_id, updated_at, id);

create trigger touch_updated_at before insert or update on public.note_images
  for each row execute function private.touch_updated_at();

alter publication supabase_realtime add table public.note_images;

-- --- the bytes ---------------------------------------------------------------------------

-- Private: nothing in it is reachable without a signed-in member of its workspace. Devices
-- make images a few hundred kilobytes before sending them; the limit only stops mistakes.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'note-images',
  'note-images',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do nothing;

-- A workspace's folder is readable and writable by its members, and no one else. Compared as
-- text, so a folder name that is not a workspace id is simply nobody's.
create policy "members read their workspaces' note images"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'note-images'
    and (storage.foldername(name))[1] in (select w::text from private.my_workspace_ids() w)
  );

create policy "members add note images to their workspaces"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'note-images'
    and (storage.foldername(name))[1] in (select w::text from private.my_workspace_ids() w)
  );

-- No update or delete: an image's bytes never change, and deleting an image is a tombstone
-- on its row, so an undo on any device still finds them.
