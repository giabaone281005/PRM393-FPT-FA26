-- Development only. Trusted caller sets transaction-local mathlingo.feature_qa
-- to the JSON from ignored build/feature-qa.json. Never run on production.
DO $$
DECLARE q jsonb:=current_setting('mathlingo.feature_qa')::jsonb; s jsonb;
BEGIN
  IF q->>'SUPABASE_URL'<>'https://seoswmcldwwytdrfrrrb.supabase.co'
    OR q->>'QA_EMAIL' NOT LIKE 'feature-qa-%@example.invalid'
    OR length(q->>'QA_PASSWORD')<32 THEN RAISE EXCEPTION 'Invalid disposable QA config'; END IF;
  INSERT INTO auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,
    raw_app_meta_data,raw_user_meta_data,created_at,updated_at,confirmation_token,recovery_token,email_change_token_new,email_change)
  VALUES('00000000-0000-0000-0000-000000000000',(q->>'QA_USER')::uuid,'authenticated','authenticated',
    q->>'QA_EMAIL',extensions.crypt(q->>'QA_PASSWORD',extensions.gen_salt('bf')),now(),
    '{"provider":"email","providers":["email"]}','{}',now(),now(),'','','','');
  INSERT INTO auth.identities(provider_id,user_id,identity_data,provider,created_at,updated_at)
  VALUES(q->>'QA_USER',(q->>'QA_USER')::uuid,jsonb_build_object('sub',q->>'QA_USER','email',q->>'QA_EMAIL'),'email',now(),now());
  INSERT INTO public.parents(id,email) VALUES((q->>'QA_USER')::uuid,q->>'QA_EMAIL') ON CONFLICT DO NOTHING;
  INSERT INTO public.subscriptions(parent_id) VALUES((q->>'QA_USER')::uuid) ON CONFLICT DO NOTHING;
  INSERT INTO public.kid_profiles(id,parent_id,nickname,grade)
  VALUES((q->>'QA_KID')::uuid,(q->>'QA_USER')::uuid,'Feature QA',1);
  UPDATE public.parents SET active_kid_id=(q->>'QA_KID')::uuid WHERE id=(q->>'QA_USER')::uuid;
  INSERT INTO public.topics(id,grade,topic_number,title) VALUES((q->>'QA_TOPIC')::uuid,1,9997,'QA Hành trình cộng');
  INSERT INTO public.lessons(id,topic_id,lesson_number,title,theory,access_tier,order_index)
  VALUES((q->>'QA_LESSON')::uuid,(q->>'QA_TOPIC')::uuid,1,'QA — Hành trình cộng','Cộng hai số bằng cách đếm thêm.','basic',1);
  INSERT INTO public.questions(id,lesson_id,question_type,prompt,payload,order_index,socratic_hints) VALUES
  ((q->>'QA_QUESTION')::uuid,(q->>'QA_LESSON')::uuid,'word_problem','3 + 2 = ?',
    '{"correctAnswer":5,"options":[3,4,5,6]}',1,'[{"hint_text":"Đếm thêm hai từ ba."}]'),
  ((q->>'QA_QUESTION2')::uuid,(q->>'QA_LESSON')::uuid,'word_problem','4 + 2 = ?',
    '{"correctAnswer":6,"options":[4,5,6,7]}',2,'[{"hint_text":"Đếm thêm hai từ bốn."}]');
  PERFORM set_config('request.jwt.claim.sub',q->>'QA_USER',true);
  SET LOCAL ROLE authenticated;
  s:=public.start_learning_session((q->>'QA_KID')::uuid,(q->>'QA_LESSON')::uuid,'lesson',gen_random_uuid());
  PERFORM public.answer_learning_session((s->>'id')::uuid,q->>'QA_QUESTION','4',gen_random_uuid(),1);
  PERFORM public.answer_learning_session((s->>'id')::uuid,q->>'QA_QUESTION','5',gen_random_uuid(),0);
  PERFORM public.heartbeat_learning_session((s->>'id')::uuid,false,'{"tab":"quiz"}');
  PERFORM public.start_learning_session((q->>'QA_KID')::uuid,NULL,'practice',gen_random_uuid());
  RESET ROLE;
END $$;
