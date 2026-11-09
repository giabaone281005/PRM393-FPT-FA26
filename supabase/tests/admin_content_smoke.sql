-- Real canonical storage and authority. Every fixture and publication rolls back.
BEGIN;
DO $$
DECLARE admin uuid := gen_random_uuid(); learner uuid := gen_random_uuid(); other_user uuid := gen_random_uuid();
BEGIN
  PERFORM set_config('test.cms_admin',admin::text,true);
  PERFORM set_config('test.cms_user',learner::text,true);
  PERFORM set_config('test.cms_other',other_user::text,true);
  PERFORM set_config('test.cms_topic','qa-cms-'||replace(admin::text,'-',''),true);
  INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES
    (admin,'cms-admin-'||admin||'@example.invalid','{}'),
    (learner,'cms-user-'||learner||'@example.invalid','{}'),
    (other_user,'cms-other-'||other_user||'@example.invalid','{}');
  UPDATE private.account_access SET role='admin' WHERE user_id=admin;
  PERFORM set_config('request.jwt.claim.sub',admin::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE topic text := current_setting('test.cms_topic'); lesson text := topic||'-lesson';
  payload jsonb; response jsonb; catalog jsonb; op uuid := gen_random_uuid(); rid uuid; correct_state jsonb; legacy jsonb;
  profile_id uuid := gen_random_uuid(); session_id uuid := gen_random_uuid(); attempt_id uuid := gen_random_uuid();
BEGIN
  PERFORM public.admin_learning_mutate(gen_random_uuid(),'topic.save',jsonb_build_object(
    'id',topic,'title','CMS fixture','subject','QA','status','active','sort_order',999,'icon_key','menu_book_outlined'));
  payload := jsonb_build_object('id',lesson,'topic_id',topic,'title','Một nửa của tám','stage','Khám phá',
    'prompt','Một nửa của 8 là bao nhiêu?','hint','Chia thành hai nhóm bằng nhau.',
    'explanation','Hai nhóm, mỗi nhóm có bốn phần.','sort_order',0,'status','active','revision',0,
    'config','{"knowledge":"Chia đều","choices":["4","8"],"reasons":["8 chia 2 bằng 4","8 cộng 2 bằng 10"],"answer":0,"reason":0,"source":"QA"}'::jsonb);
  payload := payload||coalesce(nullif(current_setting('test.generated_draft',true),'')::jsonb,'{}'::jsonb);
  correct_state := jsonb_build_object('answer',payload#>'{config,answer}','reason',payload#>'{config,reason}');
  response := public.admin_content_mutate(op,payload);
  IF response IS DISTINCT FROM public.admin_content_mutate(op,payload) THEN RAISE EXCEPTION 'Retry changed response'; END IF;
  BEGIN
    PERFORM public.admin_content_mutate(op,payload||'{"title":"conflict"}');
    RAISE EXCEPTION 'Reused operation accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  IF (public.admin_content_read(topic)->>'total')::int<>1 THEN RAISE EXCEPTION 'Admin cannot read saved lesson'; END IF;
  PERFORM set_config('request.jwt.claim.sub',current_setting('test.cms_user'),true);
  catalog := public.learning_catalog('1.3.3');
  IF NOT EXISTS(SELECT 1 FROM jsonb_array_elements(catalog->'activities') a WHERE a->>'activity_id'=lesson AND a->>'prompt'=payload->>'prompt')
    THEN RAISE EXCEPTION 'Admin create did not reach learner'; END IF;
  IF EXISTS(SELECT 1 FROM jsonb_array_elements(public.learning_catalog('1.3.2')->'activities') a WHERE a->>'activity_id'=lesson)
    THEN RAISE EXCEPTION 'Unsupported content reached old app'; END IF;
  rid := (catalog#>>'{release,id}')::uuid;
  PERFORM public.learning_mutate(gen_random_uuid(),'profile.create',jsonb_build_object('id',profile_id,'name','CMS learner','daily_minutes',10,'interest_topic_ids','[]'::jsonb));
  PERFORM public.learning_mutate(gen_random_uuid(),'session.start',jsonb_build_object('id',session_id,'profile_id',profile_id,'topic_id',topic,'release_id',rid));
  BEGIN
    PERFORM public.admin_content_read(topic); RAISE EXCEPTION 'Learner read CMS';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.admin_content_mutate(gen_random_uuid(),payload); RAISE EXCEPTION 'Learner wrote CMS';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  response := public.authored_attempt(gen_random_uuid(),jsonb_build_object('session_id',session_id,'activity_id',lesson,'content_version',1,'state','{"answer":-1,"reason":-1,"is_correct":true}'::jsonb));
  IF (response#>>'{result,attempt,is_correct}')::boolean THEN RAISE EXCEPTION 'Client forged correctness'; END IF;
  PERFORM set_config('request.jwt.claim.sub',current_setting('test.cms_other'),true);
  BEGIN
    PERFORM public.authored_attempt(gen_random_uuid(),jsonb_build_object('session_id',session_id,'activity_id',lesson,'content_version',1,'state',correct_state));
    RAISE EXCEPTION 'Cross-owner attempt accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  PERFORM set_config('request.jwt.claim.sub',current_setting('test.cms_admin'),true);
  payload := payload||'{"revision":1,"title":"Đã cập nhật","prompt":"Câu hỏi mới","config":{"knowledge":"Mới","choices":["8","4"],"reasons":["Sai","Đúng"],"answer":1,"reason":1,"source":"QA"}}';
  PERFORM public.admin_content_mutate(gen_random_uuid(),payload);
  BEGIN
    PERFORM public.admin_content_mutate(gen_random_uuid(),payload); RAISE EXCEPTION 'Stale revision accepted';
  EXCEPTION WHEN SQLSTATE 'PT409' THEN NULL; END;
  PERFORM set_config('request.jwt.claim.sub',current_setting('test.cms_user'),true);
  catalog := public.learning_catalog('1.3.3');
  IF NOT EXISTS(SELECT 1 FROM jsonb_array_elements(catalog->'activities') a WHERE a->>'activity_id'=lesson AND a->>'title'='Đã cập nhật' AND a->>'content_version'='2')
    THEN RAISE EXCEPTION 'Admin edit did not reach learner'; END IF;
  -- Old session keeps its original answer after a new version is published.
  response := public.authored_attempt(attempt_id,jsonb_build_object('session_id',session_id,'activity_id',lesson,'content_version',1,'state',correct_state));
  IF NOT (response#>>'{result,attempt,is_correct}')::boolean THEN RAISE EXCEPTION 'Old answer changed'; END IF;
  IF response IS DISTINCT FROM public.authored_attempt(attempt_id,jsonb_build_object('session_id',session_id,'activity_id',lesson,'content_version',1,'state',correct_state))
    THEN RAISE EXCEPTION 'Attempt retry not stable'; END IF;
  response := public.learning_mutate(gen_random_uuid(),'session.complete',jsonb_build_object('session_id',session_id));
  IF (response#>>'{result,xp_awarded}')::int<>30 THEN RAISE EXCEPTION 'Canonical XP not awarded'; END IF;
  PERFORM set_config('request.jwt.claim.sub',current_setting('test.cms_admin'),true);
  PERFORM public.admin_content_mutate(gen_random_uuid(),payload||'{"revision":2,"status":"archived"}');
  PERFORM set_config('request.jwt.claim.sub',current_setting('test.cms_user'),true);
  IF EXISTS(SELECT 1 FROM jsonb_array_elements(public.learning_catalog('1.3.3')->'activities') a WHERE a->>'activity_id'=lesson)
    THEN RAISE EXCEPTION 'Archived lesson still reaches new catalog'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.topic_completions WHERE owner_user_id=current_setting('test.cms_user')::uuid AND topic_id=topic)
    THEN RAISE EXCEPTION 'Archive removed learning history'; END IF;
  PERFORM set_config('request.jwt.claim.sub',current_setting('test.cms_admin'),true);
  PERFORM public.admin_content_mutate(gen_random_uuid(),payload||'{"revision":3,"status":"active"}');
  PERFORM set_config('request.jwt.claim.sub',current_setting('test.cms_user'),true);
  IF NOT EXISTS(SELECT 1 FROM jsonb_array_elements(public.learning_catalog('1.3.3')->'activities') a WHERE a->>'activity_id'=lesson)
    THEN RAISE EXCEPTION 'Restore did not reach learner'; END IF;
  PERFORM set_config('request.jwt.claim.sub',current_setting('test.cms_admin'),true);
  BEGIN
    PERFORM public.admin_content_mutate(gen_random_uuid(),payload||jsonb_build_object('revision',4,'config',(payload->'config')||'{"answer":null}'));
    RAISE EXCEPTION 'Null answer accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  SELECT value INTO legacy FROM jsonb_array_elements(public.admin_content_read('logic')->'items') WHERE value->>'id'='logic-balance';
  PERFORM public.admin_content_mutate(gen_random_uuid(),jsonb_build_object('id',legacy->>'id','topic_id','logic',
    'title','CMS editorial fixture','stage',legacy->>'stage','prompt',legacy->>'prompt','hint',legacy#>>'{hint_levels,0}',
    'explanation',legacy->>'explanation','sort_order',(legacy->>'sort_order')::int,'status','active','revision',(legacy->>'revision')::int));
  PERFORM set_config('request.jwt.claim.sub',current_setting('test.cms_user'),true);
  IF NOT EXISTS(SELECT 1 FROM jsonb_array_elements(public.learning_catalog('1.3.3')->'activities') a WHERE a->>'activity_id'='logic-balance'
    AND a->>'title'='CMS editorial fixture' AND a->'config'=legacy->'config' AND a->'content_version'=legacy->'content_version')
    THEN RAISE EXCEPTION 'Legacy editorial change lost its shipped evaluator'; END IF;
  IF EXISTS(SELECT 1 FROM jsonb_array_elements(public.learning_catalog('1.3.2')->'activities') a WHERE a->>'title'='CMS editorial fixture')
    THEN RAISE EXCEPTION 'Editorial overlay changed old client content'; END IF;
END $$;
RESET ROLE;
DO $$ BEGIN
  IF private.valid_authored_choice('{"choices":["A","B"],"reasons":["X","Y"],"answer":null,"reason":0}') IS DISTINCT FROM false
    OR private.valid_authored_choice('{"choices":["A","B"],"reasons":["X","Y"],"answer":"0","reason":0}') IS DISTINCT FROM false
    THEN RAISE EXCEPTION 'Invalid answer representation accepted'; END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.lesson_edits'::regclass)
    THEN RAISE EXCEPTION 'CMS table lacks RLS'; END IF;
  IF EXISTS(SELECT 1 FROM pg_proc WHERE pronamespace='public'::regnamespace AND prosecdef
    AND proname IN ('admin_content_read','admin_content_mutate','authored_attempt'))
    THEN RAISE EXCEPTION 'Privileged public wrapper'; END IF;
END $$;
SELECT 'PASS: CRUD, learner catalog, old client, pinned answers, XP, retries, revisions, forged answers, ownership, roles' AS result;
ROLLBACK;
