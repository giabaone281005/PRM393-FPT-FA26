BEGIN;

-- Review markers are personal annotations, never grades, rewards or progress.
CREATE TABLE IF NOT EXISTS public.learning_review_states (
  kid_id uuid NOT NULL REFERENCES public.kid_profiles(id) ON DELETE CASCADE,
  question_ref text NOT NULL,
  last_attempt_id uuid NOT NULL REFERENCES public.question_attempts(id) ON DELETE CASCADE,
  resolved boolean NOT NULL DEFAULT false,
  hidden boolean NOT NULL DEFAULT false,
  review_count integer NOT NULL DEFAULT 0 CHECK (review_count >= 0),
  reviewed_at timestamptz,
  PRIMARY KEY (kid_id, question_ref)
);
CREATE INDEX IF NOT EXISTS learning_review_states_attempt ON public.learning_review_states(last_attempt_id);
ALTER TABLE public.learning_review_states ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.learning_review_states FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.learning_review_states TO authenticated;
GRANT ALL ON public.learning_review_states TO service_role;
DROP POLICY IF EXISTS review_owner_read ON public.learning_review_states;
CREATE POLICY review_owner_read ON public.learning_review_states FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.kid_profiles k WHERE k.id=kid_id AND k.parent_id=(SELECT auth.uid())) OR public.is_admin());

CREATE OR REPLACE FUNCTION private.wrong_answer_history(p_kid uuid,p_lesson uuid,p_page integer)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; plus boolean;
BEGIN
  PERFORM private.assert_learning_kid(p_kid);
  IF p_page IS NULL OR p_page NOT BETWEEN 0 AND 10000 THEN RAISE EXCEPTION 'Trang không hợp lệ'; END IF;
  plus := coalesce((private.effective_entitlements()->>'is_plus')::boolean,false);
  WITH latest AS (
    SELECT DISTINCT ON (coalesce(a.question_ref,a.question_id::text))
      a.id,a.session_id,a.question_id,coalesce(a.question_ref,a.question_id::text) AS ref,
      a.answer_value,a.answered_at,s.lesson_id
    FROM public.question_attempts a JOIN public.study_sessions s ON s.id=a.session_id
    LEFT JOIN public.lessons l ON l.id=s.lesson_id
    WHERE s.kid_id=p_kid AND NOT a.is_correct
      AND (p_lesson IS NULL OR s.lesson_id=p_lesson)
      AND (s.lesson_id IS NULL OR (l.published AND (l.access_tier<>'plus' OR plus)))
    ORDER BY coalesce(a.question_ref,a.question_id::text),a.answered_at DESC,a.id DESC
  ), rows AS (
    SELECT a.*,coalesce(snapshot.question,to_jsonb(q)) AS question,
      coalesce(r.last_attempt_id=a.id AND r.resolved,false) AS resolved,
      coalesce(r.review_count,0) AS review_count,r.reviewed_at
    FROM latest a LEFT JOIN public.questions q ON q.id=a.question_id
    LEFT JOIN public.learning_review_states r ON r.kid_id=p_kid AND r.question_ref=a.ref
    LEFT JOIN LATERAL (
      SELECT item AS question FROM private.session_payloads payload,
        LATERAL jsonb_array_elements(payload.content->'questions') item
      WHERE payload.session_id=a.session_id AND item->>'id'=a.ref LIMIT 1
    ) snapshot ON true
    WHERE NOT coalesce(r.last_attempt_id=a.id AND r.hidden,false)
    ORDER BY a.answered_at DESC,a.id DESC LIMIT 100 OFFSET p_page*100
  )
  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'questionId',ref,'prompt',question->>'prompt','questionType',question->>'question_type',
    'userAnswer',answer_value,'lessonId',lesson_id,'timestamp',answered_at,
    'isResolved',resolved,'reviewCount',review_count,'lastReviewedAt',reviewed_at,
    'questionData',coalesce(question->'payload','{}'::jsonb)-'correctAnswer'-'answer'
  ) ORDER BY answered_at DESC,id DESC),'[]'::jsonb) INTO result FROM rows;
  RETURN result;
END $$;

CREATE OR REPLACE FUNCTION private.set_wrong_answer_review(p_kid uuid,p_question text,p_action text,p_lesson uuid)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE a record; n integer:=0; is_resolved boolean; is_hidden boolean;
BEGIN
  PERFORM private.assert_learning_kid(p_kid);
  IF p_action IS NULL OR p_action NOT IN ('resolve','reopen','hide','resolve_all','hide_all','hide_resolved') THEN
    RAISE EXCEPTION 'Thao tác ôn tập không hợp lệ';
  END IF;
  IF p_action IN ('resolve','reopen','hide') AND nullif(p_question,'') IS NULL THEN
    RAISE EXCEPTION 'Thiếu câu hỏi';
  END IF;
  PERFORM 1 FROM public.kid_profiles WHERE id=p_kid FOR UPDATE;
  FOR a IN
    SELECT DISTINCT ON (coalesce(qa.question_ref,qa.question_id::text)) qa.id,
      coalesce(qa.question_ref,qa.question_id::text) AS ref
    FROM public.question_attempts qa JOIN public.study_sessions s ON s.id=qa.session_id
    WHERE s.kid_id=p_kid AND NOT qa.is_correct
      AND (p_question IS NULL OR coalesce(qa.question_ref,qa.question_id::text)=p_question)
      AND (p_lesson IS NULL OR s.lesson_id=p_lesson)
    ORDER BY coalesce(qa.question_ref,qa.question_id::text),qa.answered_at DESC,qa.id DESC
  LOOP
    IF p_action='hide_resolved' AND NOT EXISTS (
      SELECT 1 FROM public.learning_review_states r WHERE r.kid_id=p_kid
        AND r.question_ref=a.ref AND r.last_attempt_id=a.id AND r.resolved AND NOT r.hidden
    ) THEN CONTINUE; END IF;
    IF p_action='resolve_all' AND EXISTS (
      SELECT 1 FROM public.learning_review_states r WHERE r.kid_id=p_kid
        AND r.question_ref=a.ref AND r.last_attempt_id=a.id AND r.hidden
    ) THEN CONTINUE; END IF;
    is_resolved := p_action IN ('resolve','resolve_all','hide_resolved');
    is_hidden := p_action IN ('hide','hide_all','hide_resolved');
    INSERT INTO public.learning_review_states(kid_id,question_ref,last_attempt_id,resolved,hidden,review_count,reviewed_at)
    VALUES(p_kid,a.ref,a.id,is_resolved,is_hidden,CASE WHEN is_hidden THEN 0 ELSE 1 END,now())
    ON CONFLICT(kid_id,question_ref) DO UPDATE SET
      last_attempt_id=EXCLUDED.last_attempt_id,resolved=EXCLUDED.resolved,hidden=EXCLUDED.hidden,
      review_count=public.learning_review_states.review_count + CASE
        WHEN is_hidden OR (public.learning_review_states.last_attempt_id=EXCLUDED.last_attempt_id
          AND public.learning_review_states.resolved=EXCLUDED.resolved
          AND public.learning_review_states.hidden=EXCLUDED.hidden) THEN 0 ELSE 1 END,
      reviewed_at=EXCLUDED.reviewed_at;
    n:=n+1;
  END LOOP;
  RETURN n;
END $$;

CREATE OR REPLACE FUNCTION public.wrong_answer_history(p_kid uuid,p_lesson uuid DEFAULT NULL,p_page integer DEFAULT 0)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.wrong_answer_history(p_kid,p_lesson,p_page); $$;
CREATE OR REPLACE FUNCTION public.set_wrong_answer_review(p_kid uuid,p_question text,p_action text,p_lesson uuid DEFAULT NULL)
RETURNS integer LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.set_wrong_answer_review(p_kid,p_question,p_action,p_lesson); $$;
REVOKE ALL ON FUNCTION private.wrong_answer_history(uuid,uuid,integer),public.wrong_answer_history(uuid,uuid,integer),
  private.set_wrong_answer_review(uuid,text,text,uuid),public.set_wrong_answer_review(uuid,text,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.wrong_answer_history(uuid,uuid,integer),public.wrong_answer_history(uuid,uuid,integer),
  private.set_wrong_answer_review(uuid,text,text,uuid),public.set_wrong_answer_review(uuid,text,text,uuid) TO authenticated;
COMMIT;
