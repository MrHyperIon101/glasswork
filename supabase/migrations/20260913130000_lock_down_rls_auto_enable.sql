-- Locks down the helper that switches on row level security for new tables.
--
-- The dashboard's automatic RLS option installs public.rls_auto_enable(), a security
-- definer function, with default grants, so the Data API exposes it at
-- /rest/v1/rpc/rls_auto_enable to anyone, signed in or not. It is only meant to run as the
-- event trigger that calls it, and firing an event trigger does not check EXECUTE, so the
-- grants can go.
--
-- Conditional, because the function exists only where that option was switched on. A local
-- database built from these migrations has no such function.
--
-- Deliberately not changed: the advisor also warns that signed-in users can call
-- public.merge_rows, a security definer function. That is the design. Devices hold no write
-- grants at all, and merge_rows is the one write path, checking membership itself.

do $$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    execute 'revoke all on function public.rls_auto_enable() from public, anon, authenticated';
  end if;
end
$$;
