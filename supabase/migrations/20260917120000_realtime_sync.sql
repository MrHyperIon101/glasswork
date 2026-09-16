-- Tell other devices about a change the moment it is merged.
--
-- Every synced table joins the supabase_realtime publication, and each device listens for
-- changes to them. Row level security still decides what a device hears about: Realtime
-- checks every change against the table's select policy as the listening account, so a
-- device only learns of rows it could read anyway. Hearing of a change only prompts a pull;
-- the rows still arrive through pull_rows.
--
-- Additive. A device that does not listen keeps syncing on its interval.
do $$
declare
  t text;
begin
  foreach t in array private.synced_tables() loop
    if not exists (
      select 1
      from pg_catalog.pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end
$$;
