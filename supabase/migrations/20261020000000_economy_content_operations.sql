BEGIN;
CREATE TABLE public.admin_audit_logs(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),actor_id uuid,action text NOT NULL,target_type text NOT NULL,target_id text,details jsonb NOT NULL DEFAULT '{}',created_at timestamptz NOT NULL DEFAULT now());
CREATE INDEX audit_time ON public.admin_audit_logs(created_at DESC);
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.admin_audit_logs FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.admin_audit_logs TO authenticated; GRANT ALL ON public.admin_audit_logs TO service_role;
CREATE POLICY audit_admin_read ON public.admin_audit_logs FOR SELECT TO authenticated USING(public.is_admin());
CREATE FUNCTION private.is_staff() RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT auth.uid() IS NOT NULL AND EXISTS(SELECT 1 FROM public.user_roles WHERE user_id=auth.uid() AND role IN ('admin','moderator')); $$;
CREATE FUNCTION private.audit(p_action text,p_type text,p_target text,p_details jsonb) RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$
 INSERT INTO public.admin_audit_logs(actor_id,action,target_type,target_id,details) VALUES(auth.uid(),p_action,p_type,p_target,p_details); $$;
CREATE FUNCTION private.audit_catalog() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 PERFORM private.audit(TG_OP,TG_TABLE_NAME,NEW.id::text,jsonb_build_object('before',CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END,'after',to_jsonb(NEW))); RETURN NEW; END $$;
CREATE TRIGGER catalog_audit AFTER INSERT OR UPDATE ON public.learning_plans FOR EACH ROW EXECUTE FUNCTION private.audit_catalog();
CREATE TRIGGER price_audit AFTER INSERT OR UPDATE ON public.plan_prices FOR EACH ROW EXECUTE FUNCTION private.audit_catalog();
CREATE TABLE public.notifications(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),parent_id uuid NOT NULL REFERENCES public.parents(id) ON DELETE CASCADE,title text NOT NULL,body text NOT NULL,kind text NOT NULL,dedupe_key text NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),read_at timestamptz,UNIQUE(parent_id,dedupe_key));
CREATE INDEX notifications_parent_time ON public.notifications(parent_id,created_at DESC);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.notifications FROM PUBLIC,anon,authenticated;
GRANT SELECT,UPDATE(read_at) ON public.notifications TO authenticated; GRANT ALL ON public.notifications TO service_role;
CREATE POLICY notifications_owner_read ON public.notifications FOR SELECT TO authenticated USING(parent_id=(SELECT auth.uid()));
CREATE POLICY notifications_owner_update ON public.notifications FOR UPDATE TO authenticated USING(parent_id=(SELECT auth.uid())) WITH CHECK(parent_id=(SELECT auth.uid()));
CREATE FUNCTION private.notify_purchase() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NEW.status='paid' AND OLD.status IS DISTINCT FROM NEW.status THEN
 INSERT INTO public.notifications(parent_id,title,body,kind,dedupe_key) VALUES(NEW.parent_id,'Gói học đã được kích hoạt','Thanh toán đã được xác minh. Bạn có thể quay lại bài học.','purchase','paid:'||NEW.id) ON CONFLICT DO NOTHING; END IF; RETURN NEW; END $$;
CREATE TRIGGER notify_purchase AFTER UPDATE ON public.learning_orders FOR EACH ROW EXECUTE FUNCTION private.notify_purchase();

-- Inventory/equipment is authoritative; avatar_id remains a compatibility projection.
INSERT INTO public.kid_inventory(kid_id,item_id) SELECT k.id,i.id FROM public.kid_profiles k CROSS JOIN public.mascot_items i
WHERE i.price_stars=0 OR i.name=split_part(k.avatar_id,'|',1) OR i.name=split_part(k.avatar_id,'|',2) ON CONFLICT DO NOTHING;
INSERT INTO public.kid_equipment(kid_id,hat_id,glasses_id) SELECT id,'hat_detective','glasses_wisdom' FROM public.kid_profiles ON CONFLICT DO NOTHING;
UPDATE public.kid_equipment e SET hat_id=coalesce((SELECT i.id FROM public.mascot_items i JOIN public.kid_profiles k ON k.id=e.kid_id WHERE i.slot='hat' AND i.name=split_part(k.avatar_id,'|',1)),e.hat_id),glasses_id=coalesce((SELECT i.id FROM public.mascot_items i JOIN public.kid_profiles k ON k.id=e.kid_id WHERE i.slot='glasses' AND i.name=split_part(k.avatar_id,'|',2)),e.glasses_id);
REVOKE INSERT,UPDATE,DELETE ON public.kid_inventory,public.kid_equipment FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.purchase_item(uuid,text) FROM PUBLIC,anon,authenticated;
CREATE FUNCTION private.get_wardrobe(p_kid uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.kid_profiles WHERE id=p_kid AND parent_id=auth.uid()) THEN RAISE EXCEPTION 'Không có quyền'; END IF;
 RETURN jsonb_build_object('stars',(SELECT energy_stars FROM public.kid_profiles WHERE id=p_kid),'hat',coalesce((SELECT i.name FROM public.kid_equipment e JOIN public.mascot_items i ON i.id=e.hat_id WHERE e.kid_id=p_kid),'Mũ Thám Tử'),
 'glasses',coalesce((SELECT i.name FROM public.kid_equipment e JOIN public.mascot_items i ON i.id=e.glasses_id WHERE e.kid_id=p_kid),'Kính Tri Thức'),
 'items',(SELECT coalesce(jsonb_agg(to_jsonb(i)||jsonb_build_object('owned',EXISTS(SELECT 1 FROM public.kid_inventory v WHERE v.kid_id=p_kid AND v.item_id=i.id) OR i.price_stars=0,'equipped',EXISTS(SELECT 1 FROM public.kid_equipment e WHERE e.kid_id=p_kid AND (e.hat_id=i.id OR e.glasses_id=i.id))) ORDER BY i.slot,i.price_stars),'[]') FROM public.mascot_items i WHERE i.is_active OR EXISTS(SELECT 1 FROM public.kid_inventory v WHERE v.kid_id=p_kid AND v.item_id=i.id)));
END $$;
CREATE FUNCTION private.buy_equip_item(p_kid uuid,p_item text,p_buy boolean) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE item public.mascot_items; balance integer; owned boolean; BEGIN
 PERFORM private.assert_learning_kid(p_kid);
 SELECT energy_stars INTO balance FROM public.kid_profiles WHERE id=p_kid FOR UPDATE;
 SELECT * INTO item FROM public.mascot_items WHERE id=p_item;
 IF NOT FOUND THEN RAISE EXCEPTION 'Món đồ không tồn tại'; END IF;
 SELECT EXISTS(SELECT 1 FROM public.kid_inventory WHERE kid_id=p_kid AND item_id=p_item) INTO owned;
 IF NOT owned THEN
 IF NOT item.is_active OR (NOT p_buy AND item.price_stars>0) THEN RAISE EXCEPTION 'Bé chưa sở hữu món đồ'; END IF;
 IF balance<item.price_stars THEN RAISE EXCEPTION 'Bé chưa đủ sao'; END IF;
 UPDATE public.kid_profiles SET energy_stars=energy_stars-item.price_stars WHERE id=p_kid;
 INSERT INTO public.kid_inventory(kid_id,item_id) VALUES(p_kid,p_item);
 END IF;
 INSERT INTO public.kid_equipment(kid_id,hat_id,glasses_id) VALUES(p_kid,'hat_detective','glasses_wisdom') ON CONFLICT DO NOTHING;
 UPDATE public.kid_equipment SET hat_id=CASE WHEN item.slot='hat' THEN item.id ELSE hat_id END,glasses_id=CASE WHEN item.slot='glasses' THEN item.id ELSE glasses_id END WHERE kid_id=p_kid;
 UPDATE public.kid_profiles SET avatar_id=(SELECT h.name||'|'||g.name FROM public.kid_equipment e JOIN public.mascot_items h ON h.id=e.hat_id JOIN public.mascot_items g ON g.id=e.glasses_id WHERE e.kid_id=p_kid) WHERE id=p_kid;
 RETURN private.get_wardrobe(p_kid);
END $$;

ALTER TABLE public.tournaments ADD COLUMN group_number integer NOT NULL DEFAULT 1;
ALTER TABLE public.tournaments DROP CONSTRAINT tournaments_grade_week_code_key;
ALTER TABLE public.tournaments ADD CONSTRAINT tournaments_group_unique UNIQUE(grade,week_code,group_number);
-- Split legacy oversized groups while retaining every existing score.
DO $$ DECLARE t public.tournaments; m record; destination uuid; bucket integer; BEGIN
 FOR t IN SELECT * FROM public.tournaments ORDER BY created_at LOOP
 FOR m IN SELECT kid_id,row_number() OVER(ORDER BY weekly_xp DESC,kid_id) AS n FROM public.tournament_members WHERE tournament_id=t.id LOOP
 bucket:=((m.n-1)/30)::integer+1;
 IF bucket>1 THEN
 INSERT INTO public.tournaments(grade,week_code,group_number) VALUES(t.grade,t.week_code,bucket) ON CONFLICT DO NOTHING;
 SELECT id INTO destination FROM public.tournaments WHERE grade=t.grade AND week_code=t.week_code AND group_number=bucket;
 UPDATE public.tournament_members SET tournament_id=destination WHERE tournament_id=t.id AND kid_id=m.kid_id;
 END IF; END LOOP; END LOOP;
END $$;
REVOKE ALL ON public.tournaments,public.tournament_members,public.v_leaderboard FROM PUBLIC,anon,authenticated;
GRANT ALL ON public.tournaments,public.tournament_members TO service_role;
CREATE FUNCTION private.join_arena(p_kid uuid) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_grade integer; week text:=to_char(now() AT TIME ZONE 'Asia/Ho_Chi_Minh','IYYY-"W"IW'); tournament uuid; number integer;
BEGIN
 SELECT k.grade INTO v_grade FROM public.kid_profiles k WHERE k.id=p_kid;
 PERFORM pg_advisory_xact_lock(hashtextextended(v_grade||':'||week,0));
 SELECT t.id INTO tournament FROM public.tournaments t JOIN public.tournament_members m ON m.tournament_id=t.id WHERE m.kid_id=p_kid AND t.week_code=week AND t.grade=v_grade LIMIT 1;
 IF FOUND THEN RETURN tournament; END IF;
 SELECT t.id INTO tournament FROM public.tournaments t WHERE t.grade=v_grade AND t.week_code=week AND (SELECT count(*) FROM public.tournament_members WHERE tournament_id=t.id)<30 ORDER BY group_number LIMIT 1;
 IF NOT FOUND THEN
 SELECT coalesce(max(group_number),0)+1 INTO number FROM public.tournaments t WHERE t.grade=v_grade AND t.week_code=week;
 INSERT INTO public.tournaments(grade,week_code,group_number) VALUES(v_grade,week,number) RETURNING id INTO tournament; END IF;
 INSERT INTO public.tournament_members(tournament_id,kid_id) VALUES(tournament,p_kid);
 RETURN tournament;
END $$;
CREATE OR REPLACE FUNCTION private.award_arena_session(p_session uuid,p_xp integer) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE kid uuid; tournament uuid; BEGIN
 SELECT kid_id INTO kid FROM public.study_sessions WHERE id=p_session;
 tournament:=private.join_arena(kid);
 UPDATE public.tournament_members SET weekly_xp=weekly_xp+p_xp WHERE tournament_id=tournament AND kid_id=kid;
END $$;
CREATE FUNCTION private.get_arena_board(p_kid uuid,p_previous boolean) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE tournament uuid; week text; result jsonb; BEGIN
 PERFORM private.assert_learning_kid(p_kid);
 week:=to_char((now() AT TIME ZONE 'Asia/Ho_Chi_Minh')-CASE WHEN p_previous THEN interval '7 days' ELSE interval '0 days' END,'IYYY-"W"IW');
 IF p_previous THEN SELECT t.id INTO tournament FROM public.tournaments t JOIN public.tournament_members m ON m.tournament_id=t.id WHERE m.kid_id=p_kid AND t.week_code=week LIMIT 1;
 ELSE tournament:=private.join_arena(p_kid); END IF;
 SELECT coalesce(jsonb_agg(r ORDER BY r.rank,r.nickname),'[]') INTO result FROM
 (SELECT k.nickname,m.weekly_xp,rank() OVER(ORDER BY m.weekly_xp DESC) AS rank,m.kid_id=p_kid AS is_me FROM public.tournament_members m JOIN public.kid_profiles k ON k.id=m.kid_id WHERE m.tournament_id=tournament) r;
 RETURN jsonb_build_object('week',week,'members',result,'group_number',(SELECT group_number FROM public.tournaments WHERE id=tournament));
END $$;

CREATE TABLE public.skills(id text PRIMARY KEY,name text NOT NULL);
INSERT INTO public.skills VALUES('counting','Đếm và số lượng'),('operations','Phép tính'),('time','Đồng hồ và thời gian'),('geometry','Hình học'),('word','Bài toán có lời văn');
ALTER TABLE public.skills ENABLE ROW LEVEL SECURITY; REVOKE ALL ON public.skills FROM PUBLIC,anon,authenticated; GRANT SELECT ON public.skills TO authenticated; GRANT ALL ON public.skills TO service_role;
CREATE POLICY skills_read ON public.skills FOR SELECT TO authenticated USING(true);
ALTER TABLE public.questions ADD COLUMN skill_id text REFERENCES public.skills(id);
UPDATE public.questions SET skill_id=CASE question_type WHEN 'drag_counters' THEN 'counting' WHEN 'clock_rotation' THEN 'time' WHEN 'area_grid' THEN 'geometry' WHEN 'multiplication_table' THEN 'operations' ELSE 'word' END;
CREATE INDEX questions_skill ON public.questions(skill_id);
CREATE TABLE public.lesson_drafts(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),lesson_id uuid UNIQUE REFERENCES public.lessons(id),content jsonb NOT NULL,updated_by uuid,updated_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE public.lesson_versions(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),lesson_id uuid NOT NULL REFERENCES public.lessons(id),version integer NOT NULL,content jsonb NOT NULL,published_by uuid,published_at timestamptz NOT NULL DEFAULT now(),UNIQUE(lesson_id,version));
ALTER TABLE public.lesson_drafts ENABLE ROW LEVEL SECURITY; ALTER TABLE public.lesson_versions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.lesson_drafts,public.lesson_versions FROM PUBLIC,anon,authenticated; GRANT SELECT ON public.lesson_drafts,public.lesson_versions TO authenticated; GRANT ALL ON public.lesson_drafts,public.lesson_versions TO service_role;
CREATE POLICY drafts_staff ON public.lesson_drafts FOR SELECT TO authenticated USING(private.is_staff());
CREATE POLICY versions_staff ON public.lesson_versions FOR SELECT TO authenticated USING(private.is_staff());
INSERT INTO public.lesson_versions(lesson_id,version,content)
SELECT l.id,l.content_version,to_jsonb(l)||jsonb_build_object('questions',(SELECT coalesce(jsonb_agg(q ORDER BY q.order_index),'[]') FROM public.questions q WHERE q.lesson_id=l.id AND q.is_active)) FROM public.lessons l;
CREATE FUNCTION private.staff_curriculum(p_grade integer) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT private.is_staff() THEN RAISE EXCEPTION 'Cần quyền biên tập'; END IF;
 RETURN jsonb_build_object('topics',(SELECT coalesce(jsonb_agg(t ORDER BY topic_number),'[]') FROM public.topics t WHERE grade=p_grade),
 'lessons',(SELECT coalesce(jsonb_agg(to_jsonb(l)||jsonb_build_object('draft_id',d.id) ORDER BY l.order_index),'[]') FROM public.lessons l JOIN public.topics t ON t.id=l.topic_id LEFT JOIN public.lesson_drafts d ON d.lesson_id=l.id WHERE t.grade=p_grade),
 'drafts',(SELECT coalesce(jsonb_agg(d ORDER BY updated_at DESC),'[]') FROM public.lesson_drafts d WHERE d.lesson_id IS NULL AND (d.content->>'grade')::integer=p_grade));
END $$;
CREATE FUNCTION private.staff_lesson(p_lesson uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE draft jsonb; BEGIN
 IF NOT private.is_staff() THEN RAISE EXCEPTION 'Cần quyền biên tập'; END IF;
 SELECT content INTO draft FROM public.lesson_drafts WHERE lesson_id=p_lesson;
 IF FOUND THEN RETURN draft; END IF;
 RETURN (SELECT to_jsonb(l)||jsonb_build_object('grade',t.grade,'questions',(SELECT coalesce(jsonb_agg(q ORDER BY q.order_index),'[]') FROM public.questions q WHERE q.lesson_id=l.id AND q.is_active)) FROM public.lessons l JOIN public.topics t ON t.id=l.topic_id WHERE l.id=p_lesson);
END $$;
CREATE FUNCTION private.save_lesson_draft(p_id uuid,p_content jsonb) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE id uuid; BEGIN
 IF NOT private.is_staff() OR length(p_content::text)>200000 THEN RAISE EXCEPTION 'Không có quyền hoặc nội dung quá lớn'; END IF;
 IF p_id IS NULL AND nullif(p_content->>'draft_id','') IS NOT NULL THEN
 UPDATE public.lesson_drafts SET content=p_content,updated_by=auth.uid(),updated_at=now() WHERE lesson_drafts.id=(p_content->>'draft_id')::uuid AND lesson_id IS NULL RETURNING lesson_drafts.id INTO id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Bản nháp không tồn tại'; END IF;
 PERFORM private.audit('SAVE_DRAFT','lesson',id::text,jsonb_build_object('title',p_content->>'title'));RETURN id;
 END IF;
 INSERT INTO public.lesson_drafts(lesson_id,content,updated_by) VALUES(p_id,p_content,auth.uid()) ON CONFLICT(lesson_id) DO UPDATE SET content=EXCLUDED.content,updated_by=auth.uid(),updated_at=now() RETURNING lesson_drafts.id INTO id;
 PERFORM private.audit('SAVE_DRAFT','lesson',coalesce(p_id,id)::text,jsonb_build_object('title',p_content->>'title'));
 RETURN id;
END $$;
CREATE FUNCTION private.publish_lesson(p_draft uuid) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE draft public.lesson_drafts; c jsonb; q jsonb; v_id uuid; q_id uuid; n integer:=0; topic uuid; v_version integer; expected text;
BEGIN
 IF NOT private.is_staff() THEN RAISE EXCEPTION 'Cần quyền xuất bản'; END IF;
 SELECT * INTO draft FROM public.lesson_drafts WHERE lesson_drafts.id=p_draft FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Không tìm thấy bản nháp'; END IF; c:=draft.content; topic:=(c->>'topic_id')::uuid;
 IF NOT coalesce(length(btrim(c->>'title')) BETWEEN 1 AND 150 AND length(coalesce(c->>'theory',''))>=10 AND jsonb_typeof(c->'questions')='array' AND jsonb_array_length(c->'questions') BETWEEN 1 AND 50,false) THEN RAISE EXCEPTION 'Cần tên, lý thuyết và 1–50 câu hỏi'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.topics WHERE topics.id=topic AND grade=(c->>'grade')::integer) THEN RAISE EXCEPTION 'Chủ đề/lớp không hợp lệ'; END IF;
 IF nullif(c->>'essay_prompt','') IS NOT NULL AND nullif(c->>'essay_answer','') IS NULL THEN RAISE EXCEPTION 'Cần đáp số tự luận để chấm'; END IF;
 FOR q IN SELECT value FROM jsonb_array_elements(c->'questions') LOOP
 IF NOT coalesce(length(btrim(q->>'prompt'))>=3 AND q->>'question_type' IN ('drag_counters','multiplication_table','clock_rotation','area_grid','word_problem') AND jsonb_typeof(q->'payload')='object',false) THEN RAISE EXCEPTION 'Câu hỏi hoặc dạng tương tác không hợp lệ'; END IF;
 expected:=private.question_expected(q);
 IF nullif(expected,'') IS NULL THEN RAISE EXCEPTION 'Câu hỏi thiếu đáp án'; END IF;
 IF q->>'question_type'='drag_counters' AND NOT coalesce((q->'payload'->>'targetCount')::integer BETWEEN 1 AND 20 AND coalesce(q->'payload'->>'availableCount','8')::integer BETWEEN (q->'payload'->>'targetCount')::integer AND 30,false) THEN RAISE EXCEPTION 'Số lượng kéo thả phải từ 1–20';END IF;
 IF q->>'question_type'='clock_rotation' AND NOT coalesce((q->'payload'->>'targetHour')::integer BETWEEN 0 AND 12 AND coalesce(q->'payload'->>'targetMinute','0')::integer BETWEEN 0 AND 55 AND coalesce(q->'payload'->>'targetMinute','0')::integer%5=0,false) THEN RAISE EXCEPTION 'Giờ/phút không hợp lệ';END IF;
 IF q->>'question_type'='area_grid' AND NOT coalesce(coalesce(q->'payload'->>'rows',q->'payload'->>'gridHeight')::integer BETWEEN 1 AND 10 AND coalesce(q->'payload'->>'cols',q->'payload'->>'gridWidth')::integer BETWEEN 1 AND 10,false) THEN RAISE EXCEPTION 'Lưới cần 1–10 hàng/cột';END IF;
 IF coalesce(jsonb_typeof(q->'socratic_hints'),'array')<>'array' THEN RAISE EXCEPTION 'Gợi ý cần là danh sách';END IF;
 IF EXISTS(SELECT 1 FROM jsonb_array_elements(coalesce(q->'socratic_hints','[]')) h WHERE jsonb_typeof(h)<>'object' OR coalesce(jsonb_typeof(h->'hintText'),jsonb_typeof(h->'hint_text'),'')<>'string' OR length(coalesce(h->>'hintText',h->>'hint_text','')) NOT BETWEEN 1 AND 1500 OR (h?'step' AND NOT coalesce(h->>'step' ~ '^[1-9][0-9]?$',false))) OR jsonb_array_length(coalesce(q->'socratic_hints','[]'))>10 THEN RAISE EXCEPTION 'Gợi ý cần có nội dung chữ và bước hợp lệ, tối đa 10 bước';END IF;
 IF q->>'question_type'='drag_counters' AND (jsonb_typeof(q->'payload'->'targetCount')<>'number' OR coalesce(jsonb_typeof(q->'payload'->'availableCount'),'number')<>'number') THEN RAISE EXCEPTION 'Số lượng kéo thả phải là số JSON';END IF;
 IF q->>'question_type'='clock_rotation' AND (jsonb_typeof(q->'payload'->'targetHour')<>'number' OR coalesce(jsonb_typeof(q->'payload'->'targetMinute'),'number')<>'number') THEN RAISE EXCEPTION 'Giờ/phút phải là số JSON';END IF;
 IF q->>'question_type'='area_grid' AND (jsonb_typeof(coalesce(q->'payload'->'rows',q->'payload'->'gridHeight'))<>'number' OR jsonb_typeof(coalesce(q->'payload'->'cols',q->'payload'->'gridWidth'))<>'number') THEN RAISE EXCEPTION 'Kích thước lưới phải là số JSON';END IF;
 IF q->>'question_type' IN ('multiplication_table','word_problem','area_grid') THEN
 IF coalesce(jsonb_typeof(q->'payload'->'options'),'')<>'array' OR jsonb_array_length(q->'payload'->'options') NOT BETWEEN 2 AND 6 OR NOT EXISTS(SELECT 1 FROM jsonb_array_elements_text(q->'payload'->'options') opt WHERE private.normal_answer(opt)=private.normal_answer(expected)) THEN RAISE EXCEPTION 'Cần 2–6 lựa chọn và có đáp án đúng'; END IF;
 IF (SELECT count(*) FROM jsonb_array_elements_text(q->'payload'->'options'))<>(SELECT count(DISTINCT private.normal_answer(opt)) FROM jsonb_array_elements_text(q->'payload'->'options') opt) THEN RAISE EXCEPTION 'Các lựa chọn không được trùng'; END IF;
 IF EXISTS(SELECT 1 FROM jsonb_array_elements(q->'payload'->'options') opt WHERE jsonb_typeof(opt) NOT IN ('number','string')) THEN RAISE EXCEPTION 'Lựa chọn phải là chữ hoặc số';END IF;
 IF EXISTS(SELECT 1 FROM jsonb_array_elements_text(q->'payload'->'options') WITH ORDINALITY a(value,n) CROSS JOIN jsonb_array_elements_text(q->'payload'->'options') WITH ORDINALITY b(value,n) WHERE a.n<b.n AND private.answer_equal(a.value,b.value)) THEN RAISE EXCEPTION 'Không dùng hai lựa chọn có giá trị tương đương';END IF;
 END IF;
 END LOOP;
 IF draft.lesson_id IS NULL THEN
 INSERT INTO public.lessons(topic_id,lesson_number,title,subtitle,order_index,theory,essay_prompt,essay_answer,access_tier,published)
 VALUES(topic,coalesce((c->>'lesson_number')::integer,1),c->>'title',c->>'subtitle',coalesce((c->>'order_index')::integer,1),c->>'theory',c->>'essay_prompt',c->>'essay_answer',coalesce(c->>'access_tier','basic')::public.subscription_tier,true) RETURNING lessons.id,content_version INTO v_id,v_version;
 ELSE
 v_id:=draft.lesson_id;
 UPDATE public.lessons SET topic_id=topic,title=c->>'title',subtitle=c->>'subtitle',theory=c->>'theory',essay_prompt=c->>'essay_prompt',essay_answer=c->>'essay_answer',access_tier=coalesce(c->>'access_tier','basic')::public.subscription_tier,published=true,content_version=content_version+1 WHERE lessons.id=v_id RETURNING content_version INTO v_version;
 END IF;
 UPDATE public.questions SET is_active=false WHERE lesson_id=v_id;
 FOR q IN SELECT value FROM jsonb_array_elements(c->'questions') LOOP
 n:=n+1; q_id:=coalesce(nullif(q->>'id','')::uuid,pg_catalog.gen_random_uuid());
 IF EXISTS(SELECT 1 FROM public.questions WHERE questions.id=q_id AND lesson_id<>v_id) THEN RAISE EXCEPTION 'ID câu hỏi thuộc bài khác'; END IF;
 q_id:=pg_catalog.gen_random_uuid(); -- New immutable question version; keep previous attempt FKs.
 INSERT INTO public.questions(id,lesson_id,question_type,prompt,payload,socratic_hints,order_index,is_active,skill_id)
 VALUES(q_id,v_id,q->>'question_type',q->>'prompt',q->'payload',coalesce(q->'socratic_hints','[]'),n,true,coalesce(q->>'skill_id',CASE q->>'question_type' WHEN 'drag_counters' THEN 'counting' WHEN 'clock_rotation' THEN 'time' WHEN 'area_grid' THEN 'geometry' WHEN 'multiplication_table' THEN 'operations' ELSE 'word' END))
 ON CONFLICT(id) DO UPDATE SET question_type=EXCLUDED.question_type,prompt=EXCLUDED.prompt,payload=EXCLUDED.payload,socratic_hints=EXCLUDED.socratic_hints,order_index=EXCLUDED.order_index,is_active=true,skill_id=EXCLUDED.skill_id;
 END LOOP;
 INSERT INTO public.lesson_versions(lesson_id,version,content,published_by) VALUES(v_id,v_version,c||jsonb_build_object('questions',(SELECT jsonb_agg(qs ORDER BY qs.order_index) FROM public.questions qs WHERE qs.lesson_id=v_id AND qs.is_active)),auth.uid());
 DELETE FROM public.lesson_drafts WHERE lesson_drafts.id=p_draft;
 PERFORM private.audit('PUBLISH','lesson',v_id::text,jsonb_build_object('version',v_version,'title',c->>'title'));
 RETURN v_id;
END $$;
CREATE FUNCTION private.set_lesson_published(p_lesson uuid,p_published boolean) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT private.is_staff() THEN RAISE EXCEPTION 'Cần quyền biên tập'; END IF;
 UPDATE public.lessons SET published=p_published WHERE id=p_lesson;
 PERFORM private.audit('VISIBILITY','lesson',p_lesson::text,jsonb_build_object('published',p_published)); END $$;
CREATE FUNCTION private.create_topic(p_grade integer,p_name text) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE id uuid; BEGIN
 IF NOT private.is_staff() OR p_grade NOT BETWEEN 1 AND 5 OR length(btrim(p_name)) NOT BETWEEN 1 AND 120 THEN RAISE EXCEPTION 'Chủ đề không hợp lệ'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('topic:'||p_grade,0));
 INSERT INTO public.topics(grade,topic_number,title) SELECT p_grade,coalesce(max(topic_number),0)+1,btrim(p_name) FROM public.topics WHERE grade=p_grade RETURNING topics.id INTO id;
 PERFORM private.audit('CREATE_TOPIC','topic',id::text,jsonb_build_object('name',p_name)); RETURN id; END $$;

CREATE FUNCTION private.family_report() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Cần đăng nhập'; END IF;
 RETURN jsonb_build_object('kids',(SELECT coalesce(jsonb_agg(jsonb_build_object('id',k.id,'nickname',k.nickname,'grade',k.grade,'archived',k.archived,
 'completed',(SELECT count(*) FROM public.kid_progress p WHERE p.kid_id=k.id AND p.is_completed),
 'today_seconds',coalesce((SELECT total_seconds FROM public.study_daily_usage WHERE kid_id=k.id AND study_date=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date),0),
 'days',(SELECT coalesce(jsonb_agg(u ORDER BY study_date),'[]') FROM public.study_daily_usage u WHERE kid_id=k.id AND study_date>=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date-6),
 'skills',(SELECT coalesce(jsonb_agg(r),'[]') FROM (SELECT sk.id,sk.name,count(*) AS attempts,round(100.0*count(*) FILTER(WHERE a.is_correct)/nullif(count(*),0)) AS accuracy FROM public.question_attempts a JOIN public.study_sessions s ON s.id=a.session_id JOIN public.questions q ON q.id=a.question_id JOIN public.skills sk ON sk.id=q.skill_id WHERE s.kid_id=k.id GROUP BY sk.id,sk.name) r),
 'last_session',(SELECT jsonb_build_object('lesson_id',s.lesson_id,'title',coalesce(l.title,s.kind),'status',s.status,'updated_at',s.updated_at) FROM public.study_sessions s LEFT JOIN public.lessons l ON l.id=s.lesson_id WHERE s.kid_id=k.id ORDER BY s.updated_at DESC LIMIT 1)) ORDER BY k.created_at),'[]') FROM public.kid_profiles k WHERE k.parent_id=auth.uid()),'entitlements',private.effective_entitlements());
END $$;
CREATE FUNCTION private.admin_parents(p_search text,p_tier text,p_page integer) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT public.is_admin() THEN RAISE EXCEPTION 'Cần quyền admin'; END IF;
 RETURN jsonb_build_object('total',(SELECT count(*) FROM public.parents),
 'plus_total',(SELECT count(*) FROM public.subscriptions WHERE tier='plus' AND status='active' AND (expires_at IS NULL OR expires_at>now())),
 'kid_total',(SELECT count(*) FROM public.kid_profiles WHERE NOT archived),
 'items',(SELECT coalesce(jsonb_agg(r ORDER BY r.created_at DESC),'[]') FROM (SELECT p.id,p.email,p.created_at,to_jsonb(s) AS subscription,(SELECT count(*) FROM public.kid_profiles k WHERE k.parent_id=p.id AND NOT archived) AS kid_count
 FROM public.parents p LEFT JOIN public.subscriptions s ON s.parent_id=p.id WHERE (coalesce(p_search,'')='' OR p.email ILIKE '%'||left(p_search,100)||'%')
 AND (coalesce(p_tier,'')='' OR CASE WHEN s.tier='plus' AND s.status='active' AND (s.expires_at IS NULL OR s.expires_at>now()) THEN 'plus' ELSE 'basic' END=p_tier)
 ORDER BY p.created_at DESC,p.id LIMIT 20 OFFSET greatest(0,least(p_page,10000))*20) r));
END $$;
CREATE FUNCTION private.admin_dashboard() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT public.is_admin() THEN RAISE EXCEPTION 'Cần quyền admin'; END IF;
 RETURN jsonb_build_object('paid_orders',(SELECT count(*) FROM public.learning_orders WHERE status='paid'),'pending_orders',(SELECT count(*) FROM public.learning_orders WHERE status='pending'),
 'verified_revenue_vnd',(SELECT coalesce(sum(p.amount_vnd),0) FROM public.learning_payments p JOIN public.learning_orders o ON o.id=p.order_id WHERE o.status='paid'),'sessions_week',(SELECT count(*) FROM public.study_sessions WHERE started_at>now()-interval '7 days'),
 'audit',(SELECT coalesce(jsonb_agg(r),'[]') FROM (SELECT * FROM public.admin_audit_logs ORDER BY created_at DESC LIMIT 50) r)); END $$;
CREATE FUNCTION private.set_user_role(p_user uuid,p_role public.app_role,p_enabled boolean,p_reason text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF p_user IS NULL OR p_role IS NULL OR p_enabled IS NULL THEN RAISE EXCEPTION 'Thiếu tài khoản, role hoặc thao tác'; END IF;
 IF NOT public.is_admin() OR nullif(btrim(p_reason),'') IS NULL THEN RAISE EXCEPTION 'Cần quyền admin và lý do'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('roles',0));
 IF p_role='admin' AND NOT p_enabled AND EXISTS(SELECT 1 FROM public.user_roles WHERE user_id=p_user AND role='admin') AND (SELECT count(*) FROM public.user_roles WHERE role='admin')<=1 THEN RAISE EXCEPTION 'Không thể xóa admin cuối cùng'; END IF;
 IF p_enabled THEN INSERT INTO public.user_roles(user_id,role) VALUES(p_user,p_role) ON CONFLICT DO NOTHING;
 ELSE DELETE FROM public.user_roles WHERE user_id=p_user AND role=p_role; END IF;
 PERFORM private.audit('ROLE_CHANGE','user',p_user::text,jsonb_build_object('role',p_role,'enabled',p_enabled,'reason',p_reason)); END $$;
REVOKE INSERT,UPDATE,DELETE ON public.user_roles FROM authenticated,anon;

-- Explicit wrappers and grants follow.

REVOKE ALL ON FUNCTION private.is_staff() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.is_staff() TO authenticated;
CREATE FUNCTION public.is_staff() RETURNS boolean LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.is_staff(); $$;
REVOKE ALL ON FUNCTION public.is_staff() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.is_staff() TO authenticated;
REVOKE ALL ON FUNCTION private.get_wardrobe(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.get_wardrobe(uuid) TO authenticated;
CREATE FUNCTION public.get_wardrobe(p_kid uuid) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.get_wardrobe(p_kid); $$;
REVOKE ALL ON FUNCTION public.get_wardrobe(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_wardrobe(uuid) TO authenticated;
REVOKE ALL ON FUNCTION private.buy_equip_item(uuid,text,boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.buy_equip_item(uuid,text,boolean) TO authenticated;
CREATE FUNCTION public.buy_equip_item(p_kid uuid,p_item text,p_buy boolean) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.buy_equip_item(p_kid,p_item,p_buy); $$;
REVOKE ALL ON FUNCTION public.buy_equip_item(uuid,text,boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.buy_equip_item(uuid,text,boolean) TO authenticated;
REVOKE ALL ON FUNCTION private.get_arena_board(uuid,boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.get_arena_board(uuid,boolean) TO authenticated;
CREATE FUNCTION public.get_arena_board(p_kid uuid,p_previous boolean) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.get_arena_board(p_kid,p_previous); $$;
REVOKE ALL ON FUNCTION public.get_arena_board(uuid,boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_arena_board(uuid,boolean) TO authenticated;
REVOKE ALL ON FUNCTION private.staff_curriculum(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.staff_curriculum(integer) TO authenticated;
CREATE FUNCTION public.staff_curriculum(p_grade integer) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.staff_curriculum(p_grade); $$;
REVOKE ALL ON FUNCTION public.staff_curriculum(integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.staff_curriculum(integer) TO authenticated;
REVOKE ALL ON FUNCTION private.staff_lesson(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.staff_lesson(uuid) TO authenticated;
CREATE FUNCTION public.staff_lesson(p_lesson uuid) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.staff_lesson(p_lesson); $$;
REVOKE ALL ON FUNCTION public.staff_lesson(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.staff_lesson(uuid) TO authenticated;
REVOKE ALL ON FUNCTION private.save_lesson_draft(uuid,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.save_lesson_draft(uuid,jsonb) TO authenticated;
CREATE FUNCTION public.save_lesson_draft(p_id uuid,p_content jsonb) RETURNS uuid LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.save_lesson_draft(p_id,p_content); $$;
REVOKE ALL ON FUNCTION public.save_lesson_draft(uuid,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.save_lesson_draft(uuid,jsonb) TO authenticated;
REVOKE ALL ON FUNCTION private.publish_lesson(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.publish_lesson(uuid) TO authenticated;
CREATE FUNCTION public.publish_lesson(p_draft uuid) RETURNS uuid LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.publish_lesson(p_draft); $$;
REVOKE ALL ON FUNCTION public.publish_lesson(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.publish_lesson(uuid) TO authenticated;
REVOKE ALL ON FUNCTION private.set_lesson_published(uuid,boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.set_lesson_published(uuid,boolean) TO authenticated;
CREATE FUNCTION public.set_lesson_published(p_lesson uuid,p_published boolean) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.set_lesson_published(p_lesson,p_published); $$;
REVOKE ALL ON FUNCTION public.set_lesson_published(uuid,boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.set_lesson_published(uuid,boolean) TO authenticated;
REVOKE ALL ON FUNCTION private.create_topic(integer,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.create_topic(integer,text) TO authenticated;
CREATE FUNCTION public.create_topic(p_grade integer,p_name text) RETURNS uuid LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.create_topic(p_grade,p_name); $$;
REVOKE ALL ON FUNCTION public.create_topic(integer,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.create_topic(integer,text) TO authenticated;
REVOKE ALL ON FUNCTION private.family_report() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.family_report() TO authenticated;
CREATE FUNCTION public.family_report() RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.family_report(); $$;
REVOKE ALL ON FUNCTION public.family_report() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.family_report() TO authenticated;
REVOKE ALL ON FUNCTION private.admin_parents(text,text,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.admin_parents(text,text,integer) TO authenticated;
CREATE FUNCTION public.admin_parents(p_search text,p_tier text,p_page integer) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.admin_parents(p_search,p_tier,p_page); $$;
REVOKE ALL ON FUNCTION public.admin_parents(text,text,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_parents(text,text,integer) TO authenticated;
REVOKE ALL ON FUNCTION private.admin_dashboard() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.admin_dashboard() TO authenticated;
CREATE FUNCTION public.admin_dashboard() RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.admin_dashboard(); $$;
REVOKE ALL ON FUNCTION public.admin_dashboard() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_dashboard() TO authenticated;
REVOKE ALL ON FUNCTION private.set_user_role(uuid,public.app_role,boolean,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.set_user_role(uuid,public.app_role,boolean,text) TO authenticated;
CREATE FUNCTION public.set_user_role(p_user uuid,p_role public.app_role,p_enabled boolean,p_reason text) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.set_user_role(p_user,p_role,p_enabled,p_reason); $$;
REVOKE ALL ON FUNCTION public.set_user_role(uuid,public.app_role,boolean,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.set_user_role(uuid,public.app_role,boolean,text) TO authenticated;
COMMIT;
