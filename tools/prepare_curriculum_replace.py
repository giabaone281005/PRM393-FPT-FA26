"""Prepare reviewable SQL. Defaults to a rolled-back rehearsal; never connects to DB.

Apply the language migration first. Take a fresh catalogue backup before --commit.
Expected baseline counts deliberately prevent replacing an unexpectedly changed catalogue.
"""
import argparse
import json
from pathlib import Path

root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--commit',action='store_true')
args=parser.parse_args()
data=json.loads((root/'cms/content/three-topic-curriculum.json').read_text(encoding='utf-8'))
body=json.dumps(data,ensure_ascii=False,separators=(',',':'))
assert '$curriculum$' not in body
sql="""-- Atomic, audited catalogue replacement. Historical versions and learner data survive.
BEGIN;
DO $replace$
DECLARE data jsonb := $curriculum$__DATA__$curriculum$;
 actor uuid; t jsonb; lesson jsonb; cfg jsonb; solution jsonb; s jsonb;
 result jsonb; rid uuid; before_counts jsonb; after_counts jsonb; before_versions int;
BEGIN
 PERFORM pg_advisory_xact_lock(750040);
 LOCK TABLE public.topics,public.activities,public.lesson_edits,public.lesson_builder_drafts IN SHARE ROW EXCLUSIVE MODE;
 IF (SELECT count(*) FROM public.topics)<>21 OR (SELECT count(*) FROM public.activities)<>140 OR (SELECT count(*) FROM public.activity_versions)<>141
   OR EXISTS(SELECT 1 FROM public.topics WHERE id IN ('studio-math','studio-english','studio-coding')) THEN
   RAISE EXCEPTION 'Catalogue differs from the backed-up baseline; inspect and back up again'; END IF;
 SELECT user_id INTO STRICT actor FROM private.account_access WHERE role='admin' AND status='active';
 PERFORM set_config('request.jwt.claim.sub',actor::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 PERFORM private.learning_actor('admin');
 SELECT jsonb_build_object('accounts',(SELECT count(*) FROM public.accounts),'sessions',(SELECT count(*) FROM public.learning_sessions),'attempts',(SELECT count(*) FROM public.activity_attempts),'completions',(SELECT count(*) FROM public.topic_completions),'xp',(SELECT coalesce(sum(delta),0) FROM public.xp_ledger)) INTO before_counts;
 SELECT count(*) INTO before_versions FROM public.activity_versions;
 -- Check every target and solution before any archival.
 FOR lesson IN SELECT value FROM jsonb_array_elements(data->'lessons') LOOP
  cfg:=lesson->'config';
  IF NOT coalesce(private.valid_slide_lesson(cfg),false) OR jsonb_array_length(cfg->'slides')<>6 THEN RAISE EXCEPTION 'Invalid lesson: %',lesson->>'id'; END IF;
  SELECT jsonb_build_object('index',5,'slides',jsonb_agg(data->'solutions'->(lesson->>'id')->(x->>'id') ORDER BY ord)) INTO solution FROM jsonb_array_elements(cfg->'slides') WITH ORDINALITY a(x,ord);
  IF NOT coalesce(private.evaluate_slide_lesson(cfg,solution),false) OR coalesce(private.evaluate_slide_lesson(cfg,'{}'),false) THEN RAISE EXCEPTION 'Scoring failed: %',lesson->>'id'; END IF;
 END LOOP;
 UPDATE public.topics SET status='archived',updated_at=now();
 UPDATE public.activities SET status='archived',updated_at=now();
 INSERT INTO public.lesson_edits(activity_id,title,stage,prompt,hint,explanation,status,sort_order)
 SELECT a.id,v.title,v.stage,v.prompt,coalesce(nullif(v.hint_levels->>0,''),'Đọc yêu cầu của bài.'),coalesce(nullif(v.explanation,''),'Nội dung đã lưu trữ.'),'archived',0
 FROM public.activities a JOIN LATERAL(SELECT * FROM public.activity_versions x WHERE x.activity_id=a.id ORDER BY content_version DESC LIMIT 1)v ON true
 ON CONFLICT(activity_id) DO UPDATE SET status='archived',revision=lesson_edits.revision+1,updated_at=now();
 UPDATE public.lesson_builder_drafts SET payload=jsonb_set(payload,'{status}','"archived"'::jsonb),revision=revision+1,updated_by=actor,updated_at=now();
 FOR t IN SELECT value FROM jsonb_array_elements(data->'topics') LOOP
  PERFORM public.admin_learning_mutate(gen_random_uuid(),'topic.save',t);
 END LOOP;
 FOR lesson IN SELECT value FROM jsonb_array_elements(data->'lessons') LOOP
  result:=public.admin_builder_save(gen_random_uuid(),lesson);
  result:=public.admin_content_mutate(gen_random_uuid(),lesson||jsonb_build_object('builder_revision',(result->>'revision')::int));
  rid:=(result->>'release_id')::uuid;
 END LOOP;
 IF (SELECT count(*) FROM public.release_activities WHERE release_id=rid)<>10 OR (SELECT count(*) FROM public.topics WHERE status='active')<>3 OR (SELECT count(*) FROM public.activities WHERE status='active')<>10 THEN RAISE EXCEPTION 'Final catalogue count mismatch'; END IF;
 IF (SELECT count(*) FROM public.activity_versions)<>before_versions+10 THEN RAISE EXCEPTION 'Historical versions changed'; END IF;
 SELECT jsonb_build_object('accounts',(SELECT count(*) FROM public.accounts),'sessions',(SELECT count(*) FROM public.learning_sessions),'attempts',(SELECT count(*) FROM public.activity_attempts),'completions',(SELECT count(*) FROM public.topic_completions),'xp',(SELECT coalesce(sum(delta),0) FROM public.xp_ledger)) INTO after_counts;
 IF before_counts IS DISTINCT FROM after_counts THEN RAISE EXCEPTION 'Learner history changed'; END IF;
 INSERT INTO private.admin_audit_logs(actor_user_id,actor_kind,action,target_type,target_id,request_id,summary)
 VALUES(actor,'admin','catalog.replace','content_release',rid::text,gen_random_uuid(),jsonb_build_object('archived_topics',21,'archived_activities',140,'new_topics',3,'new_lessons',10,'new_parts',60,'learner_counts',after_counts));
 PERFORM set_config('curriculum.release',rid::text,true);
END $replace$;
SELECT current_setting('curriculum.release') release_id,
 (SELECT jsonb_agg(t) FROM (SELECT id,title,(SELECT count(*) FROM public.activities a WHERE a.topic_id=topics.id AND a.status='active') lessons FROM public.topics WHERE status='active' ORDER BY sort_order)t) topics,
 (SELECT count(*) FROM public.activity_versions) preserved_and_new_versions;
__END__;
""".replace('__DATA__',body).replace('__END__','COMMIT' if args.commit else 'ROLLBACK')
if not args.commit:
    qa=(root/'supabase/tests/three_topic_curriculum_smoke.sql').read_text(encoding='utf-8').replace('__CURRICULUM_JSON__',body)
    sql=sql.replace('ROLLBACK;',qa+'\nROLLBACK;')
out=root/'build'/('curriculum-commit.sql' if args.commit else 'curriculum-rehearsal.sql')
out.write_text(sql,encoding='utf-8')
print(out)
