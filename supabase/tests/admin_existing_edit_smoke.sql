-- Exercises actual existing content, with all edits and fixtures rolled back.
BEGIN;
DO $$
DECLARE actor uuid:=gen_random_uuid(); learner uuid:=gen_random_uuid(); chosen public.activity_versions;
  body jsonb; result jsonb; revision integer; latest integer; original jsonb; found_row jsonb;
BEGIN
 INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES(actor,'qa-admin-edit-'||actor||'@example.invalid','{}'),(learner,'qa-reader-edit-'||learner||'@example.invalid','{}');
 UPDATE private.account_access SET role='admin' WHERE user_id=actor;
 PERFORM set_config('request.jwt.claim.sub',actor::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 SELECT * INTO chosen FROM public.activity_versions WHERE status='published' AND mechanism='reasonedChoice' AND evaluator_version=2 ORDER BY activity_id LIMIT 1;
 IF NOT FOUND THEN RAISE EXCEPTION 'No existing compiled choice to validate'; END IF;
 original:=to_jsonb(chosen);
 SELECT coalesce((SELECT e.revision FROM public.lesson_edits e WHERE e.activity_id=chosen.activity_id),0) INTO revision;
 body:=jsonb_build_object('id',chosen.activity_id,'topic_id',(SELECT a.topic_id FROM public.activities a WHERE a.id=chosen.activity_id),
   'title','QA existing choice edited','stage',chosen.stage,'prompt',chosen.prompt,'hint',chosen.hint_levels->>0,'explanation',chosen.explanation,
   'status','active','sort_order',0,'revision',revision,'mechanism','reasonedChoice','config',chosen.config||jsonb_build_object('answer',1,'reason',0));
 PERFORM public.admin_builder_save(gen_random_uuid(),body||jsonb_build_object('revision',coalesce((SELECT d.revision FROM public.lesson_builder_drafts d WHERE d.id=chosen.activity_id),0)));
 result:=public.admin_content_mutate(gen_random_uuid(),body);
 SELECT max(content_version) INTO latest FROM public.activity_versions WHERE activity_id=chosen.activity_id;
 IF latest<>chosen.content_version+1 OR NOT EXISTS(SELECT 1 FROM public.activity_versions WHERE activity_id=chosen.activity_id AND content_version=latest AND evaluator_version=3 AND config=body->'config') THEN RAISE EXCEPTION 'Choice edit failed to create authored version'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.activity_versions a WHERE a.activity_id=chosen.activity_id AND a.content_version=chosen.content_version AND to_jsonb(a)=original) THEN RAISE EXCEPTION 'Original version changed'; END IF;
 PERFORM set_config('request.jwt.claim.sub',learner::text,true);
 SELECT value INTO found_row FROM jsonb_array_elements(public.learning_catalog('1.3.5')->'activities') a WHERE a->>'activity_id'=chosen.activity_id;
 IF found_row->>'title'<>'QA existing choice edited' OR found_row->'config' IS DISTINCT FROM body->'config' THEN RAISE EXCEPTION 'Existing edit not synchronized to learner'; END IF;
 PERFORM set_config('request.jwt.claim.sub',actor::text,true);
 SELECT * INTO chosen FROM public.activity_versions WHERE status='published' AND mechanism<>'reasonedChoice' AND evaluator_version IN(1,2) ORDER BY activity_id LIMIT 1;
 original:=to_jsonb(chosen);
 SELECT coalesce((SELECT e.revision FROM public.lesson_edits e WHERE e.activity_id=chosen.activity_id),0) INTO revision;
 body:=jsonb_build_object('id',chosen.activity_id,'topic_id',(SELECT a.topic_id FROM public.activities a WHERE a.id=chosen.activity_id),
  'title','QA existing interactive edited','stage',chosen.stage,'prompt',chosen.prompt,'hint',chosen.hint_levels->>0,'explanation',chosen.explanation,'status','active','sort_order',0,'revision',revision);
 PERFORM public.admin_content_mutate(gen_random_uuid(),body);
 PERFORM set_config('request.jwt.claim.sub',learner::text,true);
 SELECT value INTO found_row FROM jsonb_array_elements(public.learning_catalog('1.3.5')->'activities') a WHERE a->>'activity_id'=chosen.activity_id;
 IF found_row->>'title'<>'QA existing interactive edited' OR found_row->'config' IS DISTINCT FROM chosen.config THEN RAISE EXCEPTION 'Packaged editorial edit not synchronized'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.activity_versions a WHERE a.activity_id=chosen.activity_id AND a.content_version=chosen.content_version AND to_jsonb(a)=original) THEN RAISE EXCEPTION 'Packaged version changed'; END IF;
END $$;
SELECT 'PASS: actual existing choice and packaged lesson edits, learner synchronization, immutable original versions' AS result;
ROLLBACK;
