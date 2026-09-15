-- Sleep set per day, and task reminders.
--
-- Additive only. merge_rows ignores any column a table lacks, so an app from before this
-- migration and one from after it keep syncing with each other; the new fields sync once
-- both the app and the server have them.

-- When you get up on each day, and when you go to bed that night, in minutes past
-- midnight. A bedtime at or before the time you get up is after midnight. Two columns a
-- day rather than one list, so edits to different days on different devices merge.
alter table public.capacity_profiles
  add column wake_mon_min integer not null default 420,
  add column bedtime_mon_min integer not null default 1410,
  add column wake_tue_min integer not null default 420,
  add column bedtime_tue_min integer not null default 1410,
  add column wake_wed_min integer not null default 420,
  add column bedtime_wed_min integer not null default 1410,
  add column wake_thu_min integer not null default 420,
  add column bedtime_thu_min integer not null default 1410,
  add column wake_fri_min integer not null default 420,
  add column bedtime_fri_min integer not null default 1410,
  add column wake_sat_min integer not null default 420,
  add column bedtime_sat_min integer not null default 1410,
  add column wake_sun_min integer not null default 420,
  add column bedtime_sun_min integer not null default 1410;

-- Every day starts where the single bedtime and sleep target already put it, as each
-- device's own database migration does. No field clocks are written, so these values never
-- beat an edit: the first real change to a day, from any device, wins.
update public.capacity_profiles set
  wake_mon_min = (sleep_start_min + sleep_target_min) % 1440,
  bedtime_mon_min = sleep_start_min,
  wake_tue_min = (sleep_start_min + sleep_target_min) % 1440,
  bedtime_tue_min = sleep_start_min,
  wake_wed_min = (sleep_start_min + sleep_target_min) % 1440,
  bedtime_wed_min = sleep_start_min,
  wake_thu_min = (sleep_start_min + sleep_target_min) % 1440,
  bedtime_thu_min = sleep_start_min,
  wake_fri_min = (sleep_start_min + sleep_target_min) % 1440,
  bedtime_fri_min = sleep_start_min,
  wake_sat_min = (sleep_start_min + sleep_target_min) % 1440,
  bedtime_sat_min = sleep_start_min,
  wake_sun_min = (sleep_start_min + sleep_target_min) % 1440,
  bedtime_sun_min = sleep_start_min;

-- When to be reminded about a task. Null for no reminder.
alter table public.tasks
  add column remind_at timestamptz;
