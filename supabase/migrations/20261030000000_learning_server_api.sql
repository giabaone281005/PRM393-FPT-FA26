-- Additive canonical learning APIs. Existing backup/Auth APIs remain unchanged.
-- Public entrypoints are invoker wrappers; privileged writes live in private.
CREATE OR REPLACE FUNCTION private.learning_actor(wanted text DEFAULT 'user')
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := auth.uid();
BEGIN
  IF actor IS NULL OR NOT EXISTS (
    SELECT 1 FROM private.account_access x JOIN public.accounts a ON a.id=x.user_id
    WHERE x.user_id=actor AND x.role=wanted AND x.status='active' AND a.deleted_at IS NULL
  ) THEN RAISE EXCEPTION 'Account access denied' USING ERRCODE='42501'; END IF;
  RETURN actor;
END $$;
REVOKE ALL ON FUNCTION private.learning_actor(text) FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION private.learning_apply(
  actor uuid, op uuid, kind text, data jsonb, evaluation jsonb DEFAULT NULL
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE
  head private.sync_heads; prior private.sync_operations; digest text;
  profile public.learner_profiles; sess public.learning_sessions;
  draft public.lesson_drafts; attempt public.activity_attempts;
  completion public.topic_completions; reward public.xp_ledger;
  event public.activity_events; account public.accounts; version public.activity_versions;
  changes jsonb := '[]'; result jsonb; item jsonb; record_id uuid;
  interests text[]; rev bigint; count_required integer; date_at timestamptz;
BEGIN
  -- Lock current authority as well as the per-owner commit clock. Role changes
  -- cannot race a mutation, and cursors never advance past uncommitted work.
  PERFORM 1 FROM private.account_access a JOIN public.accounts u ON u.id=a.user_id
    WHERE a.user_id=actor AND a.role='user' AND a.status='active' AND u.deleted_at IS NULL
    FOR SHARE OF a,u;
  IF NOT FOUND THEN RAISE EXCEPTION 'Account access denied' USING ERRCODE='42501'; END IF;
  IF op IS NULL OR kind IS NULL OR data IS NULL OR jsonb_typeof(data)<>'object'
    OR octet_length(data::text)>300000 THEN
    RAISE EXCEPTION 'Invalid operation payload' USING ERRCODE='22023'; END IF;
  INSERT INTO private.sync_heads(owner_user_id) VALUES(actor) ON CONFLICT DO NOTHING;
  SELECT * INTO head FROM private.sync_heads WHERE owner_user_id=actor FOR UPDATE;
  digest := encode(extensions.digest(convert_to(kind||':'||data::text,'UTF8'),'sha256'),'hex');
  SELECT * INTO prior FROM private.sync_operations WHERE owner_user_id=actor AND operation_id=op;
  IF FOUND THEN
    IF prior.payload_hash<>digest THEN
      RAISE EXCEPTION 'Operation ID reused with different payload' USING ERRCODE='22023'; END IF;
    RETURN prior.response;
  END IF;
  rev := head.revision+1;

  IF kind='account.update' THEN
    IF coalesce(length(btrim(data->>'display_name')),0) NOT BETWEEN 1 AND 80
      OR coalesce(length(data->>'locale'),0) NOT BETWEEN 2 AND 20
      OR NOT EXISTS(SELECT 1 FROM pg_timezone_names WHERE name=data->>'timezone')
    THEN RAISE EXCEPTION 'Invalid account settings' USING ERRCODE='22023'; END IF;
    UPDATE public.accounts SET display_name=btrim(data->>'display_name'),locale=data->>'locale',
      timezone=data->>'timezone' WHERE id=actor RETURNING * INTO account;
    changes := jsonb_build_array(jsonb_build_object('entity','accounts','id',actor,'row',to_jsonb(account)));
    result := to_jsonb(account);
  ELSIF kind IN ('profile.create','profile.update','profile.delete') THEN
    record_id := (data->>'id')::uuid;
    IF record_id IS NULL THEN RAISE EXCEPTION 'Profile ID required' USING ERRCODE='22023'; END IF;
    IF kind='profile.create' THEN
      IF (SELECT count(*) FROM public.learner_profiles WHERE owner_user_id=actor AND deleted_at IS NULL)>=100
      THEN RAISE EXCEPTION 'Profile limit reached' USING ERRCODE='22023'; END IF;
    ELSE
      SELECT * INTO profile FROM public.learner_profiles WHERE id=record_id AND owner_user_id=actor
        AND deleted_at IS NULL FOR UPDATE;
      IF NOT FOUND THEN RAISE EXCEPTION 'Profile unavailable' USING ERRCODE='42501'; END IF;
      IF (data->>'expected_revision')::bigint IS DISTINCT FROM profile.revision THEN
        RAISE EXCEPTION 'Profile revision conflict' USING ERRCODE='40001'; END IF;
    END IF;
    IF kind='profile.delete' THEN
      UPDATE public.learner_profiles SET deleted_at=now(),revision=revision+1 WHERE id=record_id RETURNING * INTO profile;
      -- A profile tombstone invalidates its entire subtree on other devices.
      changes := jsonb_build_array(jsonb_build_object('entity','learner_profiles','id',record_id,'delete',true));
    ELSE
      IF coalesce(length(btrim(data->>'name')),0) NOT BETWEEN 1 AND 60
        OR coalesce((data->>'daily_minutes')::int,0) NOT BETWEEN 1 AND 120
        OR jsonb_typeof(data->'interest_topic_ids') IS DISTINCT FROM 'array'
        OR jsonb_array_length(data->'interest_topic_ids')>30
      THEN RAISE EXCEPTION 'Invalid profile settings' USING ERRCODE='22023'; END IF;
      SELECT coalesce(array_agg(value),'{}') INTO interests FROM jsonb_array_elements_text(data->'interest_topic_ids');
      IF cardinality(interests)<>(SELECT count(DISTINCT x) FROM unnest(interests) x)
        OR EXISTS(SELECT 1 FROM unnest(interests) x WHERE NOT EXISTS(SELECT 1 FROM public.topics WHERE id=x))
      THEN RAISE EXCEPTION 'Invalid interest topics' USING ERRCODE='22023'; END IF;
      IF kind='profile.create' THEN
        INSERT INTO public.learner_profiles(id,owner_user_id,name,daily_minutes,interest_topic_ids,onboarded_at)
          VALUES(record_id,actor,btrim(data->>'name'),(data->>'daily_minutes')::smallint,interests,
            CASE WHEN data->>'onboarded'='true' THEN now() END) RETURNING * INTO profile;
      ELSE
        UPDATE public.learner_profiles SET name=btrim(data->>'name'),daily_minutes=(data->>'daily_minutes')::smallint,
          interest_topic_ids=interests,revision=revision+1,
          onboarded_at=CASE WHEN data->>'onboarded'='true' THEN coalesce(onboarded_at,now()) ELSE onboarded_at END
          WHERE id=record_id RETURNING * INTO profile;
      END IF;
      changes := jsonb_build_array(jsonb_build_object('entity','learner_profiles','id',record_id,'row',to_jsonb(profile)));
    END IF;
    result := to_jsonb(profile);
  ELSE
    IF kind='session.start' THEN
      SELECT * INTO profile FROM public.learner_profiles WHERE id=(data->>'profile_id')::uuid
        AND owner_user_id=actor AND deleted_at IS NULL FOR UPDATE;
      IF NOT FOUND THEN RAISE EXCEPTION 'Profile unavailable' USING ERRCODE='42501'; END IF;
      IF NOT EXISTS(SELECT 1 FROM public.content_releases r JOIN public.release_activities ra ON ra.release_id=r.id
          JOIN public.activity_versions av ON av.activity_id=ra.activity_id AND av.content_version=ra.content_version
          JOIN private.evaluator_versions ev ON ev.mechanism=av.mechanism AND ev.version=av.evaluator_version
          WHERE r.id=(data->>'release_id')::uuid AND r.status='published' AND ra.topic_id=data->>'topic_id'
            AND av.status='published' AND ev.status='active')
      THEN RAISE EXCEPTION 'Published lesson unavailable' USING ERRCODE='22023'; END IF;
      date_at := coalesce((data->>'started_at')::timestamptz,now());
      IF date_at>now()+interval '5 minutes' OR date_at<now()-interval '90 days'
      THEN RAISE EXCEPTION 'Invalid session time' USING ERRCODE='22023'; END IF;
      INSERT INTO public.learning_sessions(id,profile_id,owner_user_id,topic_id,release_id,device_id,started_at)
        VALUES((data->>'id')::uuid,profile.id,actor,data->>'topic_id',(data->>'release_id')::uuid,
          (data->>'device_id')::uuid,date_at) RETURNING * INTO sess;
    ELSE
      SELECT s.* INTO sess FROM public.learning_sessions s JOIN public.learner_profiles p ON p.id=s.profile_id
        WHERE s.id=(data->>'session_id')::uuid AND s.owner_user_id=actor AND p.deleted_at IS NULL FOR UPDATE OF s;
      IF NOT FOUND THEN RAISE EXCEPTION 'Session unavailable' USING ERRCODE='42501'; END IF;
      IF sess.status<>'in_progress' THEN RAISE EXCEPTION 'Session already closed' USING ERRCODE='22023'; END IF;
      IF kind='draft.save' THEN
        IF jsonb_typeof(data->'snapshot') IS DISTINCT FROM 'object' OR octet_length((data->'snapshot')::text)>262144
          OR coalesce((data->>'expected_revision')::bigint,-1)<0
          OR NOT EXISTS(SELECT 1 FROM public.release_activities WHERE release_id=sess.release_id
            AND topic_id=sess.topic_id AND activity_id=data->>'activity_id')
        THEN RAISE EXCEPTION 'Invalid lesson draft' USING ERRCODE='22023'; END IF;
        SELECT * INTO draft FROM public.lesson_drafts WHERE id=(data->>'id')::uuid AND owner_user_id=actor FOR UPDATE;
        IF FOUND THEN
          IF draft.session_id<>sess.id OR draft.revision<>(data->>'expected_revision')::bigint THEN
            RAISE EXCEPTION 'Draft revision conflict' USING ERRCODE='40001'; END IF;
          UPDATE public.lesson_drafts SET snapshot=data->'snapshot',current_activity_id=data->>'activity_id',
            base_revision=draft.revision,revision=revision+1 WHERE id=draft.id RETURNING * INTO draft;
        ELSE
          IF (data->>'expected_revision')::bigint<>0 THEN
            RAISE EXCEPTION 'Draft revision conflict' USING ERRCODE='40001'; END IF;
          INSERT INTO public.lesson_drafts(id,session_id,profile_id,owner_user_id,current_activity_id,snapshot,base_revision)
            VALUES((data->>'id')::uuid,sess.id,sess.profile_id,actor,data->>'activity_id',data->'snapshot',0)
            RETURNING * INTO draft;
        END IF;
        changes := jsonb_build_array(jsonb_build_object('entity','lesson_drafts','id',draft.id,'row',to_jsonb(draft)));
      ELSIF kind='attempt.submit' THEN
        IF evaluation IS NULL THEN RAISE EXCEPTION 'Server evaluation required' USING ERRCODE='42501'; END IF;
        SELECT av.* INTO version FROM public.release_activities ra JOIN public.activity_versions av
          ON av.activity_id=ra.activity_id AND av.content_version=ra.content_version
          JOIN private.evaluator_versions ev ON ev.mechanism=av.mechanism AND ev.version=av.evaluator_version
          WHERE ra.release_id=sess.release_id AND ra.topic_id=sess.topic_id AND ra.activity_id=data->>'activity_id'
          AND ra.content_version=(data->>'content_version')::int AND ev.status IN ('active','retired')
          AND ev.implementation_hash=evaluation->>'implementation_hash';
        IF NOT FOUND OR version.mechanism IS DISTINCT FROM evaluation->>'mechanism'
          OR version.evaluator_version IS DISTINCT FROM (evaluation->>'evaluator_version')::int
          OR version.config IS DISTINCT FROM evaluation->'config'
          OR version.initial_state IS DISTINCT FROM evaluation->'initial_state'
          OR jsonb_typeof(evaluation->'is_correct') IS DISTINCT FROM 'boolean'
          OR jsonb_typeof(data->'state') IS DISTINCT FROM 'object'
          OR octet_length((data->'state')::text)>65536
          OR coalesce((data->>'hint_level')::int,0) NOT BETWEEN 0 AND 3
        THEN RAISE EXCEPTION 'Unsupported lesson version or invalid state' USING ERRCODE='22023'; END IF;
        INSERT INTO public.activity_attempts(operation_id,session_id,profile_id,owner_user_id,release_id,
          activity_id,content_version,submitted_state,hint_level,evaluation_status,is_correct,misconception_codes,
          satisfied_constraints,feedback_key,evaluator_version)
        VALUES(op,sess.id,sess.profile_id,actor,sess.release_id,version.activity_id,version.content_version,
          data->'state',coalesce((data->>'hint_level')::smallint,0),'verified',(evaluation->>'is_correct')::boolean,
          ARRAY(SELECT jsonb_array_elements_text(evaluation->'misconception_codes')),
          ARRAY(SELECT jsonb_array_elements_text(evaluation->'satisfied_constraints')),
          evaluation->>'feedback_key',version.evaluator_version) RETURNING * INTO attempt;
        UPDATE public.learning_sessions SET attempts_count=attempts_count+1,revision=revision+1
          WHERE id=sess.id RETURNING * INTO sess;
        changes := jsonb_build_array(jsonb_build_object('entity','activity_attempts','id',attempt.id,'row',to_jsonb(attempt)));
      ELSIF kind='event.record' THEN
        IF data->>'event_type' IS NULL OR data->>'event_type' NOT IN ('active_time','hint_opened')
          OR coalesce((data->>'active_ms')::bigint,0) NOT BETWEEN 0 AND 60000
          OR coalesce((data->>'hint_level')::int,0) NOT BETWEEN 0 AND 3
          OR NOT EXISTS(SELECT 1 FROM public.release_activities WHERE release_id=sess.release_id
            AND topic_id=sess.topic_id AND activity_id=data->>'activity_id')
        THEN RAISE EXCEPTION 'Invalid learning event' USING ERRCODE='22023'; END IF;
        -- Active time is telemetry only, never an authority for XP or completion.
        SELECT * INTO account FROM public.accounts WHERE id=actor;
        INSERT INTO public.activity_events(operation_id,session_id,profile_id,owner_user_id,event_type,activity_id,
          active_ms_delta,hint_level,occurred_at,local_date,timezone)
        VALUES(op,sess.id,sess.profile_id,actor,data->>'event_type',data->>'activity_id',
          CASE WHEN data->>'event_type'='active_time' THEN coalesce((data->>'active_ms')::bigint,0) ELSE 0 END,
          coalesce((data->>'hint_level')::smallint,0),now(),(now() AT TIME ZONE account.timezone)::date,account.timezone)
          RETURNING * INTO event;
        UPDATE public.learning_sessions SET active_ms=active_ms+event.active_ms_delta,
          hints_used=hints_used+CASE WHEN event.event_type='hint_opened' THEN 1 ELSE 0 END,revision=revision+1
          WHERE id=sess.id RETURNING * INTO sess;
        changes := jsonb_build_array(jsonb_build_object('entity','activity_events','id',event.id,'row',to_jsonb(event)));
      ELSIF kind='session.complete' THEN
        SELECT count(*) INTO count_required FROM public.release_activities
          WHERE release_id=sess.release_id AND topic_id=sess.topic_id AND required;
        IF count_required=0 OR EXISTS(
          SELECT 1 FROM public.release_activities ra WHERE ra.release_id=sess.release_id
            AND ra.topic_id=sess.topic_id AND ra.required AND NOT EXISTS(
              SELECT 1 FROM public.activity_attempts a WHERE a.session_id=sess.id AND a.activity_id=ra.activity_id
                AND a.content_version=ra.content_version AND a.evaluation_status='verified' AND a.is_correct))
        THEN RAISE EXCEPTION 'Required activities are not complete' USING ERRCODE='22023'; END IF;
        INSERT INTO public.topic_completions(profile_id,owner_user_id,topic_id,release_id,session_id,source,completed_at,verified_at)
          VALUES(sess.profile_id,actor,sess.topic_id,sess.release_id,sess.id,'verified',now(),now())
          ON CONFLICT DO NOTHING RETURNING * INTO completion;
        IF completion.id IS NULL THEN
          SELECT * INTO completion FROM public.topic_completions WHERE profile_id=sess.profile_id
            AND topic_id=sess.topic_id AND release_id=sess.release_id AND source='verified'; END IF;
        INSERT INTO public.xp_ledger(profile_id,owner_user_id,reward_key,topic_id,completion_id,source)
          VALUES(sess.profile_id,actor,'topic:'||sess.topic_id||':first_completion',sess.topic_id,completion.id,'first_completion')
          ON CONFLICT DO NOTHING RETURNING * INTO reward;
        UPDATE public.learning_sessions SET status='verified',completed_at=now(),revision=revision+1
          WHERE id=sess.id RETURNING * INTO sess;
        changes := jsonb_build_array(jsonb_build_object('entity','topic_completions','id',completion.id,'row',to_jsonb(completion)));
        IF reward.id IS NOT NULL THEN changes := changes||jsonb_build_array(
          jsonb_build_object('entity','xp_ledger','id',reward.id,'row',to_jsonb(reward))); END IF;
      ELSIF kind='session.abandon' THEN
        UPDATE public.learning_sessions SET status='abandoned',revision=revision+1 WHERE id=sess.id RETURNING * INTO sess;
      ELSE RAISE EXCEPTION 'Unknown learning operation' USING ERRCODE='22023';
      END IF;
    END IF;
    changes := changes||jsonb_build_array(jsonb_build_object('entity','learning_sessions','id',sess.id,'row',to_jsonb(sess)));
    result := jsonb_build_object('session',to_jsonb(sess),'draft',to_jsonb(draft),'attempt',to_jsonb(attempt),
      'completion',to_jsonb(completion),'xp_awarded',CASE WHEN reward.id IS NULL THEN 0 ELSE reward.delta END);
  END IF;
  UPDATE private.sync_heads SET revision=rev WHERE owner_user_id=actor;
  FOR item IN SELECT value FROM jsonb_array_elements(changes) LOOP
    INSERT INTO private.sync_changes(owner_user_id,revision,change_index,entity_type,entity_id,action,payload)
    VALUES(actor,rev,(SELECT count(*) FROM private.sync_changes WHERE owner_user_id=actor AND revision=rev),
      item->>'entity',item->>'id',CASE WHEN item->>'delete'='true' THEN 'delete' ELSE 'upsert' END,
      item->'row');
  END LOOP;
  result := jsonb_build_object('operation_id',op,'revision',rev::text,'result',result);
  INSERT INTO private.sync_operations(owner_user_id,operation_id,operation_type,payload_hash,status,response,server_revision)
    VALUES(actor,op,kind,digest,'applied',result,rev);
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION private.learning_apply(uuid,uuid,text,jsonb,jsonb) FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION private.learning_mutate(operation_id uuid,operation_type text,payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
  IF operation_type='attempt.submit' THEN RAISE EXCEPTION 'Use server evaluator' USING ERRCODE='42501'; END IF;
  RETURN private.learning_apply(private.learning_actor(),operation_id,operation_type,payload);
END $$;
REVOKE ALL ON FUNCTION private.learning_mutate(uuid,text,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.learning_mutate(uuid,text,jsonb) TO authenticated;
CREATE OR REPLACE FUNCTION public.learning_mutate(operation_id uuid,operation_type text,payload jsonb)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
  SELECT private.learning_mutate(operation_id,operation_type,payload)
$$;
REVOKE ALL ON FUNCTION public.learning_mutate(uuid,text,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.learning_mutate(uuid,text,jsonb) TO authenticated;

-- Only the authenticated Edge handler may commit an evaluation. A mobile JWT
-- cannot manufacture correctness, evaluator versions, XP, or another owner.
CREATE OR REPLACE FUNCTION private.record_learning_attempt(owner_id uuid,operation_id uuid,payload jsonb,evaluation jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN RAISE EXCEPTION 'Server only' USING ERRCODE='42501'; END IF;
  RETURN private.learning_apply(owner_id,operation_id,'attempt.submit',payload,evaluation);
END $$;
REVOKE ALL ON FUNCTION private.record_learning_attempt(uuid,uuid,jsonb,jsonb) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.record_learning_attempt(uuid,uuid,jsonb,jsonb) TO service_role;
CREATE OR REPLACE FUNCTION public.record_learning_attempt(owner_id uuid,operation_id uuid,payload jsonb,evaluation jsonb)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
  SELECT private.record_learning_attempt(owner_id,operation_id,payload,evaluation)
$$;
REVOKE ALL ON FUNCTION public.record_learning_attempt(uuid,uuid,jsonb,jsonb) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.record_learning_attempt(uuid,uuid,jsonb,jsonb) TO service_role;

CREATE OR REPLACE FUNCTION private.learning_changes(
  after_revision bigint DEFAULT 0,after_index integer DEFAULT -1,until_revision bigint DEFAULT NULL,page_size integer DEFAULT 100
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor(); head private.sync_heads; items jsonb; last_row private.sync_changes; high bigint;
BEGIN
  SELECT * INTO head FROM private.sync_heads WHERE owner_user_id=actor;
  high := coalesce(until_revision,head.revision,0);
  IF after_revision IS NULL OR after_index IS NULL OR page_size IS NULL
    OR page_size NOT BETWEEN 1 AND 200 OR after_index< -1 OR after_revision<0
    OR high>coalesce(head.revision,0) OR high<after_revision
    OR after_revision<coalesce(head.min_available_revision,0)
  THEN RAISE EXCEPTION 'Invalid or expired sync cursor' USING ERRCODE='22023'; END IF;
  SELECT coalesce(jsonb_agg(jsonb_build_object('revision',x.revision::text,'index',x.change_index,
    'entity',x.entity_type,'id',x.entity_id,'action',x.action,'payload',x.payload) ORDER BY x.revision,x.change_index),'[]')
    INTO items FROM (SELECT * FROM private.sync_changes WHERE owner_user_id=actor
      AND (revision,change_index)>(after_revision,after_index) AND revision<=high
      ORDER BY revision,change_index LIMIT page_size) x;
  SELECT * INTO last_row FROM private.sync_changes WHERE owner_user_id=actor
    AND (revision,change_index)>(after_revision,after_index) AND revision<=high
    ORDER BY revision,change_index LIMIT 1 OFFSET page_size-1;
  RETURN jsonb_build_object('changes',items,'high_water',high::text,
    'has_more',CASE WHEN last_row.revision IS NULL THEN false ELSE EXISTS(
      SELECT 1 FROM private.sync_changes WHERE owner_user_id=actor AND revision<=high
        AND (revision,change_index)>(last_row.revision,last_row.change_index)) END,
    'next_revision',coalesce(items->-1->>'revision',after_revision::text),
    'next_index',coalesce((items->-1->>'index')::int,after_index));
END $$;
REVOKE ALL ON FUNCTION private.learning_changes(bigint,integer,bigint,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.learning_changes(bigint,integer,bigint,integer) TO authenticated;
CREATE OR REPLACE FUNCTION public.learning_changes(
  after_revision bigint DEFAULT 0,after_index integer DEFAULT -1,until_revision bigint DEFAULT NULL,page_size integer DEFAULT 100
) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.learning_changes(after_revision,after_index,until_revision,page_size)
$$;
REVOKE ALL ON FUNCTION public.learning_changes(bigint,integer,bigint,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.learning_changes(bigint,integer,bigint,integer) TO authenticated;
CREATE OR REPLACE FUNCTION private.learning_catalog(app_version text)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor(); release public.content_releases;
BEGIN
  IF app_version IS NULL OR app_version !~ '^\d+\.\d+\.\d+$' THEN
    RAISE EXCEPTION 'Invalid app version' USING ERRCODE='22023'; END IF;
  SELECT * INTO release FROM public.content_releases r WHERE r.status='published'
    AND string_to_array(r.min_app_version,'.')::int[]<=string_to_array(app_version,'.')::int[]
    ORDER BY published_at DESC,id DESC LIMIT 1;
  IF NOT FOUND THEN RETURN jsonb_build_object('release',NULL,'topics','[]'::jsonb,'activities','[]'::jsonb); END IF;
  RETURN jsonb_build_object('release',to_jsonb(release),
    'topics',(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY t.sort_order,t.id),'[]') FROM public.topics t
      WHERE EXISTS(SELECT 1 FROM public.release_activities ra WHERE ra.release_id=release.id AND ra.topic_id=t.id)),
    'activities',(SELECT coalesce(jsonb_agg(to_jsonb(av)||jsonb_build_object('topic_id',ra.topic_id,'position',ra.position,
      'required',ra.required) ORDER BY ra.topic_id,ra.position),'[]') FROM public.release_activities ra
      JOIN public.activity_versions av ON av.activity_id=ra.activity_id AND av.content_version=ra.content_version
      WHERE ra.release_id=release.id));
END $$;
REVOKE ALL ON FUNCTION private.learning_catalog(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.learning_catalog(text) TO authenticated;
CREATE OR REPLACE FUNCTION public.learning_catalog(app_version text DEFAULT '1.3.0')
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT private.learning_catalog(app_version) $$;
REVOKE ALL ON FUNCTION public.learning_catalog(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.learning_catalog(text) TO authenticated;

CREATE OR REPLACE FUNCTION private.learning_progress(profile_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor(); profile public.learner_profiles;
BEGIN
  SELECT * INTO profile FROM public.learner_profiles p WHERE p.id=profile_id AND p.owner_user_id=actor AND p.deleted_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'Profile unavailable' USING ERRCODE='42501'; END IF;
  RETURN jsonb_build_object('profile',to_jsonb(profile)||jsonb_build_object('revision',profile.revision::text),
    'verified_xp',(SELECT coalesce(sum(delta),0) FROM public.xp_ledger x WHERE x.profile_id=profile.id),
    'topics',(SELECT coalesce(jsonb_agg(to_jsonb(x)),'[]') FROM (
      SELECT a.topic_id,count(*) FILTER (WHERE a.status='verified') verified_sessions,
        sum(a.active_ms)::text active_ms,sum(a.attempts_count) attempts,sum(a.hints_used) hints_used
      FROM public.learning_sessions a WHERE a.profile_id=profile.id GROUP BY a.topic_id) x),
    'assessment',(SELECT coalesce(jsonb_agg(to_jsonb(x)),'[]') FROM (
      SELECT a.activity_id,count(*) attempts,count(*) FILTER(WHERE is_correct) correct_attempts
      FROM public.activity_attempts a WHERE a.profile_id=profile.id GROUP BY a.activity_id) x));
END $$;
REVOKE ALL ON FUNCTION private.learning_progress(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.learning_progress(uuid) TO authenticated;
CREATE OR REPLACE FUNCTION public.learning_progress(profile_id uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT private.learning_progress(profile_id) $$;
REVOKE ALL ON FUNCTION public.learning_progress(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.learning_progress(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION private.admin_learning_read(section text,page_offset integer,page_size integer)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor('admin'); result jsonb;
BEGIN
  IF page_offset IS NULL OR page_size IS NULL OR page_offset NOT BETWEEN 0 AND 100000 OR page_size NOT BETWEEN 1 AND 100
  THEN RAISE EXCEPTION 'Invalid page' USING ERRCODE='22023'; END IF;
  IF section='overview' THEN
    RETURN jsonb_build_object('users',(SELECT count(*) FROM private.account_access WHERE role='user'),
      'profiles',(SELECT count(*) FROM public.learner_profiles WHERE deleted_at IS NULL),
      'sessions',(SELECT count(*) FROM public.learning_sessions),
      'verified_completions',(SELECT count(*) FROM public.topic_completions WHERE source='verified'));
  ELSIF section='accounts' THEN
    SELECT coalesce(jsonb_agg(to_jsonb(x)),'[]') INTO result FROM (
      SELECT a.id,a.display_name,a.locale,a.timezone,a.created_at,x.status FROM public.accounts a
        JOIN private.account_access x ON x.user_id=a.id WHERE x.role='user' ORDER BY a.created_at,a.id
        LIMIT page_size OFFSET page_offset) x;
  ELSIF section='audit' THEN
    SELECT coalesce(jsonb_agg(to_jsonb(x)),'[]') INTO result FROM (
      SELECT * FROM private.admin_audit_logs ORDER BY created_at DESC,id DESC LIMIT page_size OFFSET page_offset) x;
  ELSIF section='releases' THEN
    SELECT coalesce(jsonb_agg(to_jsonb(x)),'[]') INTO result FROM (
      SELECT * FROM public.content_releases ORDER BY created_at DESC,id DESC LIMIT page_size OFFSET page_offset) x;
  ELSIF section='topics' THEN
    SELECT coalesce(jsonb_agg(to_jsonb(x)),'[]') INTO result FROM (
      SELECT * FROM public.topics ORDER BY sort_order,id LIMIT page_size OFFSET page_offset) x;
  ELSIF section='activities' THEN
    SELECT coalesce(jsonb_agg(to_jsonb(x)),'[]') INTO result FROM (
      SELECT * FROM public.activity_versions ORDER BY activity_id,content_version DESC LIMIT page_size OFFSET page_offset) x;
  ELSE RAISE EXCEPTION 'Unknown admin section' USING ERRCODE='22023'; END IF;
  RETURN jsonb_build_object('items',result,'offset',page_offset,'limit',page_size);
END $$;
REVOKE ALL ON FUNCTION private.admin_learning_read(text,integer,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.admin_learning_read(text,integer,integer) TO authenticated;
CREATE OR REPLACE FUNCTION public.admin_learning_read(section text DEFAULT 'overview',page_offset integer DEFAULT 0,page_size integer DEFAULT 50)
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT private.admin_learning_read(section,page_offset,page_size) $$;
REVOKE ALL ON FUNCTION public.admin_learning_read(text,integer,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_learning_read(text,integer,integer) TO authenticated;

CREATE OR REPLACE FUNCTION private.admin_learning_mutate(operation_id uuid,operation_type text,payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor('admin'); data jsonb := payload; result jsonb;
  audit private.admin_audit_logs; target text; manifest jsonb; release public.content_releases;
BEGIN
  IF operation_id IS NULL OR operation_type IS NULL OR data IS NULL OR jsonb_typeof(data)<>'object'
    OR octet_length(data::text)>300000 THEN RAISE EXCEPTION 'Invalid admin payload' USING ERRCODE='22023'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(actor::text,750031));
  SELECT * INTO audit FROM private.admin_audit_logs WHERE actor_user_id=actor AND request_id=operation_id;
  IF FOUND THEN
    IF audit.summary->'request' IS DISTINCT FROM jsonb_build_object('operation_type',operation_type,'payload',data)
    THEN RAISE EXCEPTION 'Operation ID reused with different payload' USING ERRCODE='22023'; END IF;
    RETURN audit.summary->'response'; END IF;
  target := data->>'id';
  IF operation_type='account.status' THEN
    IF data->>'status' IS NULL OR data->>'status' NOT IN ('active','suspended') THEN
      RAISE EXCEPTION 'Invalid account status' USING ERRCODE='22023'; END IF;
    UPDATE private.account_access SET status=data->>'status' WHERE user_id=target::uuid AND role='user';
    IF NOT FOUND THEN RAISE EXCEPTION 'User account unavailable' USING ERRCODE='42501'; END IF;
    result := jsonb_build_object('id',target,'status',data->>'status');
  ELSIF operation_type='topic.save' THEN
    INSERT INTO public.topics(id,title,subtitle,subject,action_label,icon_key,sort_order,status,created_by)
      VALUES(target,data->>'title',coalesce(data->>'subtitle',''),data->>'subject',coalesce(data->>'action_label',''),
        data->>'icon_key',coalesce((data->>'sort_order')::int,0),coalesce(data->>'status','draft'),actor)
      ON CONFLICT(id) DO UPDATE SET title=excluded.title,subtitle=excluded.subtitle,subject=excluded.subject,
        action_label=excluded.action_label,icon_key=excluded.icon_key,sort_order=excluded.sort_order,status=excluded.status
      RETURNING to_jsonb(topics) INTO result;
  ELSIF operation_type='activity.save' THEN
    INSERT INTO public.activities(id,topic_id,created_by) VALUES(target,data->>'topic_id',actor) ON CONFLICT DO NOTHING;
    IF NOT EXISTS(SELECT 1 FROM public.activities WHERE id=target AND topic_id=data->>'topic_id') THEN
      RAISE EXCEPTION 'Activity topic cannot change' USING ERRCODE='22023'; END IF;
    INSERT INTO public.activity_versions(activity_id,content_version,title,stage,prompt,hint_levels,explanation,
      mechanism,mechanism_version,evaluator_version,config,initial_state,skill_ids,created_by)
      VALUES(target,(data->>'content_version')::int,data->>'title',data->>'stage',data->>'prompt',data->'hint_levels',
        data->>'explanation',data->>'mechanism',(data->>'mechanism_version')::int,(data->>'evaluator_version')::int,
        data->'config',data->'initial_state',ARRAY(SELECT jsonb_array_elements_text(coalesce(data->'skill_ids','[]'))),actor)
      ON CONFLICT(activity_id,content_version) DO UPDATE SET title=excluded.title,stage=excluded.stage,prompt=excluded.prompt,
        hint_levels=excluded.hint_levels,explanation=excluded.explanation,mechanism=excluded.mechanism,
        mechanism_version=excluded.mechanism_version,evaluator_version=excluded.evaluator_version,
        config=excluded.config,initial_state=excluded.initial_state,skill_ids=excluded.skill_ids
      RETURNING to_jsonb(activity_versions) INTO result;
  ELSIF operation_type='release.create' THEN
    IF data->>'min_app_version' IS NULL OR data->>'min_app_version' !~ '^\d+\.\d+\.\d+$'
      OR jsonb_typeof(data->'activities') IS DISTINCT FROM 'array'
      OR jsonb_array_length(data->'activities') NOT BETWEEN 1 AND 500
    THEN RAISE EXCEPTION 'Invalid release manifest' USING ERRCODE='22023'; END IF;
    INSERT INTO public.content_releases(id,version_label,min_app_version,created_by)
      VALUES(target::uuid,data->>'version_label',data->>'min_app_version',actor) RETURNING * INTO release;
    INSERT INTO public.release_activities(release_id,activity_id,content_version,topic_id,position,required)
      SELECT release.id,x->>'activity_id',(x->>'content_version')::int,x->>'topic_id',(x->>'position')::int,
        coalesce((x->>'required')::boolean,true) FROM jsonb_array_elements(data->'activities') x;
    result := to_jsonb(release);
  ELSIF operation_type='release.publish' THEN
    SELECT * INTO release FROM public.content_releases WHERE id=target::uuid AND status='draft' FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Draft release unavailable' USING ERRCODE='22023'; END IF;
    -- Only content whose evaluator/config has actually shipped may be published.
    IF EXISTS(SELECT 1 FROM public.release_activities ra JOIN public.activity_versions av
      ON av.activity_id=ra.activity_id AND av.content_version=ra.content_version
      JOIN private.evaluator_versions ev ON ev.mechanism=av.mechanism AND ev.version=av.evaluator_version
      WHERE ra.release_id=release.id AND (ev.status<>'active' OR NOT coalesce(ev.input_schema->'activities' @>
        jsonb_build_array(jsonb_build_object('id',av.activity_id,'content_version',av.content_version,
          'config',av.config,'initial_state',av.initial_state)),false)))
    THEN RAISE EXCEPTION 'Unsupported lesson version or invalid state' USING ERRCODE='22023'; END IF;
    UPDATE public.activity_versions av SET status='published',published_at=now()
      WHERE av.status='draft' AND EXISTS(SELECT 1 FROM public.release_activities ra
        WHERE ra.release_id=release.id AND ra.activity_id=av.activity_id AND ra.content_version=av.content_version);
    SELECT jsonb_agg(to_jsonb(ra) ORDER BY ra.topic_id,ra.position) INTO manifest
      FROM public.release_activities ra WHERE ra.release_id=release.id;
    UPDATE public.content_releases SET status='published',published_at=now(),
      manifest_hash=encode(extensions.digest(convert_to(manifest::text,'UTF8'),'sha256'),'hex')
      WHERE id=release.id RETURNING to_jsonb(content_releases) INTO result;
  ELSIF operation_type='release.retire' THEN
    UPDATE public.content_releases SET status='retired' WHERE id=target::uuid AND status='published'
      RETURNING to_jsonb(content_releases) INTO result;
    IF NOT FOUND THEN RAISE EXCEPTION 'Published release unavailable' USING ERRCODE='22023'; END IF;
  ELSE RAISE EXCEPTION 'Unknown admin operation' USING ERRCODE='22023'; END IF;
  INSERT INTO private.admin_audit_logs(actor_user_id,actor_kind,action,target_type,target_id,request_id,summary)
    VALUES(actor,'admin',operation_type,split_part(operation_type,'.',1),target,operation_id,
      jsonb_build_object('request',jsonb_build_object('operation_type',operation_type,'payload',data),'response',result));
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION private.admin_learning_mutate(uuid,text,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.admin_learning_mutate(uuid,text,jsonb) TO authenticated;
CREATE OR REPLACE FUNCTION public.admin_learning_mutate(operation_id uuid,operation_type text,payload jsonb)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.admin_learning_mutate(operation_id,operation_type,payload) $$;
REVOKE ALL ON FUNCTION public.admin_learning_mutate(uuid,text,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_learning_mutate(uuid,text,jsonb) TO authenticated;
NOTIFY pgrst,'reload schema';
