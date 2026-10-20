-- Development only. Deletes ONLY the exact disposable fixture identified by
-- mathlingo.feature_qa. Refuses any fixture with commerce/support/AI activity.
DO $$
DECLARE q jsonb:=current_setting('mathlingo.feature_qa')::jsonb; u uuid:=(q->>'QA_USER')::uuid;
BEGIN
  IF q->>'SUPABASE_URL'<>'https://seoswmcldwwytdrfrrrb.supabase.co'
    OR q->>'QA_EMAIL' NOT LIKE 'feature-qa-%@example.invalid'
    OR NOT EXISTS(SELECT 1 FROM auth.users WHERE id=u AND email=q->>'QA_EMAIL')
    OR EXISTS(SELECT 1 FROM public.kid_profiles WHERE parent_id=u AND id<>(q->>'QA_KID')::uuid)
    OR EXISTS(SELECT 1 FROM public.learning_orders WHERE parent_id=u)
    OR EXISTS(SELECT 1 FROM public.support_requests WHERE parent_id=u)
    OR EXISTS(SELECT 1 FROM private.ai_requests WHERE parent_id=u)
    THEN RAISE EXCEPTION 'Refusing non-disposable or changed QA fixture'; END IF;
  DELETE FROM auth.sessions WHERE user_id=u;
  DELETE FROM public.practice_garden_logs WHERE kid_id=(q->>'QA_KID')::uuid;
  DELETE FROM public.user_roles WHERE user_id=u;
  DELETE FROM public.parents WHERE id=u;
  DELETE FROM auth.users WHERE id=u AND email=q->>'QA_EMAIL';
  DELETE FROM public.questions WHERE lesson_id=(q->>'QA_LESSON')::uuid;
  DELETE FROM public.lesson_versions WHERE lesson_id=(q->>'QA_LESSON')::uuid;
  DELETE FROM public.lessons WHERE id=(q->>'QA_LESSON')::uuid AND topic_id=(q->>'QA_TOPIC')::uuid;
  DELETE FROM public.topics WHERE id=(q->>'QA_TOPIC')::uuid AND title='QA Hành trình cộng';
END $$;
