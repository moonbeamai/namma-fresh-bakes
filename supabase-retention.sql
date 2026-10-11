-- =====================================================================
-- WEEK 3, STEP 4: DELETE OLD ORDERS AUTOMATICALLY
--
-- Orders contain customers' names, phone numbers and addresses. This
-- schedules a daily job that deletes them once they are no longer needed.
--
-- 1. In the Supabase dashboard open Database > Extensions, search for
--    "pg_cron" and switch it on.
-- 2. Run this file once in the SQL Editor. Running it again just updates
--    the same job (it will not create a second one).
--
-- Keep these numbers equal to retentionDays and unfinishedDays in
-- privacy.html, so the privacy page tells customers the truth:
--   * finished orders (completed or cancelled): deleted after 90 days
--   * any order, even an unfinished one: deleted after 180 days
--
-- pg_cron works in UTC. 22:30 UTC is 4:00 am in India.
-- To see the job:    select * from cron.job;
-- To remove the job: select cron.unschedule('delete-old-orders');
-- =====================================================================

select cron.schedule(
  'delete-old-orders',
  '30 22 * * *',
  $$
    delete from public.orders
    where (status in ('completed', 'cancelled') and created_at < now() - interval '90 days')
       or created_at < now() - interval '180 days'
  $$
);
