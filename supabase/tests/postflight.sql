-- READ ONLY after all NEW migrations; review every flagged row.
BEGIN READ ONLY;
SELECT schemaname,tablename,rowsecurity FROM pg_tables WHERE schemaname IN ('public','private') ORDER BY 1,2;
SELECT n.nspname,p.proname,p.prosecdef,p.proconfig FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ('public','private') ORDER BY 1,2;
SELECT has_function_privilege('authenticated','public.settle_vnpay_order(uuid,text,bigint,text,text)','EXECUTE') AS must_be_false,
has_table_privilege('authenticated','public.kid_profiles','UPDATE') AS must_be_false,
has_table_privilege('authenticated','public.questions','SELECT') AS must_be_false;
SELECT o.id,o.status,count(p.id) AS payment_count FROM public.learning_orders o LEFT JOIN public.learning_payments p ON p.order_id=o.id WHERE o.status IN ('paid','refunded') GROUP BY o.id HAVING count(p.id)<>1;
SELECT t.id,t.grade,t.week_code,count(*) FROM public.tournaments t JOIN public.tournament_members m ON m.tournament_id=t.id GROUP BY t.id HAVING count(*)>30;
SELECT p.id,p.active_kid_id FROM public.parents p JOIN public.kid_profiles k ON k.id=p.active_kid_id WHERE k.parent_id<>p.id OR k.archived;
SELECT id,status,updated_at FROM public.refund_requests WHERE status IN ('processing','unknown');
-- Content audit: repeated legacy content is deliberately retained for human review.
SELECT q.lesson_id,private.question_expected(to_jsonb(q)) AS expected,q.prompt FROM public.questions q WHERE q.is_active AND nullif(private.question_expected(to_jsonb(q)),'') IS NULL;
SELECT md5(prompt||payload::text) AS fingerprint,count(*) AS repeats FROM public.questions WHERE is_active GROUP BY 1 HAVING count(*)>1 ORDER BY repeats DESC;
SELECT conname,convalidated FROM pg_constraint WHERE conrelid='public.parents'::regclass;
ROLLBACK;
