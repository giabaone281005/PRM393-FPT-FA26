-- Hosted smoke suite. Every record, publication and XP grant rolls back.
BEGIN;
DO $setup$
DECLARE actor uuid:=gen_random_uuid(); learner uuid:=gen_random_uuid();
BEGIN
 INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES(actor,'qa-engine-admin-'||actor||'@example.invalid','{}'),(learner,'qa-engine-user-'||learner||'@example.invalid','{}');
 UPDATE private.account_access SET role='admin' WHERE user_id=actor;
 PERFORM set_config('test.actor',actor::text,true);PERFORM set_config('test.learner',learner::text,true);
 PERFORM set_config('test.topic','qa-engine-'||replace(actor::text,'-',''),true);
 PERFORM set_config('request.jwt.claim.sub',actor::text,true);PERFORM set_config('request.jwt.claim.role','authenticated',true);
END $setup$;
SET LOCAL ROLE authenticated;
DO $qa$
DECLARE topic text:=current_setting('test.topic'); lesson text:=topic||'-lesson'; body jsonb; result jsonb; catalog jsonb; rid uuid;
 pid uuid:=gen_random_uuid(); sid uuid:=gen_random_uuid(); op uuid:=gen_random_uuid(); original jsonb; original_id text;
 cfg jsonb:=$cfg${"schema_version": 1, "slides": [{"id": "extra-numberline", "engine": "numberLine", "locked": true, "title": "QA numberLine", "prompt": "Hoàn thành tương tác theo mục tiêu.", "hint": "Quan sát mô hình.", "explanation": "Bạn đã hoàn thành.", "config": {"min": -10, "max": 10, "start": 0, "target": 4}}, {"id": "extra-fractionboard", "engine": "fractionBoard", "locked": true, "title": "QA fractionBoard", "prompt": "Hoàn thành tương tác theo mục tiêu.", "hint": "Quan sát mô hình.", "explanation": "Bạn đã hoàn thành.", "config": {"denominator": 6, "numerator": 4}}, {"id": "extra-numberinput", "engine": "numberInput", "locked": true, "title": "QA numberInput", "prompt": "Hoàn thành tương tác theo mục tiêu.", "hint": "Quan sát mô hình.", "explanation": "Bạn đã hoàn thành.", "config": {"target_value": 12}}, {"id": "extra-quadraticgraph", "engine": "quadraticGraph", "locked": true, "title": "QA quadraticGraph", "prompt": "Hoàn thành tương tác theo mục tiêu.", "hint": "Quan sát mô hình.", "explanation": "Bạn đã hoàn thành.", "config": {"target_a": 1, "target_b": 0, "target_c": -1}}, {"id": "extra-barchart", "engine": "barChart", "locked": true, "title": "QA barChart", "prompt": "Hoàn thành tương tác theo mục tiêu.", "hint": "Quan sát mô hình.", "explanation": "Bạn đã hoàn thành.", "config": {"labels": ["Nhóm A", "Nhóm B", "Nhóm C"], "target_values": [2, 5, 3]}}, {"id": "extra-coordinatepoint", "engine": "coordinatePoint", "locked": true, "title": "QA coordinatePoint", "prompt": "Hoàn thành tương tác theo mục tiêu.", "hint": "Quan sát mô hình.", "explanation": "Bạn đã hoàn thành.", "config": {"target_x": 3, "target_y": 2}}, {"id": "extra-venndiagram", "engine": "vennDiagram", "locked": true, "title": "QA vennDiagram", "prompt": "Hoàn thành tương tác theo mục tiêu.", "hint": "Quan sát mô hình.", "explanation": "Bạn đã hoàn thành.", "config": {"items": ["Chỉ thuộc A", "Chỉ thuộc B", "Thuộc cả hai", "Không thuộc tập nào"], "answer_values": [1, 2, 3, 0]}}, {"id": "extra-fractioncompare", "engine": "fractionCompare", "locked": true, "title": "QA fractionCompare", "prompt": "Hoàn thành tương tác theo mục tiêu.", "hint": "Quan sát mô hình.", "explanation": "Bạn đã hoàn thành.", "config": {"left_numerator": 2, "left_denominator": 3, "right_numerator": 3, "right_denominator": 4}}, {"id": "extra-shapematch", "engine": "shapeMatch", "locked": true, "title": "QA shapeMatch", "prompt": "Hoàn thành tương tác theo mục tiêu.", "hint": "Quan sát mô hình.", "explanation": "Bạn đã hoàn thành.", "config": {"target_shape": "triangle"}}]}$cfg$; solution jsonb:=$solution${"index": 8, "slides": [{"position": 4}, {"selected": [0, 1, 2, 3]}, {"value": "12"}, {"a": 1, "b": 0, "c": -1}, {"values": [2, 5, 3]}, {"x": 3, "y": 2}, {"values": [1, 2, 3, 0]}, {"comparison": 0}, {"shape": "triangle"}]}$solution$;
BEGIN
 PERFORM public.admin_learning_mutate(gen_random_uuid(),'topic.save',jsonb_build_object('id',topic,'title','QA mobile engines','subject','QA','status','active','sort_order',10000,'icon_key','menu_book_outlined'));
 body:=jsonb_build_object('id',lesson,'topic_id',topic,'title','QA nine mobile engines','stage','Khám phá','prompt','Test mobile runtime','hint','Try each interaction','explanation','All controls checked','sort_order',0,'status','active','mechanism','slideLesson','config',cfg,'revision',0);
 PERFORM public.admin_builder_save(op,body);
 IF public.admin_builder_save(op,body)->>'revision'<>'1' THEN RAISE EXCEPTION 'Draft retry failed'; END IF;
 result:=public.admin_content_mutate(gen_random_uuid(),body||'{"builder_revision":1}');
 rid:=(result->>'release_id')::uuid;
 PERFORM set_config('request.jwt.claim.sub',current_setting('test.learner'),true);
 IF EXISTS(SELECT 1 FROM jsonb_array_elements(public.learning_catalog('1.3.5')->'activities') a WHERE a->>'activity_id'=lesson) THEN RAISE EXCEPTION 'New engine exposed to old app'; END IF;
 catalog:=public.learning_catalog('1.3.6');
 IF NOT EXISTS(SELECT 1 FROM jsonb_array_elements(catalog->'activities') a WHERE a->>'activity_id'=lesson AND a->'config'=cfg) THEN RAISE EXCEPTION 'New engines absent from mobile catalog'; END IF;
 PERFORM public.learning_mutate(gen_random_uuid(),'profile.create',jsonb_build_object('id',pid,'name','QA engines','daily_minutes',10,'interest_topic_ids','[]'::jsonb));
 PERFORM public.learning_mutate(gen_random_uuid(),'session.start',jsonb_build_object('id',sid,'profile_id',pid,'topic_id',topic,'release_id',rid));
 result:=public.authored_attempt(gen_random_uuid(),jsonb_build_object('session_id',sid,'activity_id',lesson,'content_version',1,'state','{}'::jsonb));
 IF (result#>>'{result,attempt,is_correct}')::boolean THEN RAISE EXCEPTION 'Forged answer accepted'; END IF;
 result:=public.authored_attempt(gen_random_uuid(),jsonb_build_object('session_id',sid,'activity_id',lesson,'content_version',1,'state',solution));
 IF NOT (result#>>'{result,attempt,is_correct}')::boolean THEN RAISE EXCEPTION 'Nine-engine solution rejected'; END IF;
 result:=public.learning_mutate(gen_random_uuid(),'session.complete',jsonb_build_object('session_id',sid));
 IF (result#>>'{result,xp_awarded}')::int<>30 THEN RAISE EXCEPTION 'Canonical completion failed'; END IF;
 BEGIN PERFORM public.admin_content_mutate(gen_random_uuid(),body); RAISE EXCEPTION 'Non-admin wrote content'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 PERFORM set_config('request.jwt.claim.sub',current_setting('test.actor'),true);
 SELECT to_jsonb(v)||jsonb_build_object('topic_id',a.topic_id,'revision',coalesce(e.revision,0)) INTO original FROM public.activity_versions v JOIN public.activities a ON a.id=v.activity_id LEFT JOIN public.lesson_edits e ON e.activity_id=a.id WHERE v.status='published' AND v.evaluator_version=1 AND v.mechanism<>'reasonedChoice' ORDER BY v.activity_id LIMIT 1;
 original_id:=original->>'activity_id';
 body:=jsonb_build_object('id',original_id,'topic_id',original->>'topic_id','title','QA converted existing lesson','stage',original->>'stage','prompt',original->>'prompt','hint',original#>>'{hint_levels,0}','explanation',original->>'explanation','sort_order',0,'status','active','revision',original->'revision','mechanism','slideLesson','config',cfg);
 BEGIN PERFORM public.admin_content_mutate(gen_random_uuid(),body); RAISE EXCEPTION 'Conversion without token accepted'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
 PERFORM public.admin_content_mutate(gen_random_uuid(),body||jsonb_build_object('convert_from_version',(original->>'content_version')::int));
 IF NOT EXISTS(SELECT 1 FROM public.activity_versions WHERE activity_id=original_id AND content_version=(original->>'content_version')::int AND config=original->'config' AND mechanism=original->>'mechanism') THEN RAISE EXCEPTION 'Original packaged version changed'; END IF;
 PERFORM set_config('request.jwt.claim.sub',current_setting('test.learner'),true);
 IF NOT EXISTS(SELECT 1 FROM jsonb_array_elements(public.learning_catalog('1.3.6')->'activities') a WHERE a->>'activity_id'=original_id AND a->>'mechanism'='slideLesson') THEN RAISE EXCEPTION 'Converted lesson not synchronized'; END IF;
END $qa$;
RESET ROLE;
SELECT 'PASS: nine engines, mobile version gating, draft retries, real scoring/XP, Admin authority and versioned conversion of existing lessons' AS result;
ROLLBACK;
