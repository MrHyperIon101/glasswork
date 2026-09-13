-- Behavioural checks for the sync schema, against a real Postgres.
--
-- Everything runs in one transaction that always rolls back: the last statement raises on
-- purpose, so the accounts, rows and helpers created here never persist. A good run ends
-- with "ALL SYNC SCHEMA CHECKS PASSED"; any other error names the check that failed.
--
-- Run it against a database that already has the migration. To check a migration before it
-- is applied, send the migration and this file together, in that order, as one query.

begin;

-- --- helpers ----------------------------------------------------------------------------

-- A change as a device sends it, every value stamped with the one clock.
create function private.check_change(target text, row_id uuid, vals jsonb, clock text)
returns jsonb
language sql
as $$
  select jsonb_build_object(
    'table', target,
    'id', row_id,
    'client_id', split_part(clock, ':', 3),
    'values', vals,
    'versions', coalesce(
      (select jsonb_object_agg(k, clock) from jsonb_object_keys(vals) as k),
      '{}'::jsonb
    )
  )
$$;

-- Fails the run, naming the check, unless the condition is true.
create function private.check(ok boolean, label text)
returns void
language plpgsql
as $$
begin
  if ok is not true then
    raise exception 'CHECK FAILED: %', label;
  end if;
end;
$$;

-- The same, with the yes-or-no query run as an API role rather than the owner.
create function private.check_as(as_role text, query text, label text)
returns void
language plpgsql
as $$
declare
  ok boolean;
begin
  begin
    execute format('set local role %I', as_role);
    execute query into ok;
    reset role;
  exception when others then
    raise exception 'CHECK FAILED: % (%: %)', label, sqlstate, sqlerrm;
  end;
  if ok is not true then
    raise exception 'CHECK FAILED: %', label;
  end if;
end;
$$;

-- Fails the run unless the statement, run as the given role (the owner if null), is refused
-- with the given SQLSTATE. A refused statement is undone by its own subtransaction.
create function private.check_refused(as_role text, statement text, expected text, label text)
returns void
language plpgsql
as $$
begin
  begin
    if as_role is not null then
      execute format('set local role %I', as_role);
    end if;
    execute statement;
  exception when others then
    if sqlstate = expected then
      return;
    end if;
    raise exception 'CHECK FAILED: % (expected %, got %: %)', label, expected, sqlstate, sqlerrm;
  end;
  raise exception 'CHECK FAILED: % (expected %, but it was allowed)', label, expected;
end;
$$;

-- --- two accounts -----------------------------------------------------------------------

insert into auth.users (id, email)
values
  ('00000000-0000-4000-8000-00000000000a', 'check-a@example.invalid'),
  ('00000000-0000-4000-8000-00000000000b', 'check-b@example.invalid');

-- Requests from account A. The API sets these claims from the caller's token.
set local request.jwt.claims to
  '{"sub": "00000000-0000-4000-8000-00000000000a", "role": "authenticated"}';

-- --- writing ----------------------------------------------------------------------------

-- A workspace, then its contents with each child ahead of its parent. Foreign keys are
-- deferred, so order inside a batch does not matter once the workspace exists.
select public.merge_rows(jsonb_build_array(
  private.check_change('workspaces', 'aaaaaaaa-0000-4000-8000-000000000001',
    '{"name": "Personal", "created_at": "2026-09-01T09:00:00Z"}',
    '001757000000000:00000:laptop'),
  private.check_change('tasks', 'aaaaaaaa-0000-4000-8000-000000000004',
    '{"workspace_id": "aaaaaaaa-0000-4000-8000-000000000001",
      "list_id": "aaaaaaaa-0000-4000-8000-000000000003",
      "title": "DBMS lab", "order_key": "a0", "priority": 1, "status": "open",
      "due_at": "2026-09-20T18:30:00.000Z", "scheduled_for": "2026-09-18"}',
    '001757000000000:00000:laptop'),
  private.check_change('lists', 'aaaaaaaa-0000-4000-8000-000000000003',
    '{"workspace_id": "aaaaaaaa-0000-4000-8000-000000000001",
      "board_id": "aaaaaaaa-0000-4000-8000-000000000002",
      "name": "To do", "order_key": "a0", "is_done_column": false}',
    '001757000000000:00000:laptop'),
  private.check_change('boards', 'aaaaaaaa-0000-4000-8000-000000000002',
    '{"workspace_id": "aaaaaaaa-0000-4000-8000-000000000001", "name": "Sem V",
      "order_key": "a0", "archived": false, "colour": 4278879487, "view_default": "board"}',
    '001757000000000:00000:laptop'),
  private.check_change('capacity_profiles', 'aaaaaaaa-0000-4000-8000-000000000007',
    '{"workspace_id": "aaaaaaaa-0000-4000-8000-000000000001", "focus_factor": 0.65,
      "sleep_target_min": 450}',
    '001757000000000:00000:laptop')
));

-- Deferred foreign keys are checked now, rather than at a commit this run never makes.
set constraints all immediate;
set constraints all deferred;

select private.check(
  exists (
    select 1 from public.workspace_members
    where workspace_id = 'aaaaaaaa-0000-4000-8000-000000000001'
      and user_id = '00000000-0000-4000-8000-00000000000a'
  ),
  'creating a workspace makes its creator a member');

select private.check(
  (select title = 'DBMS lab'
      and due_at = '2026-09-20T18:30:00Z'::timestamptz
      and scheduled_for = '2026-09-18'::date
      and client_id = 'laptop'
      and field_versions ->> 'title' = '001757000000000:00000:laptop'
      and updated_at is not null
   from public.tasks where id = 'aaaaaaaa-0000-4000-8000-000000000004'),
  'a new row arrives with its values, wire types and clocks');

select private.check(
  (select colour = 4278879487 and archived = false and view_default = 'board'
   from public.boards where id = 'aaaaaaaa-0000-4000-8000-000000000002'),
  'large integers and booleans arrive intact');

select private.check(
  (select focus_factor = 0.65 and sleep_target_min = 450 and meals_min = 90
   from public.capacity_profiles where id = 'aaaaaaaa-0000-4000-8000-000000000007'),
  'fractions arrive intact, and fields not sent take their defaults');

-- --- merging ----------------------------------------------------------------------------

do $$
declare
  task constant uuid := 'aaaaaaaa-0000-4000-8000-000000000004';
  row_before tid;
  row_after tid;
begin
  -- A newer clock takes the field.
  perform public.merge_rows(jsonb_build_array(private.check_change(
    'tasks', task, '{"title": "DBMS lab report"}', '001757000100000:00000:phone')));
  perform private.check(
    (select title = 'DBMS lab report'
        and field_versions ->> 'title' = '001757000100000:00000:phone'
        and field_versions ->> 'priority' = '001757000000000:00000:laptop'
        and client_id = 'phone'
     from public.tasks where id = task),
    'a newer clock takes that field, and only that field');

  -- An older clock loses, and the row is not written at all.
  select ctid into row_before from public.tasks where id = task;
  perform public.merge_rows(jsonb_build_array(private.check_change(
    'tasks', task, '{"title": "stale offline edit"}', '001756999900000:00000:phone')));
  select ctid into row_after from public.tasks where id = task;
  perform private.check(
    row_before = row_after
      and (select title = 'DBMS lab report' from public.tasks where id = task),
    'an older clock loses, and nothing is written');

  -- The same change delivered twice is not a second write.
  perform public.merge_rows(jsonb_build_array(private.check_change(
    'tasks', task, '{"title": "DBMS lab report"}', '001757000100000:00000:phone')));
  select ctid into row_after from public.tasks where id = task;
  perform private.check(row_before = row_after, 'a repeated delivery changes nothing');

  -- Each field is decided on its own clock.
  perform public.merge_rows(jsonb_build_array(jsonb_build_object(
    'table', 'tasks', 'id', task, 'client_id', 'phone',
    'values', '{"title": "stale", "priority": 3}'::jsonb,
    'versions', '{"title": "001756999900000:00000:phone",
                  "priority": "001757000200000:00000:phone"}'::jsonb)));
  perform private.check(
    (select title = 'DBMS lab report' and priority = 3 from public.tasks where id = task),
    'fields in one change are merged independently');

  -- What a device can never set.
  select ctid into row_before from public.tasks where id = task;
  perform public.merge_rows(jsonb_build_array(jsonb_build_object(
    'table', 'tasks', 'id', task, 'client_id', 'phone',
    'values', jsonb_build_object(
      'workspace_id', 'bbbbbbbb-0000-4000-8000-000000000001',
      'updated_at', '2000-01-01T00:00:00Z',
      'field_versions', '{}'::jsonb,
      'no_such_column', 'x',
      'notes_md', 'sent with an unreadable clock'),
    'versions', jsonb_build_object(
      'workspace_id', '001757000300000:00000:phone',
      'updated_at', '001757000300000:00000:phone',
      'field_versions', '001757000300000:00000:phone',
      'no_such_column', '001757000300000:00000:phone',
      'notes_md', '1:2:phone'))));
  select ctid into row_after from public.tasks where id = task;
  perform private.check(
    row_before = row_after
      and (select workspace_id = 'aaaaaaaa-0000-4000-8000-000000000001' and notes_md is null
           from public.tasks where id = task),
    'workspace, bookkeeping, unknown columns and unreadable clocks are all ignored');
end
$$;

select private.check_refused(null,
  $$select public.merge_rows(jsonb_build_array(private.check_change('tasks',
      'aaaaaaaa-0000-4000-8000-000000000004', '{"title": "from a phone set to the wrong year"}',
      '009999999999999:00000:broken')))$$,
  'GW001', 'a clock far ahead of server time is refused');

select private.check(
  (select title = 'DBMS lab report' from public.tasks
   where id = 'aaaaaaaa-0000-4000-8000-000000000004'),
  'a refused batch leaves the row as it was');

-- --- another account --------------------------------------------------------------------

set local request.jwt.claims to
  '{"sub": "00000000-0000-4000-8000-00000000000b", "role": "authenticated"}';

select public.merge_rows(jsonb_build_array(private.check_change(
  'workspaces', 'bbbbbbbb-0000-4000-8000-000000000001', '{"name": "Personal"}',
  '001757000000000:00000:tablet')));

select private.check_refused('authenticated',
  $$select public.merge_rows(jsonb_build_array(private.check_change('tasks',
      'aaaaaaaa-0000-4000-8000-000000000004', '{"title": "not yours"}',
      '001757000900000:00000:intruder')))$$,
  '42501', 'an account cannot edit rows in a workspace it is not a member of');

select private.check_refused('authenticated',
  $$select public.merge_rows(jsonb_build_array(private.check_change('tasks',
      'bbbbbbbb-0000-4000-8000-000000000009',
      '{"workspace_id": "aaaaaaaa-0000-4000-8000-000000000001",
        "list_id": "aaaaaaaa-0000-4000-8000-000000000003",
        "title": "planted", "order_key": "a0"}',
      '001757000900000:00000:intruder')))$$,
  '42501', 'an account cannot add rows to a workspace it is not a member of');

select private.check_refused('authenticated',
  $$select public.merge_rows(jsonb_build_array(private.check_change('workspaces',
      'aaaaaaaa-0000-4000-8000-000000000001', '{"name": "taken over"}',
      '001757000900000:00000:intruder')))$$,
  '42501', 'reusing a workspace id does not make an account a member');

select private.check_refused('authenticated',
  $$update public.workspaces set name = 'written directly'$$,
  '42501', 'rows cannot be written except through merge_rows');

select private.check_refused('authenticated',
  $$insert into public.workspace_members (workspace_id, user_id)
    values ('aaaaaaaa-0000-4000-8000-000000000001', '00000000-0000-4000-8000-00000000000b')$$,
  '42501', 'an account cannot make itself a member');

select private.check_as('authenticated',
  $$select (select count(*) from public.tasks) = 0
       and (select count(*) from public.workspaces) = 1
       and (select count(*) from public.workspace_members) = 1
       and public.pull_rows('tasks') = '[]'::jsonb$$,
  'an account sees only its own workspace, memberships and rows');

-- --- reading ----------------------------------------------------------------------------

set local request.jwt.claims to
  '{"sub": "00000000-0000-4000-8000-00000000000a", "role": "authenticated"}';

select public.merge_rows(jsonb_build_array(
  private.check_change('lists', 'aaaaaaaa-0000-4000-8000-000000000005',
    '{"workspace_id": "aaaaaaaa-0000-4000-8000-000000000001",
      "board_id": "aaaaaaaa-0000-4000-8000-000000000002", "name": "Doing", "order_key": "a1"}',
    '001757000000000:00001:laptop'),
  private.check_change('lists', 'aaaaaaaa-0000-4000-8000-000000000006',
    '{"workspace_id": "aaaaaaaa-0000-4000-8000-000000000001",
      "board_id": "aaaaaaaa-0000-4000-8000-000000000002", "name": "Done", "order_key": "a2"}',
    '001757000000000:00002:laptop')));

-- Every row here shares one updated_at, since it all happens in one transaction. That is
-- exactly the case paging by position exists for.
select private.check_as('authenticated',
  $$with first_page as (
      select public.pull_rows('lists', null, null, null, 2) as rows
    ),
    second_page as (
      select public.pull_rows('lists', null,
        (rows -> 1 ->> 'updated_at')::timestamptz, (rows -> 1 ->> 'id')::uuid, 2) as rows
      from first_page
    )
    select jsonb_array_length(f.rows) = 2
       and jsonb_array_length(s.rows) = 1
       and (select array_agg(e ->> 'id' order by e ->> 'id')
            from jsonb_array_elements(f.rows || s.rows) as e)
           = array['aaaaaaaa-0000-4000-8000-000000000003',
                   'aaaaaaaa-0000-4000-8000-000000000005',
                   'aaaaaaaa-0000-4000-8000-000000000006']
    from first_page f, second_page s$$,
  'pages cover every row exactly once, even when they share one updated_at');

select private.check_as('authenticated',
  $$select jsonb_array_length(public.pull_rows('lists', now() + interval '1 minute')) = 0
       and (public.pull_rows('tasks') -> 0 -> 'field_versions') ? 'title'$$,
  'pulling honours the cursor, and rows carry their clocks');

select private.check_refused('authenticated',
  $$select public.pull_rows('workspace_members')$$,
  '22023', 'only synced tables can be pulled');

select private.check_refused('authenticated',
  $$select public.merge_rows('[{"table": "workspace_members",
      "id": "aaaaaaaa-0000-4000-8000-000000000001", "values": {}, "versions": {}}]')$$,
  '22023', 'only synced tables can be written');

-- --- signed out -------------------------------------------------------------------------

set local request.jwt.claims to '{"role": "anon"}';

select private.check_refused('anon', $$select public.merge_rows('[]')$$,
  '42501', 'a signed-out request cannot call merge_rows');

select private.check_refused('anon', $$select public.pull_rows('tasks')$$,
  '42501', 'a signed-out request cannot call pull_rows');

select private.check_refused('anon', $$select count(*) from public.tasks$$,
  '42501', 'a signed-out request cannot read a table');

-- --- shape ------------------------------------------------------------------------------

select private.check(
  (select bool_and(c.relrowsecurity)
   from pg_catalog.pg_class c
   join pg_catalog.pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind = 'r'),
  'row level security is on for every table in public');

select private.check(
  (select count(*) = cardinality(private.synced_tables())
   from pg_catalog.pg_trigger t
   where t.tgname = 'touch_updated_at' and not t.tgisinternal),
  'every synced table stamps its own updated_at');

-- --- done -------------------------------------------------------------------------------

do $$
begin
  raise exception 'ALL SYNC SCHEMA CHECKS PASSED (raised on purpose, so nothing above is kept)';
end
$$;
