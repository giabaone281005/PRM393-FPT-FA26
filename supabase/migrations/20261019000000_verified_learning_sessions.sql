BEGIN;
-- Parent authorization is bound to the authenticated session and held only in app memory.
CREATE TABLE private.parent_unlocks (
 token_hash text PRIMARY KEY, parent_id uuid NOT NULL REFERENCES public.parents(id) ON DELETE CASCADE,
 session_id text NOT NULL, expires_at timestamptz NOT NULL
);
CREATE INDEX parent_unlocks_parent ON private.parent_unlocks(parent_id,expires_at);
CREATE FUNCTION private.parent_authorized(p_token text) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT auth.uid() IS NOT NULL AND EXISTS(SELECT 1 FROM private.parent_unlocks
 WHERE parent_id=auth.uid() AND token_hash=encode(extensions.digest(coalesce(p_token,''),'sha256'),'hex')
 AND session_id=coalesce(auth.jwt()->>'session_id','') AND expires_at>now()); $$;
CREATE FUNCTION private.unlock_parent(p_pin text) RETURNS text
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE token text; BEGIN
 IF NOT private.verify_parent_pin(p_pin) THEN RETURN NULL; END IF;
 DELETE FROM private.parent_unlocks WHERE parent_id=auth.uid();
 token:=encode(extensions.gen_random_bytes(32),'hex');
 INSERT INTO private.parent_unlocks VALUES(encode(extensions.digest(token,'sha256'),'hex'),auth.uid(),coalesce(auth.jwt()->>'session_id',''),now()+interval '15 minutes');
 RETURN token; END $$;
CREATE FUNCTION private.lock_parent() RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$
 DELETE FROM private.parent_unlocks WHERE parent_id=auth.uid() AND session_id=coalesce(auth.jwt()->>'session_id',''); $$;

ALTER TABLE public.kid_profiles ADD COLUMN archived boolean NOT NULL DEFAULT false;
ALTER TABLE public.parents ADD COLUMN active_kid_id uuid REFERENCES public.kid_profiles(id) ON DELETE SET NULL;
UPDATE public.parents p SET active_kid_id=(SELECT k.id FROM public.kid_profiles k WHERE k.parent_id=p.id ORDER BY k.created_at,k.id LIMIT 1);
GRANT SELECT(active_kid_id) ON public.parents TO authenticated;
CREATE FUNCTION private.effective_entitlements() RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT jsonb_build_object('is_plus',coalesce(s.tier='plus' AND s.status='active' AND (s.expires_at IS NULL OR s.expires_at>now()),false),
 'max_kids',CASE WHEN s.tier='plus' AND s.status='active' AND (s.expires_at IS NULL OR s.expires_at>now()) THEN least(s.max_kids,3) ELSE 1 END,
 'active_kid_id',p.active_kid_id,'expires_at',s.expires_at,'server_time',now())
 FROM public.parents p LEFT JOIN public.subscriptions s ON s.parent_id=p.id WHERE p.id=auth.uid(); $$;
CREATE FUNCTION private.assert_learning_kid(p_kid uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE e jsonb; BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.kid_profiles WHERE id=p_kid AND parent_id=auth.uid() AND NOT archived) THEN RAISE EXCEPTION 'Không có quyền với hồ sơ'; END IF;
 e:=private.effective_entitlements();
 IF NOT (e->>'is_plus')::boolean AND (e->>'active_kid_id')::uuid IS DISTINCT FROM p_kid THEN RAISE EXCEPTION 'Nhờ phụ huynh chọn bé đang học cho gói Basic'; END IF;
END $$;
CREATE FUNCTION private.manage_kid(p_id uuid,p_name text,p_grade integer,p_archive boolean,p_token text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE k public.kid_profiles; BEGIN
 IF NOT private.parent_authorized(p_token) THEN RAISE EXCEPTION 'Cần mở cổng phụ huynh'; END IF;
 IF NOT coalesce(length(btrim(p_name)) BETWEEN 1 AND 40 AND p_grade BETWEEN 1 AND 5 AND p_archive IS NOT NULL,false) THEN RAISE EXCEPTION 'Biệt danh/lớp không hợp lệ'; END IF;
 PERFORM 1 FROM public.parents WHERE id=auth.uid() FOR UPDATE;
 IF p_id IS NULL THEN
 INSERT INTO public.kid_profiles(parent_id,nickname,grade) VALUES(auth.uid(),btrim(p_name),p_grade) RETURNING * INTO k;
 UPDATE public.parents SET active_kid_id=k.id WHERE id=auth.uid() AND active_kid_id IS NULL;
 ELSE
 SELECT * INTO k FROM public.kid_profiles WHERE id=p_id AND parent_id=auth.uid() FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Không tìm thấy bé'; END IF;
 IF p_archive AND (SELECT active_kid_id FROM public.parents WHERE id=auth.uid())=k.id THEN
 UPDATE public.parents SET active_kid_id=(SELECT id FROM public.kid_profiles WHERE parent_id=auth.uid() AND id<>k.id AND NOT archived ORDER BY created_at,id LIMIT 1) WHERE id=auth.uid(); END IF;
 IF NOT p_archive AND k.archived AND (SELECT count(*) FROM public.kid_profiles WHERE parent_id=auth.uid() AND NOT archived)>=(private.effective_entitlements()->>'max_kids')::integer THEN RAISE EXCEPTION 'Đã đạt số hồ sơ theo gói'; END IF;
 UPDATE public.kid_profiles SET nickname=btrim(p_name),grade=p_grade,archived=p_archive WHERE id=k.id RETURNING * INTO k;
 IF NOT p_archive THEN UPDATE public.parents SET active_kid_id=k.id WHERE id=auth.uid() AND active_kid_id IS NULL;END IF;
 END IF;
 RETURN to_jsonb(k);
END $$;
CREATE OR REPLACE FUNCTION public.check_max_kids_limit() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$
DECLARE allowed integer; BEGIN
 PERFORM 1 FROM public.parents WHERE id=NEW.parent_id FOR UPDATE;
 SELECT CASE WHEN tier='plus' AND status='active' AND (expires_at IS NULL OR expires_at>now()) THEN least(max_kids,3) ELSE 1 END
 INTO allowed FROM public.subscriptions WHERE parent_id=NEW.parent_id;
 IF (SELECT count(*) FROM public.kid_profiles WHERE parent_id=NEW.parent_id AND NOT archived AND id<>NEW.id)>=coalesce(allowed,1) THEN RAISE EXCEPTION 'Đã đạt số hồ sơ theo gói'; END IF;
 RETURN NEW; END $$;
CREATE FUNCTION private.set_active_kid(p_kid uuid,p_token text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT private.parent_authorized(p_token) THEN RAISE EXCEPTION 'Cần mở cổng phụ huynh'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.kid_profiles WHERE id=p_kid AND parent_id=auth.uid() AND NOT archived) THEN RAISE EXCEPTION 'Hồ sơ không hợp lệ'; END IF;
 UPDATE public.parents SET active_kid_id=p_kid WHERE id=auth.uid();
END $$;
CREATE FUNCTION private.set_screen_limit(p_kid uuid,p_minutes integer,p_token text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT private.parent_authorized(p_token) OR p_minutes IS NULL OR p_minutes NOT BETWEEN 15 AND 120 THEN RAISE EXCEPTION 'Không có quyền hoặc giới hạn không hợp lệ'; END IF;
 UPDATE public.kid_profiles SET screen_time_limit_minutes=p_minutes WHERE id=p_kid AND parent_id=auth.uid();
 IF NOT FOUND THEN RAISE EXCEPTION 'Không tìm thấy bé'; END IF;
END $$;
REVOKE INSERT,UPDATE,DELETE ON public.kid_profiles FROM PUBLIC,anon,authenticated;
REVOKE INSERT,UPDATE,DELETE ON public.study_sessions,public.question_attempts,public.practice_garden_logs FROM authenticated,anon;
REVOKE EXECUTE ON FUNCTION public.complete_kid_lesson(uuid,uuid,integer,integer) FROM authenticated;

ALTER TABLE public.topics ADD COLUMN published boolean NOT NULL DEFAULT true;
ALTER TABLE public.lessons ADD COLUMN published boolean NOT NULL DEFAULT true;
ALTER TABLE public.lessons ADD COLUMN content_version integer NOT NULL DEFAULT 1;
ALTER TABLE public.lessons ADD COLUMN essay_answer text;
-- Explicit answers for the five known legacy prompts. Never infer an answer from
-- the first intermediate calculation in essay_guidance.
UPDATE public.lessons SET essay_answer=CASE essay_prompt
 WHEN 'Trong rổ có 5 quả táo, mẹ cho thêm 3 quả táo nữa. Hỏi trong rổ có tất cả bao nhiêu quả táo?' THEN '8'
 WHEN 'Có 18 viên kẹo chia đều cho 2 bạn. Hỏi mỗi bạn nhận được bao nhiêu viên kẹo?' THEN '9'
 WHEN 'Một mảnh sân hình chữ nhật có chiều dài 12m, chiều rộng 8m. Tính chu vi của mảnh sân đó.' THEN '40'
 WHEN 'Trung bình cộng số tuổi của bố và con là 25 tuổi. Bố hơn con 30 tuổi. Tính tuổi của mỗi người.' THEN '40;10'
 WHEN 'Một ô tô đi quãng đường 150 km trong 3 giờ. Sau đó đi tiếp 100 km trong 2 giờ. Tính vận tốc trung bình của ô tô trên cả quãng đường.' THEN '50'
 ELSE NULL END;
UPDATE public.lessons SET essay_prompt=essay_prompt||' Nhập đáp số theo thứ tự tuổi bố;tuổi con, không có khoảng trắng (ví dụ 20;5).'
WHERE essay_answer='40;10';
ALTER TABLE public.practice_garden_logs ADD COLUMN session_id uuid UNIQUE REFERENCES public.study_sessions(id);
ALTER TABLE public.questions ADD COLUMN is_active boolean NOT NULL DEFAULT true;
ALTER TABLE public.study_sessions ADD COLUMN kind text NOT NULL DEFAULT 'lesson' CHECK(kind IN ('lesson','practice','arena'));
ALTER TABLE public.study_sessions ADD COLUMN status text NOT NULL DEFAULT 'completed' CHECK(status IN ('active','paused','completed','abandoned'));
ALTER TABLE public.study_sessions ADD COLUMN client_request_id uuid UNIQUE;
ALTER TABLE public.study_sessions ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();
ALTER TABLE public.study_sessions ADD COLUMN last_heartbeat_at timestamptz NOT NULL DEFAULT now();
ALTER TABLE public.study_sessions ADD COLUMN last_active boolean NOT NULL DEFAULT false;
ALTER TABLE public.study_sessions ADD COLUMN question_index integer NOT NULL DEFAULT 0;
ALTER TABLE public.study_sessions ADD COLUMN essay_passed boolean NOT NULL DEFAULT false;
ALTER TABLE public.study_sessions ADD COLUMN view_state jsonb NOT NULL DEFAULT '{}';
ALTER TABLE public.study_sessions ADD COLUMN content_version integer;
ALTER TABLE public.study_sessions ADD COLUMN fractional_seconds numeric NOT NULL DEFAULT 0;
ALTER TABLE public.study_sessions ADD COLUMN stars_awarded integer NOT NULL DEFAULT 0;
ALTER TABLE public.study_sessions ADD COLUMN accuracy_percent integer NOT NULL DEFAULT 0;
CREATE UNIQUE INDEX sessions_one_active_per_kid ON public.study_sessions(kid_id) WHERE status='active';
CREATE INDEX sessions_resume ON public.study_sessions(kid_id,lesson_id,kind,updated_at DESC);
ALTER TABLE public.question_attempts ALTER COLUMN question_id DROP NOT NULL;
ALTER TABLE public.question_attempts ADD COLUMN request_id uuid;
ALTER TABLE public.question_attempts ADD COLUMN question_ref text;
ALTER TABLE public.question_attempts ADD COLUMN answer_value jsonb;
CREATE UNIQUE INDEX attempts_request_unique ON public.question_attempts(session_id,request_id);
CREATE TABLE private.session_payloads(session_id uuid PRIMARY KEY REFERENCES public.study_sessions(id) ON DELETE CASCADE,content jsonb NOT NULL);
CREATE TABLE public.study_daily_usage(
 kid_id uuid NOT NULL REFERENCES public.kid_profiles(id) ON DELETE CASCADE,study_date date NOT NULL,total_seconds integer NOT NULL DEFAULT 0 CHECK(total_seconds>=0),PRIMARY KEY(kid_id,study_date));
ALTER TABLE public.study_daily_usage ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.study_daily_usage FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.study_daily_usage TO authenticated;
GRANT ALL ON public.study_daily_usage TO service_role;
CREATE POLICY usage_owner ON public.study_daily_usage FOR SELECT TO authenticated USING(EXISTS(SELECT 1 FROM public.kid_profiles k WHERE k.id=kid_id AND k.parent_id=(SELECT auth.uid())));
INSERT INTO public.study_daily_usage(kid_id,study_date,total_seconds)
SELECT kid_id,(started_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date,least(sum(duration_seconds),86400)::integer FROM public.study_sessions GROUP BY 1,2;

CREATE FUNCTION private.normal_answer(value text) RETURNS text LANGUAGE sql IMMUTABLE SET search_path='' AS $$
 SELECT lower(regexp_replace(replace(btrim(coalesce(value,'')),',','.'),'\s+',' ','g')); $$;
CREATE FUNCTION private.answer_equal(p_given text,p_expected text) RETURNS boolean LANGUAGE plpgsql IMMUTABLE SET search_path='' AS $$
DECLARE a text:=private.normal_answer(p_given);b text:=private.normal_answer(p_expected);an numeric;ad numeric;bn numeric;bd numeric;BEGIN
 IF a=b THEN RETURN true;END IF;
 IF length(a)>100 OR length(b)>100 THEN RETURN false;END IF;
 IF a ~ '^[+-]?[0-9]+([.][0-9]+)?(/[+-]?[0-9]+([.][0-9]+)?)?$' AND b ~ '^[+-]?[0-9]+([.][0-9]+)?(/[+-]?[0-9]+([.][0-9]+)?)?$' THEN
 an:=split_part(a,'/',1)::numeric;ad:=coalesce(nullif(split_part(a,'/',2),''),'1')::numeric;
 bn:=split_part(b,'/',1)::numeric;bd:=coalesce(nullif(split_part(b,'/',2),''),'1')::numeric;
 RETURN ad<>0 AND bd<>0 AND an*bd=bn*ad;
 END IF;RETURN false;END $$;
CREATE FUNCTION private.question_expected(q jsonb) RETURNS text LANGUAGE plpgsql IMMUTABLE SET search_path='' AS $$
DECLARE p jsonb:=q->'payload'; BEGIN
 IF q->>'question_type'='clock_rotation' THEN RETURN (p->>'targetHour')||':'||coalesce(p->>'targetMinute','0'); END IF;
 IF q->>'question_type'='drag_counters' THEN RETURN p->>'targetCount'; END IF;
 RETURN coalesce(p->>'correctAnswer',p->>'answer',CASE WHEN q->>'question_type'='area_grid' THEN ((coalesce(p->>'rows',p->>'gridHeight')::integer)*(coalesce(p->>'cols',p->>'gridWidth')::integer))::text END);
END $$;
CREATE FUNCTION private.charge_session(p_session uuid,p_active boolean) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.study_sessions; day date; a timestamptz; b timestamptz:=clock_timestamp(); overlap_seconds integer; budget integer; used integer; charged integer:=0; carry numeric; elapsed numeric;
BEGIN
 SELECT * INTO s FROM public.study_sessions WHERE id=p_session FOR UPDATE;
 carry:=s.fractional_seconds;
 SELECT screen_time_limit_minutes*60 INTO budget FROM public.kid_profiles WHERE id=s.kid_id;
 IF s.last_active AND s.status='active' AND b-s.last_heartbeat_at BETWEEN interval '0 seconds' AND interval '45 seconds' THEN
 a:=s.last_heartbeat_at;
 FOR day IN SELECT d::date FROM generate_series((a AT TIME ZONE 'Asia/Ho_Chi_Minh')::date::timestamp,(b AT TIME ZONE 'Asia/Ho_Chi_Minh')::date::timestamp,interval '1 day') d LOOP
 elapsed:=greatest(0,extract(epoch FROM least(b,(day+1)::timestamp AT TIME ZONE 'Asia/Ho_Chi_Minh')-greatest(a,day::timestamp AT TIME ZONE 'Asia/Ho_Chi_Minh')))+carry;
 overlap_seconds:=floor(elapsed)::integer; carry:=elapsed-overlap_seconds;
 INSERT INTO public.study_daily_usage(kid_id,study_date,total_seconds) VALUES(s.kid_id,day,0) ON CONFLICT DO NOTHING;
 SELECT total_seconds INTO used FROM public.study_daily_usage WHERE kid_id=s.kid_id AND study_date=day FOR UPDATE;
 overlap_seconds:=least(overlap_seconds,greatest(0,budget-used));
 UPDATE public.study_daily_usage SET total_seconds=total_seconds+overlap_seconds WHERE kid_id=s.kid_id AND study_date=day;
 charged:=charged+overlap_seconds;
 END LOOP;
 END IF;
 SELECT coalesce(total_seconds,0) INTO used FROM public.study_daily_usage WHERE kid_id=s.kid_id AND study_date=(b AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
 UPDATE public.study_sessions SET duration_seconds=duration_seconds+charged,last_heartbeat_at=b,fractional_seconds=carry,
 last_active=p_active AND coalesce(used,0)<budget,updated_at=b WHERE id=p_session;
 RETURN greatest(0,budget-coalesce(used,0));
END $$;
CREATE FUNCTION private.assert_session_access(p_session uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.study_sessions; BEGIN
 SELECT * INTO s FROM public.study_sessions WHERE id=p_session;
 IF NOT FOUND THEN RAISE EXCEPTION 'Không tìm thấy phiên'; END IF;
 PERFORM private.assert_learning_kid(s.kid_id);
 IF s.kind='lesson' AND EXISTS(SELECT 1 FROM public.lessons WHERE id=s.lesson_id AND (NOT published OR (access_tier='plus' AND NOT (private.effective_entitlements()->>'is_plus')::boolean))) THEN RAISE EXCEPTION 'Bài học chưa khả dụng theo gói hiện tại'; END IF;
END $$;
CREATE FUNCTION private.session_public(p_session uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.study_sessions; c jsonb; result jsonb; BEGIN
 SELECT * INTO s FROM public.study_sessions WHERE id=p_session;
 SELECT content INTO c FROM private.session_payloads WHERE session_id=s.id;
 SELECT jsonb_agg(q || jsonb_build_object('payload',((q->'payload')-'correctAnswer'-'answer')||CASE WHEN jsonb_typeof(q->'payload'->'options')='array' THEN jsonb_build_object('options',(SELECT jsonb_agg(opt ORDER BY md5(opt::text||(q->>'id'))) FROM jsonb_array_elements(q->'payload'->'options') opt)) ELSE '{}' END,'expected',NULL) ORDER BY ord) INTO result FROM jsonb_array_elements(c->'questions') WITH ORDINALITY AS j(q,ord);
 RETURN to_jsonb(s)||jsonb_build_object('title',c->>'title','theory',c->>'theory','essay_prompt',c->>'essay_prompt',
 'essay_required',nullif(c->>'essay_answer','') IS NOT NULL,'questions',coalesce(result,'[]'),
 'hearts',(SELECT current_hearts FROM public.kid_profiles WHERE id=s.kid_id),
 'offline_until',least(now()+interval '15 minutes',((now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date+1)::timestamp AT TIME ZONE 'Asia/Ho_Chi_Minh',coalesce((SELECT expires_at FROM public.subscriptions WHERE parent_id=auth.uid() AND tier='plus'),'infinity'::timestamptz)),
 'remaining_seconds',greatest(0,(SELECT screen_time_limit_minutes*60 FROM public.kid_profiles WHERE id=s.kid_id)-coalesce((SELECT total_seconds FROM public.study_daily_usage WHERE kid_id=s.kid_id AND study_date=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date),0)));
END $$;

CREATE FUNCTION private.start_learning_session(p_kid uuid,p_lesson uuid,p_kind text,p_request uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.study_sessions; l public.lessons; questions jsonb; c jsonb; a integer; b integer; n integer; grade integer; type text; expected text; payload jsonb;
BEGIN
 PERFORM private.assert_learning_kid(p_kid);
 PERFORM 1 FROM public.kid_profiles WHERE id=p_kid FOR UPDATE;
 IF p_kind IS NULL OR p_request IS NULL OR p_kind NOT IN ('lesson','practice','arena') THEN RAISE EXCEPTION 'Loại phiên không hợp lệ'; END IF;
 IF EXISTS(SELECT 1 FROM public.study_daily_usage u JOIN public.kid_profiles k ON k.id=u.kid_id WHERE u.kid_id=p_kid AND study_date=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AND total_seconds>=k.screen_time_limit_minutes*60) THEN RAISE EXCEPTION 'Đã hết thời gian học hôm nay'; END IF;
 SELECT * INTO s FROM public.study_sessions WHERE client_request_id=p_request;
 IF FOUND THEN IF s.kid_id<>p_kid OR s.kind<>p_kind OR s.lesson_id IS DISTINCT FROM p_lesson THEN RAISE EXCEPTION 'Mã phiên không hợp lệ'; END IF; PERFORM private.assert_session_access(s.id); IF s.status<>'paused' THEN RETURN private.session_public(s.id); END IF; END IF;
 FOR s IN SELECT * FROM public.study_sessions WHERE kid_id=p_kid AND status='active' FOR UPDATE LOOP
 PERFORM private.charge_session(s.id,false);
 UPDATE public.study_sessions SET status='paused' WHERE id=s.id;
 END LOOP;
 SELECT * INTO s FROM public.study_sessions WHERE kid_id=p_kid AND kind=p_kind AND lesson_id IS NOT DISTINCT FROM p_lesson AND status='paused' ORDER BY updated_at DESC LIMIT 1 FOR UPDATE;
 IF FOUND THEN PERFORM private.assert_session_access(s.id); UPDATE public.study_sessions SET status='active',last_heartbeat_at=now(),last_active=true WHERE id=s.id; RETURN private.session_public(s.id); END IF;
 IF p_kind='arena' AND (SELECT count(*) FROM public.study_sessions WHERE kid_id=p_kid AND kind='arena' AND status='completed' AND (started_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date)>=5 THEN RAISE EXCEPTION 'Đã hoàn thành 5 thử thách hôm nay';END IF;
 IF p_kind='lesson' THEN
 SELECT lessons.* INTO l FROM public.lessons JOIN public.topics t ON t.id=topic_id JOIN public.kid_profiles k ON k.grade=t.grade WHERE lessons.id=p_lesson AND k.id=p_kid AND lessons.published AND t.published;
 IF NOT FOUND THEN RAISE EXCEPTION 'Bài học chưa được xuất bản'; END IF;
 IF l.access_tier='plus' AND NOT (private.effective_entitlements()->>'is_plus')::boolean THEN RAISE EXCEPTION 'Cần gói Plus'; END IF;
 IF EXISTS(SELECT 1 FROM public.lessons prev WHERE prev.topic_id=l.topic_id AND prev.published AND prev.order_index<l.order_index AND NOT EXISTS(SELECT 1 FROM public.kid_progress p WHERE p.kid_id=p_kid AND p.lesson_id=prev.id AND p.is_completed)) THEN RAISE EXCEPTION 'Hãy hoàn thành các bài trước'; END IF;
 SELECT jsonb_agg(to_jsonb(q) ORDER BY order_index) INTO questions FROM public.questions q WHERE q.lesson_id=l.id AND q.is_active;
 IF coalesce(jsonb_array_length(questions),0)=0 THEN RAISE EXCEPTION 'Bài học chưa có câu hỏi'; END IF;
 c:=jsonb_build_object('title',l.title,'theory',l.theory,'essay_prompt',l.essay_prompt,'essay_answer',l.essay_answer,'questions',questions,'star_reward',l.star_reward,'xp_reward',l.xp_reward);
 ELSE
 questions:='[]'; SELECT k.grade INTO grade FROM public.kid_profiles k WHERE k.id=p_kid;
 FOR n IN 1..5 LOOP
 a:=1+floor(random()*(grade*5+5))::integer; b:=1+floor(random()*9)::integer;
 type:=CASE WHEN grade>=3 AND n%2=0 THEN 'multiplication_table' ELSE 'word_problem' END;
 expected:=CASE WHEN grade>=3 AND n%2=0 THEN (a*b)::text ELSE (a+b)::text END;
 payload:=jsonb_build_object('options',jsonb_build_array(expected,(expected::integer+1)::text,(expected::integer+2)::text,(greatest(0,expected::integer-1))::text),'correctAnswer',expected);
 questions:=questions||jsonb_build_array(jsonb_build_object('id',pg_catalog.gen_random_uuid(),'question_type',type,'prompt',a||CASE WHEN grade>=3 AND n%2=0 THEN ' × ' ELSE ' + ' END||b||' = ?','payload',payload,'socratic_hints',jsonb_build_array(jsonb_build_object('question_text','Em có thể tách phép tính thành các bước nhỏ nào?','hint_text','Dùng que tính hoặc nhóm bằng nhau để kiểm tra.'))));
 END LOOP;
 c:=jsonb_build_object('title',CASE WHEN p_kind='practice' THEN 'Vườn luyện tập' ELSE 'Thử thách đấu trường' END,'questions',questions);
 END IF;
 INSERT INTO public.study_sessions(kid_id,lesson_id,kind,status,client_request_id,last_active,content_version)
 VALUES(p_kid,CASE WHEN p_kind='lesson' THEN p_lesson END,p_kind,'active',p_request,true,l.content_version) RETURNING * INTO s;
 INSERT INTO private.session_payloads VALUES(s.id,c);
 RETURN private.session_public(s.id);
END $$;
CREATE FUNCTION private.heartbeat_learning_session(p_session uuid,p_active boolean,p_state jsonb) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE kid uuid; BEGIN
 SELECT kid_id INTO kid FROM public.study_sessions WHERE id=p_session;
 PERFORM private.assert_session_access(p_session); PERFORM 1 FROM public.kid_profiles WHERE id=kid FOR UPDATE;
 IF length(p_state::text)>4096 THEN RAISE EXCEPTION 'Trạng thái quá lớn'; END IF;
 PERFORM private.charge_session(p_session,p_active);
 UPDATE public.study_sessions SET view_state=p_state WHERE id=p_session;
 RETURN private.session_public(p_session);
END $$;
CREATE FUNCTION private.answer_learning_session(p_session uuid,p_question text,p_value jsonb,p_request uuid,p_hints integer) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.study_sessions; q jsonb; correct boolean; a public.question_attempts; expected text; given text; remaining integer;
BEGIN
 SELECT * INTO s FROM public.study_sessions WHERE id=p_session;
 PERFORM private.assert_session_access(s.id); PERFORM 1 FROM public.kid_profiles WHERE id=s.kid_id FOR UPDATE;
 SELECT * INTO s FROM public.study_sessions WHERE id=p_session FOR UPDATE;
 SELECT * INTO a FROM public.question_attempts WHERE session_id=s.id AND request_id=p_request;
 IF FOUND THEN RETURN private.session_public(s.id)||jsonb_build_object('correct',a.is_correct); END IF;
 IF s.status<>'active' THEN RAISE EXCEPTION 'Phiên không hoạt động'; END IF;
 remaining:=private.charge_session(s.id,true); IF remaining<=0 THEN RETURN private.session_public(s.id)||jsonb_build_object('time_limit',true); END IF;
 IF s.kind='lesson' AND (SELECT current_hearts FROM public.kid_profiles WHERE id=s.kid_id)<=0 THEN RETURN private.session_public(s.id)||jsonb_build_object('out_of_hearts',true); END IF;
 SELECT content->'questions'->s.question_index INTO q FROM private.session_payloads WHERE session_id=s.id;
 IF q IS NULL THEN RAISE EXCEPTION 'Đã trả lời hết câu hỏi'; END IF;
 IF p_question IS DISTINCT FROM q->>'id' THEN RAISE EXCEPTION 'Câu hỏi đã thay đổi. Tải lại phiên để tiếp tục.'; END IF;
 expected:=private.question_expected(q);
 given:=CASE WHEN jsonb_typeof(p_value)='object' THEN (p_value->>'hour')||':'||(p_value->>'minute') ELSE p_value#>>'{}' END;
 correct:=private.answer_equal(given,expected);
 INSERT INTO public.question_attempts(session_id,question_id,question_ref,is_correct,hints_used,request_id,answer_value)
 VALUES(s.id,CASE WHEN s.kind='lesson' THEN (q->>'id')::uuid END,q->>'id',coalesce(correct,false),least(greatest(p_hints,0),10),p_request,p_value);
 IF correct OR s.kind='arena' THEN UPDATE public.study_sessions SET question_index=question_index+1 WHERE id=s.id;
 ELSIF s.kind='lesson' THEN UPDATE public.kid_profiles SET current_hearts=greatest(0,current_hearts-1) WHERE id=s.kid_id;
 UPDATE public.study_sessions SET hearts_lost=hearts_lost+1 WHERE id=s.id; END IF;
 RETURN private.session_public(s.id)||jsonb_build_object('correct',coalesce(correct,false));
END $$;
CREATE FUNCTION private.submit_learning_essay(p_session uuid,p_result text,p_solution text) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE s public.study_sessions; expected text; valid boolean; BEGIN
 SELECT * INTO s FROM public.study_sessions WHERE id=p_session;
 PERFORM private.assert_session_access(s.id); PERFORM 1 FROM public.kid_profiles WHERE id=s.kid_id FOR UPDATE;
 IF s.status<>'active' OR length(p_solution) NOT BETWEEN 5 AND 3000 OR length(p_result)>200 THEN RETURN false; END IF;
 IF private.charge_session(s.id,true)<=0 THEN RETURN false; END IF;
 SELECT content->>'essay_answer' INTO expected FROM private.session_payloads WHERE session_id=s.id;
 valid:=nullif(expected,'') IS NULL OR private.answer_equal(p_result,expected);
 UPDATE public.study_sessions SET essay_passed=valid,view_state=view_state||jsonb_build_object('essay_result',p_result,'essay_solution',p_solution) WHERE id=s.id;
 RETURN valid;
END $$;
-- Economy migration replaces this hook with atomic group scoring.
CREATE FUNCTION private.award_arena_session(p_session uuid,p_xp integer) RETURNS void LANGUAGE plpgsql SET search_path='' AS $$ BEGIN RETURN; END $$;
CREATE FUNCTION private.finish_learning_session(p_session uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.study_sessions; c jsonb; correct integer; total integer; accuracy integer; already boolean; stars integer:=0; xp integer:=0; restored integer; day date; previous date; streak integer;
BEGIN
 SELECT * INTO s FROM public.study_sessions WHERE id=p_session;
 PERFORM private.assert_session_access(s.id); PERFORM 1 FROM public.kid_profiles WHERE id=s.kid_id FOR UPDATE;
 SELECT * INTO s FROM public.study_sessions WHERE id=p_session FOR UPDATE;
 IF s.status='completed' THEN RETURN private.session_public(s.id); END IF;
 PERFORM private.charge_session(s.id,false);
 SELECT content INTO c FROM private.session_payloads WHERE session_id=s.id;
 IF s.question_index<jsonb_array_length(c->'questions') THEN RAISE EXCEPTION 'Chưa hoàn thành câu hỏi'; END IF;
 IF s.kind='lesson' AND nullif(c->>'essay_answer','') IS NOT NULL AND NOT s.essay_passed THEN RAISE EXCEPTION 'Chưa hoàn thành tự luận'; END IF;
 SELECT count(*) FILTER(WHERE is_correct),count(*) INTO correct,total FROM public.question_attempts WHERE session_id=s.id;
 accuracy:=CASE WHEN total=0 THEN 0 ELSE round(correct*100.0/total)::integer END;
 IF s.kind='lesson' THEN
 SELECT coalesce(bool_or(is_completed),false) INTO already FROM public.kid_progress WHERE kid_id=s.kid_id AND lesson_id=s.lesson_id;
 IF NOT already THEN stars:=(c->>'star_reward')::integer; xp:=(c->>'xp_reward')::integer; END IF;
 INSERT INTO public.kid_progress(kid_id,lesson_id,is_completed,accuracy_percent,stars_earned,attempts_count,completed_at)
 VALUES(s.kid_id,s.lesson_id,true,accuracy,stars,1,now()) ON CONFLICT(kid_id,lesson_id) DO UPDATE
 SET is_completed=true,accuracy_percent=greatest(public.kid_progress.accuracy_percent,EXCLUDED.accuracy_percent),stars_earned=greatest(public.kid_progress.stars_earned,EXCLUDED.stars_earned),attempts_count=public.kid_progress.attempts_count+1,completed_at=coalesce(public.kid_progress.completed_at,now());
 ELSIF s.kind='practice' THEN
 SELECT max_hearts-current_hearts INTO restored FROM public.kid_profiles WHERE id=s.kid_id;
 UPDATE public.kid_profiles SET current_hearts=max_hearts WHERE id=s.kid_id;
 INSERT INTO public.practice_garden_logs(kid_id,hearts_restored,math_drills_completed,session_id) VALUES(s.kid_id,restored,5,s.id);
 ELSE xp:=correct*30+10; stars:=xp/10; PERFORM private.award_arena_session(s.id,xp);
 END IF;
 UPDATE public.kid_profiles SET energy_stars=energy_stars+stars WHERE id=s.kid_id;
 IF (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::time<'21:00'::time THEN
 day:=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
 SELECT last_activity_date,streak_count INTO previous,streak FROM public.kid_streaks WHERE kid_id=s.kid_id;
 IF previous IS DISTINCT FROM day THEN INSERT INTO public.kid_streaks(kid_id,streak_count,last_activity_date) VALUES(s.kid_id,CASE WHEN previous=day-1 THEN streak+1 ELSE 1 END,day)
 ON CONFLICT(kid_id) DO UPDATE SET streak_count=EXCLUDED.streak_count,last_activity_date=EXCLUDED.last_activity_date; END IF; END IF;
 UPDATE public.study_sessions SET status='completed',last_active=false,xp_earned=xp,stars_awarded=stars,accuracy_percent=accuracy,updated_at=now() WHERE id=s.id;
 RETURN private.session_public(s.id)||jsonb_build_object('accuracy',accuracy,'stars_awarded',stars,'xp_awarded',xp);
END $$;

CREATE OR REPLACE FUNCTION private.get_kid_curriculum(p_kid uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_grade integer; result jsonb; BEGIN
 SELECT grade INTO v_grade FROM public.kid_profiles WHERE id=p_kid AND parent_id=auth.uid() AND NOT archived;
 IF NOT FOUND THEN RAISE EXCEPTION 'Không có quyền'; END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',l.id,'lesson_number',l.lesson_number,'title',l.title,'subtitle',l.subtitle,'estimated_minutes',l.estimated_minutes,
 'xp_reward',l.xp_reward,'star_reward',l.star_reward,'access_tier',l.access_tier,'content_version',l.content_version,'is_completed',coalesce(p.is_completed,false),'stars_earned',coalesce(p.stars_earned,0),
 'topic_id',l.topic_id,'topic_title',t.title,'can_start',NOT EXISTS(SELECT 1 FROM public.lessons prev WHERE prev.topic_id=l.topic_id AND prev.published AND prev.order_index<l.order_index AND NOT EXISTS(SELECT 1 FROM public.kid_progress kp WHERE kp.kid_id=p_kid AND kp.lesson_id=prev.id AND kp.is_completed)),
 'questions','[]'::jsonb,'theory',NULL,'essay_prompt',NULL,'essay_guidance',NULL) ORDER BY t.topic_number,l.order_index),'[]') INTO result
 FROM public.lessons l JOIN public.topics t ON t.id=l.topic_id LEFT JOIN public.kid_progress p ON p.lesson_id=l.id AND p.kid_id=p_kid WHERE t.grade=v_grade AND t.published AND l.published;
 RETURN result; END $$;

-- Wrappers and narrow EXECUTE grants are generated below; private tables have no client grants.

REVOKE ALL ON FUNCTION private.parent_authorized(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.parent_authorized(text) TO authenticated;
CREATE FUNCTION public.parent_authorized(p_token text) RETURNS boolean LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.parent_authorized(p_token); $$;
REVOKE ALL ON FUNCTION public.parent_authorized(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.parent_authorized(text) TO authenticated;
REVOKE ALL ON FUNCTION private.unlock_parent(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.unlock_parent(text) TO authenticated;
CREATE FUNCTION public.unlock_parent(p_pin text) RETURNS text LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.unlock_parent(p_pin); $$;
REVOKE ALL ON FUNCTION public.unlock_parent(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.unlock_parent(text) TO authenticated;
REVOKE ALL ON FUNCTION private.lock_parent() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.lock_parent() TO authenticated;
CREATE FUNCTION public.lock_parent() RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.lock_parent(); $$;
REVOKE ALL ON FUNCTION public.lock_parent() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.lock_parent() TO authenticated;
REVOKE ALL ON FUNCTION private.effective_entitlements() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.effective_entitlements() TO authenticated;
CREATE FUNCTION public.effective_entitlements() RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.effective_entitlements(); $$;
REVOKE ALL ON FUNCTION public.effective_entitlements() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.effective_entitlements() TO authenticated;
REVOKE ALL ON FUNCTION private.manage_kid(uuid,text,integer,boolean,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.manage_kid(uuid,text,integer,boolean,text) TO authenticated;
CREATE FUNCTION public.manage_kid(p_id uuid,p_name text,p_grade integer,p_archive boolean,p_token text) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.manage_kid(p_id,p_name,p_grade,p_archive,p_token); $$;
REVOKE ALL ON FUNCTION public.manage_kid(uuid,text,integer,boolean,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.manage_kid(uuid,text,integer,boolean,text) TO authenticated;
REVOKE ALL ON FUNCTION private.set_active_kid(uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.set_active_kid(uuid,text) TO authenticated;
CREATE FUNCTION public.set_active_kid(p_kid uuid,p_token text) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.set_active_kid(p_kid,p_token); $$;
REVOKE ALL ON FUNCTION public.set_active_kid(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.set_active_kid(uuid,text) TO authenticated;
REVOKE ALL ON FUNCTION private.set_screen_limit(uuid,integer,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.set_screen_limit(uuid,integer,text) TO authenticated;
CREATE FUNCTION public.set_screen_limit(p_kid uuid,p_minutes integer,p_token text) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.set_screen_limit(p_kid,p_minutes,p_token); $$;
REVOKE ALL ON FUNCTION public.set_screen_limit(uuid,integer,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.set_screen_limit(uuid,integer,text) TO authenticated;
REVOKE ALL ON FUNCTION private.start_learning_session(uuid,uuid,text,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.start_learning_session(uuid,uuid,text,uuid) TO authenticated;
CREATE FUNCTION public.start_learning_session(p_kid uuid,p_lesson uuid,p_kind text,p_request uuid) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.start_learning_session(p_kid,p_lesson,p_kind,p_request); $$;
REVOKE ALL ON FUNCTION public.start_learning_session(uuid,uuid,text,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.start_learning_session(uuid,uuid,text,uuid) TO authenticated;
REVOKE ALL ON FUNCTION private.heartbeat_learning_session(uuid,boolean,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.heartbeat_learning_session(uuid,boolean,jsonb) TO authenticated;
CREATE FUNCTION public.heartbeat_learning_session(p_session uuid,p_active boolean,p_state jsonb) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.heartbeat_learning_session(p_session,p_active,p_state); $$;
REVOKE ALL ON FUNCTION public.heartbeat_learning_session(uuid,boolean,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.heartbeat_learning_session(uuid,boolean,jsonb) TO authenticated;
REVOKE ALL ON FUNCTION private.answer_learning_session(uuid,text,jsonb,uuid,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.answer_learning_session(uuid,text,jsonb,uuid,integer) TO authenticated;
CREATE FUNCTION public.answer_learning_session(p_session uuid,p_question text,p_value jsonb,p_request uuid,p_hints integer) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.answer_learning_session(p_session,p_question,p_value,p_request,p_hints); $$;
REVOKE ALL ON FUNCTION public.answer_learning_session(uuid,text,jsonb,uuid,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.answer_learning_session(uuid,text,jsonb,uuid,integer) TO authenticated;
REVOKE ALL ON FUNCTION private.submit_learning_essay(uuid,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.submit_learning_essay(uuid,text,text) TO authenticated;
CREATE FUNCTION public.submit_learning_essay(p_session uuid,p_result text,p_solution text) RETURNS boolean LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.submit_learning_essay(p_session,p_result,p_solution); $$;
REVOKE ALL ON FUNCTION public.submit_learning_essay(uuid,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.submit_learning_essay(uuid,text,text) TO authenticated;
REVOKE ALL ON FUNCTION private.finish_learning_session(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.finish_learning_session(uuid) TO authenticated;
CREATE FUNCTION public.finish_learning_session(p_session uuid) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.finish_learning_session(p_session); $$;
REVOKE ALL ON FUNCTION public.finish_learning_session(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.finish_learning_session(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION private.complete_kid_lesson(uuid,uuid,integer,integer),private.create_learning_order(uuid,uuid),public.create_learning_order(uuid,uuid) FROM authenticated;
CREATE FUNCTION private.create_parent_order(p_price uuid,p_key uuid,p_token text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT private.parent_authorized(p_token) THEN RAISE EXCEPTION 'Cần xác thực phụ huynh'; END IF;
 RETURN to_jsonb(private.create_learning_order(p_price,p_key)); END $$;
REVOKE ALL ON FUNCTION private.create_parent_order(uuid,uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.create_parent_order(uuid,uuid,text) TO authenticated;
CREATE FUNCTION public.create_learning_order(p_price uuid,p_key uuid,p_token text) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.create_parent_order(p_price,p_key,p_token); $$;
REVOKE ALL ON FUNCTION public.create_learning_order(uuid,uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.create_learning_order(uuid,uuid,text) TO authenticated;
COMMIT;
