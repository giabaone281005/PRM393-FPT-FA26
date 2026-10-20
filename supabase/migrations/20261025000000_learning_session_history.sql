BEGIN;

-- Existing server-graded sessions/attempts are the only history source.
CREATE OR REPLACE FUNCTION private.learning_session_history(
  p_kid uuid, p_kind text DEFAULT NULL, p_status text DEFAULT NULL, p_page integer DEFAULT 0
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb;
BEGIN
  PERFORM private.assert_learning_kid(p_kid);
  IF p_page IS NULL OR p_page NOT BETWEEN 0 AND 10000
    OR (p_kind IS NOT NULL AND p_kind NOT IN ('lesson','practice','arena'))
    OR (p_status IS NOT NULL AND p_status NOT IN ('unfinished','completed')) THEN
    RAISE EXCEPTION 'Bộ lọc lịch sử không hợp lệ';
  END IF;
  SELECT coalesce(jsonb_agg(row_data ORDER BY updated_at DESC,id DESC),'[]'::jsonb)
  INTO result FROM (
    SELECT s.id,s.updated_at,jsonb_build_object(
      'id',s.id,'kid_id',s.kid_id,'lesson_id',s.lesson_id,'kind',s.kind,'status',s.status,
      'title',coalesce(payload.content->>'title',l.title,CASE s.kind WHEN 'practice' THEN 'Vườn luyện tập' WHEN 'arena' THEN 'Thử thách đấu trường' ELSE 'Bài học' END),
      'started_at',s.started_at,'updated_at',s.updated_at,'duration_seconds',s.duration_seconds,
      'question_index',s.question_index,'question_count',coalesce(jsonb_array_length(payload.content->'questions'),0),
      'correct_count',(SELECT count(*) FROM public.question_attempts a WHERE a.session_id=s.id AND a.is_correct),
      'attempt_count',(SELECT count(*) FROM public.question_attempts a WHERE a.session_id=s.id),
      'accuracy_percent',s.accuracy_percent,'xp_earned',s.xp_earned,'stars_awarded',s.stars_awarded
    ) AS row_data
    FROM public.study_sessions s
    LEFT JOIN private.session_payloads payload ON payload.session_id=s.id
    LEFT JOIN public.lessons l ON l.id=s.lesson_id
    WHERE s.kid_id=p_kid AND (p_kind IS NULL OR s.kind=p_kind)
      AND (p_status IS NULL OR (p_status='completed' AND s.status='completed')
        OR (p_status='unfinished' AND s.status IN ('active','paused')))
    ORDER BY s.updated_at DESC,s.id DESC LIMIT 20 OFFSET p_page*20
  ) rows;
  RETURN result;
END $$;

CREATE OR REPLACE FUNCTION private.learning_session_review(p_session uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.study_sessions; content jsonb; attempts jsonb;
BEGIN
  PERFORM private.assert_session_access(p_session);
  SELECT * INTO s FROM public.study_sessions WHERE id=p_session;
  SELECT p.content INTO content FROM private.session_payloads p WHERE session_id=s.id;
  SELECT coalesce(jsonb_agg(jsonb_build_object(
    'id',a.id,'question_ref',coalesce(a.question_ref,a.question_id::text),
    'prompt',q.item->>'prompt','question_type',q.item->>'question_type',
    'answer',a.answer_value,'is_correct',a.is_correct,'hints_used',a.hints_used,
    'answered_at',a.answered_at,'hints',coalesce(q.item->'socratic_hints','[]'::jsonb)
  ) ORDER BY a.answered_at,a.id),'[]'::jsonb) INTO attempts
  FROM public.question_attempts a LEFT JOIN LATERAL (
    SELECT item FROM jsonb_array_elements(coalesce(content->'questions','[]'::jsonb)) item
    WHERE item->>'id'=coalesce(a.question_ref,a.question_id::text) LIMIT 1
  ) q ON true WHERE a.session_id=s.id;
  -- Deliberately return no payload, expected answer, essay key or reward controls.
  RETURN jsonb_build_object('session_id',s.id,'title',content->>'title','attempts',attempts);
END $$;

CREATE OR REPLACE FUNCTION private.resume_learning_session(p_session uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.study_sessions; other public.study_sessions; remaining integer;
BEGIN
  PERFORM private.assert_session_access(p_session);
  SELECT * INTO s FROM public.study_sessions WHERE id=p_session;
  PERFORM 1 FROM public.kid_profiles WHERE id=s.kid_id FOR UPDATE;
  SELECT * INTO s FROM public.study_sessions WHERE id=p_session FOR UPDATE;
  IF s.status NOT IN ('active','paused') THEN RAISE EXCEPTION 'Phiên đã kết thúc'; END IF;
  FOR other IN SELECT * FROM public.study_sessions
    WHERE kid_id=s.kid_id AND status='active' AND id<>s.id FOR UPDATE LOOP
    PERFORM private.charge_session(other.id,false);
    UPDATE public.study_sessions SET status='paused' WHERE id=other.id;
  END LOOP;
  remaining:=private.charge_session(s.id,false);
  IF remaining<=0 THEN RAISE EXCEPTION 'Đã hết thời gian học hôm nay'; END IF;
  UPDATE public.study_sessions SET status='active',last_active=true,
    last_heartbeat_at=clock_timestamp(),updated_at=clock_timestamp() WHERE id=s.id;
  RETURN private.session_public(s.id);
END $$;

CREATE OR REPLACE FUNCTION public.learning_session_history(
  p_kid uuid,p_kind text DEFAULT NULL,p_status text DEFAULT NULL,p_page integer DEFAULT 0
) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
  SELECT private.learning_session_history(p_kid,p_kind,p_status,p_page);
$$;
CREATE OR REPLACE FUNCTION public.learning_session_review(p_session uuid)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
  SELECT private.learning_session_review(p_session);
$$;
CREATE OR REPLACE FUNCTION public.resume_learning_session(p_session uuid)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
  SELECT private.resume_learning_session(p_session);
$$;
REVOKE ALL ON FUNCTION private.learning_session_history(uuid,text,text,integer),
  private.learning_session_review(uuid),private.resume_learning_session(uuid),
  public.learning_session_history(uuid,text,text,integer),public.learning_session_review(uuid),
  public.resume_learning_session(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.learning_session_history(uuid,text,text,integer),
  private.learning_session_review(uuid),private.resume_learning_session(uuid),
  public.learning_session_history(uuid,text,text,integer),public.learning_session_review(uuid),
  public.resume_learning_session(uuid) TO authenticated;
CREATE INDEX IF NOT EXISTS study_sessions_kid_history
  ON public.study_sessions(kid_id,updated_at DESC,id DESC);
COMMIT;
