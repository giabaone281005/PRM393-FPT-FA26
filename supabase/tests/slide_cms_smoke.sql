BEGIN;
DO $$
DECLARE admin uuid:=gen_random_uuid(); learner uuid:=gen_random_uuid(); other_user uuid:=gen_random_uuid();
BEGIN
 PERFORM set_config('test.slide_admin',admin::text,true);PERFORM set_config('test.slide_user',learner::text,true);PERFORM set_config('test.slide_other',other_user::text,true);
 PERFORM set_config('test.slide_topic','qa-slides-'||replace(admin::text,'-',''),true);
 INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES(admin,'slides-admin-'||admin||'@example.invalid','{}'),(learner,'slides-user-'||learner||'@example.invalid','{}'),(other_user,'slides-other-'||other_user||'@example.invalid','{}');
 UPDATE private.account_access SET role='admin' WHERE user_id=admin;
 PERFORM set_config('request.jwt.claim.sub',admin::text,true);PERFORM set_config('request.jwt.claim.role','authenticated',true);
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE topic text:=current_setting('test.slide_topic'); lesson text:=topic||'-lesson'; body jsonb; result jsonb; catalog jsonb;
 draft_op uuid:=gen_random_uuid(); publish_op uuid:=gen_random_uuid(); attempt_op uuid:=gen_random_uuid(); complete_op uuid:=gen_random_uuid();
 pid uuid:=gen_random_uuid(); sid uuid:=gen_random_uuid(); rid uuid;
 solution jsonb:='{"index":3,"slides":[{"ack":true},{"answer":1},{"values":[0,1]},{"a":2,"b":1}]}';
 cfg jsonb:='{"schema_version":1,"slides":[
 {"id":"story","engine":"story","locked":true,"title":"Giới thiệu","prompt":"","hint":"","explanation":"","config":{"text":"Cùng khám phá mô hình.","image_url":"","image_alt":""}},
 {"id":"quiz","engine":"quiz","locked":true,"title":"Chọn đáp án","prompt":"Một nửa của tám?","hint":"Chia đôi","explanation":"Bốn","config":{"choices":["8","4"],"answer":1}},
 {"id":"pairs","engine":"pairs","locked":true,"title":"Ghép cặp","prompt":"Ghép phân số","hint":"Rút gọn","explanation":"Hai phân số tương đương","config":{"pairs":[{"left":"1/2","right":"2/4"},{"left":"1/4","right":"2/8"}]}},
 {"id":"graph","engine":"graph","locked":true,"title":"Đồ thị","prompt":"Dựng y=2x+1","hint":"a=2,b=1","explanation":"Độ dốc 2, giao điểm 1","config":{"min_a":-5,"max_a":5,"min_b":-5,"max_b":5,"start_a":0,"start_b":0,"target_a":2,"target_b":1}}
 ]}';
BEGIN
 PERFORM public.admin_learning_mutate(gen_random_uuid(),'topic.save',jsonb_build_object('id',topic,'title','QA Slides','subject','QA','status','active','sort_order',999,'icon_key','menu_book_outlined'));
 body:=jsonb_build_object('id',lesson,'topic_id',topic,'title','Bài nhiều engine','prompt','Hoàn thành các slide','stage','Khám phá','hint','Đọc từng slide','explanation','Hoàn thành','status','active','sort_order',0,'mechanism','slideLesson','config',cfg,'revision',0);
 result:=public.admin_builder_save(draft_op,body);
 IF result IS DISTINCT FROM public.admin_builder_save(draft_op,body) THEN RAISE EXCEPTION 'Draft retry not stable'; END IF;
 IF (public.admin_builder_read(topic)->>'total')::int<>1 THEN RAISE EXCEPTION 'Draft not readable'; END IF;
 BEGIN PERFORM public.admin_builder_save(gen_random_uuid(),body);RAISE EXCEPTION 'Stale draft accepted';EXCEPTION WHEN SQLSTATE 'PT409' THEN NULL;END;
 PERFORM set_config('request.jwt.claim.sub',current_setting('test.slide_user'),true);
 IF EXISTS(SELECT 1 FROM jsonb_array_elements(public.learning_catalog('1.3.4')->'activities') a WHERE a->>'activity_id'=lesson) THEN RAISE EXCEPTION 'Unpublished draft exposed'; END IF;
 IF EXISTS(SELECT 1 FROM public.lesson_builder_drafts WHERE id=lesson) THEN RAISE EXCEPTION 'User can read builder drafts'; END IF;
 BEGIN PERFORM public.admin_builder_read(topic);RAISE EXCEPTION 'User read CMS';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
 BEGIN PERFORM public.admin_builder_save(gen_random_uuid(),body);RAISE EXCEPTION 'User wrote CMS';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
 PERFORM set_config('request.jwt.claim.sub',current_setting('test.slide_admin'),true);
 BEGIN PERFORM public.admin_content_mutate(gen_random_uuid(),body||'{"builder_revision":0}');RAISE EXCEPTION 'Stale builder published';EXCEPTION WHEN SQLSTATE 'PT409' THEN NULL;END;
 result:=public.admin_content_mutate(publish_op,body||'{"builder_revision":1}');
 IF result IS DISTINCT FROM public.admin_content_mutate(publish_op,body||'{"builder_revision":1}') THEN RAISE EXCEPTION 'Publication retry failed';END IF;
 PERFORM set_config('request.jwt.claim.sub',current_setting('test.slide_user'),true);
 catalog:=public.learning_catalog('1.3.4');rid:=(catalog#>>'{release,id}')::uuid;
 IF NOT EXISTS(SELECT 1 FROM jsonb_array_elements(catalog->'activities') a WHERE a->>'activity_id'=lesson AND a->>'evaluator_version'='4' AND a->'config'=cfg) THEN RAISE EXCEPTION 'Published slide lesson missing';END IF;
 IF EXISTS(SELECT 1 FROM jsonb_array_elements(public.learning_catalog('1.3.3')->'activities') a WHERE a->>'activity_id'=lesson) THEN RAISE EXCEPTION 'Unsupported engine exposed to old client';END IF;
 PERFORM public.learning_mutate(gen_random_uuid(),'profile.create',jsonb_build_object('id',pid,'name','Slide fixture','daily_minutes',10,'interest_topic_ids','[]'::jsonb));
 PERFORM public.learning_mutate(gen_random_uuid(),'session.start',jsonb_build_object('id',sid,'profile_id',pid,'topic_id',topic,'release_id',rid));
 result:=public.authored_attempt(gen_random_uuid(),jsonb_build_object('session_id',sid,'activity_id',lesson,'content_version',1,'state','{"is_correct":true,"slides":[{"ack":true},{"answer":1},{"values":[0,1]},{"a":0,"b":0}]}'::jsonb));
 IF (result#>>'{result,attempt,is_correct}')::boolean THEN RAISE EXCEPTION 'Incorrect graph awarded correctness';END IF;
 PERFORM set_config('request.jwt.claim.sub',current_setting('test.slide_other'),true);
 BEGIN PERFORM public.authored_attempt(gen_random_uuid(),jsonb_build_object('session_id',sid,'activity_id',lesson,'content_version',1,'state',solution));RAISE EXCEPTION 'Other owner submitted';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
 PERFORM set_config('request.jwt.claim.sub',current_setting('test.slide_user'),true);
 result:=public.authored_attempt(attempt_op,jsonb_build_object('session_id',sid,'activity_id',lesson,'content_version',1,'state',solution));
 IF NOT (result#>>'{result,attempt,is_correct}')::boolean THEN RAISE EXCEPTION 'Correct multi-engine answer rejected';END IF;
 result:=public.learning_mutate(complete_op,'session.complete',jsonb_build_object('session_id',sid));
 IF (result#>>'{result,xp_awarded}')::int<>30 THEN RAISE EXCEPTION 'Canonical completion failed';END IF;
 IF result IS DISTINCT FROM public.learning_mutate(complete_op,'session.complete',jsonb_build_object('session_id',sid)) THEN RAISE EXCEPTION 'Completion retry not stable';END IF;
END $$;
RESET ROLE;
DO $$ BEGIN
 IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.lesson_builder_drafts'::regclass) THEN RAISE EXCEPTION 'Drafts lack RLS';END IF;
 IF EXISTS(SELECT 1 FROM pg_proc WHERE pronamespace='public'::regnamespace AND prosecdef AND proname IN ('admin_builder_read','admin_builder_save')) THEN RAISE EXCEPTION 'Unsafe public wrapper';END IF;
END $$;
SELECT 'PASS: draft isolation/retries/conflicts, four engines, publication, mobile compatibility, authority, wrong/right attempts and XP' AS result;
ROLLBACK;
