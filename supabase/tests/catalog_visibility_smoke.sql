-- Admin metadata/visibility and session history share one contract. Roll back all fixtures.
BEGIN;
DO $$
DECLARE actor uuid := gen_random_uuid(); admin uuid := gen_random_uuid();
  profile_id uuid := gen_random_uuid(); session_id uuid := gen_random_uuid();
  wanted_release uuid; saved jsonb; catalog jsonb;
BEGIN
  INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES
    (actor,'catalog-user-'||actor||'@example.invalid','{}'),
    (admin,'catalog-admin-'||admin||'@example.invalid','{}');
  UPDATE private.account_access SET role='admin' WHERE user_id=admin;
  PERFORM set_config('request.jwt.claim.sub',actor::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  catalog := public.learning_catalog('1.3.2');
  IF jsonb_array_length(catalog->'topics')<>20 OR jsonb_array_length(catalog->'activities')<>139
    THEN RAISE EXCEPTION 'Full catalog missing'; END IF;
  wanted_release := (catalog#>>'{release,id}')::uuid;
  PERFORM public.learning_mutate(gen_random_uuid(),'profile.create',jsonb_build_object('id',profile_id,
    'name','Catalog fixture','daily_minutes',10,'interest_topic_ids','[]'::jsonb));
  PERFORM public.learning_mutate(gen_random_uuid(),'session.start',jsonb_build_object('id',session_id,
    'profile_id',profile_id,'topic_id','logic','release_id',wanted_release));
  PERFORM set_config('request.jwt.claim.sub',admin::text,true);
  SELECT to_jsonb(t)||jsonb_build_object('title','Catalog live metadata fixture','status','archived')
    INTO saved FROM public.topics t WHERE id='logic';
  PERFORM public.admin_learning_mutate(gen_random_uuid(),'topic.save',saved);
  PERFORM set_config('request.jwt.claim.sub',actor::text,true);
  catalog := public.learning_catalog('1.3.2');
  IF NOT EXISTS(SELECT 1 FROM jsonb_array_elements(catalog->'topics') t WHERE t->>'id'='logic'
    AND t->>'title'='Catalog live metadata fixture' AND t->>'status'='archived')
    THEN RAISE EXCEPTION 'Admin metadata/status did not reach learning catalog'; END IF;
  BEGIN
    PERFORM public.learning_mutate(gen_random_uuid(),'session.start',jsonb_build_object('id',gen_random_uuid(),
      'profile_id',profile_id,'topic_id','logic','release_id',wanted_release));
    RAISE EXCEPTION 'Archived topic accepted a new session';
  EXCEPTION WHEN invalid_parameter_value THEN
    IF SQLERRM <> 'Lesson unavailable' THEN RAISE; END IF;
  END;
  -- An existing pinned session remains writable after discovery is archived.
  PERFORM public.learning_mutate(gen_random_uuid(),'draft.save',jsonb_build_object('id',gen_random_uuid(),
    'session_id',session_id,'activity_id','logic-balance','expected_revision','0','snapshot','{}'::jsonb));
  IF NOT EXISTS(SELECT 1 FROM public.learning_sessions WHERE id=session_id AND release_id=wanted_release)
    THEN RAISE EXCEPTION 'Archive lost pinned session'; END IF;
END $$;
ROLLBACK;
