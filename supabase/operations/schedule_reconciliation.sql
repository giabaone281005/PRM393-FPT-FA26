-- MANUAL operation, after functions deployment and Vault setup. Not a migration.
-- Enable pg_cron, pg_net and Vault in Supabase Dashboard first.
-- In Vault create mathlingo_project_url and mathlingo_job_key.
-- mathlingo_job_key MUST equal the COMMERCE_JOB_KEY Edge Function secret.
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM vault.decrypted_secrets WHERE name='mathlingo_project_url')
 OR NOT EXISTS(SELECT 1 FROM vault.decrypted_secrets WHERE name='mathlingo_job_key') THEN
 RAISE EXCEPTION 'Configure Vault secrets before scheduling';END IF;
END $$;
SELECT cron.schedule('mathlingo-commerce-reconcile','*/5 * * * *',
$$ SELECT net.http_post(
 url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name='mathlingo_project_url')||'/functions/v1/commerce-reconcile',
 headers := jsonb_build_object('Content-Type','application/json','x-job-key',(SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name='mathlingo_job_key')),
 body := '{}'::jsonb, timeout_milliseconds := 120000
); $$);
-- Re-running cron.schedule with the same job name updates that job.
-- To disable: SELECT cron.unschedule('mathlingo-commerce-reconcile');
