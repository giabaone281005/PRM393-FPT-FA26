-- Nine additional mobile engines; explicit versioned conversion of packaged lessons.
CREATE OR REPLACE FUNCTION private.valid_extended_slide(engine text,c jsonb)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE SET search_path='' AS $$
DECLARE a jsonb := c->'answer_values'; n integer;
BEGIN
 CASE engine
 WHEN 'numberLine' THEN RETURN private.slide_integer(c->'min',-100,100) AND private.slide_integer(c->'max',-100,100) AND (c->>'min')::int<(c->>'max')::int AND (c->>'max')::int-(c->>'min')::int<=100 AND private.slide_integer(c->'start',(c->>'min')::int,(c->>'max')::int) AND private.slide_integer(c->'target',(c->>'min')::int,(c->>'max')::int);
 WHEN 'fractionBoard' THEN RETURN private.slide_integer(c->'denominator',2,12) AND private.slide_integer(c->'numerator',0,(c->>'denominator')::int);
 WHEN 'numberInput' THEN RETURN private.slide_integer(c->'target_value',-10000,10000);
 WHEN 'quadraticGraph' THEN RETURN private.slide_integer(c->'target_a',-3,3) AND c->'target_a'<>'0'::jsonb AND private.slide_integer(c->'target_b',-5,5) AND private.slide_integer(c->'target_c',-5,5);
 WHEN 'barChart' THEN RETURN private.studio_strings(c->'labels',2,6) AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements_text(c->'labels') v WHERE length(v)>100) AND private.studio_numbers(c->'target_values',0,10) AND jsonb_array_length(c->'target_values')=jsonb_array_length(c->'labels');
 WHEN 'coordinatePoint' THEN RETURN private.slide_integer(c->'target_x',-5,5) AND private.slide_integer(c->'target_y',-5,5);
 WHEN 'vennDiagram' THEN RETURN private.studio_strings(c->'items',2,8) AND private.studio_numbers(c->'answer_values',0,3) AND jsonb_array_length(c->'answer_values')=jsonb_array_length(c->'items');
 WHEN 'fractionCompare' THEN RETURN private.slide_integer(c->'left_denominator',2,12) AND private.slide_integer(c->'right_denominator',2,12) AND private.slide_integer(c->'left_numerator',0,(c->>'left_denominator')::int) AND private.slide_integer(c->'right_numerator',0,(c->>'right_denominator')::int);
 WHEN 'shapeMatch' THEN RETURN c->>'target_shape' IN ('circle','triangle','square','hexagon');

 WHEN 'solid3D' THEN RETURN private.slide_integer(c->'target_volume',1,125) AND EXISTS(SELECT 1 FROM generate_series(1,5) w,generate_series(1,5) h,generate_series(1,5) d WHERE w*h*d=(c->>'target_volume')::int);
 WHEN 'polygonVertices' THEN RETURN private.slide_integer(c->'target_area',1,16) AND EXISTS(SELECT 1 FROM generate_series(1,4) w,generate_series(1,4) h WHERE w*h=(c->>'target_area')::int);
 WHEN 'balanceScale' THEN RETURN private.slide_integer(c->'target_weight',0,10);
 WHEN 'robotRoute' THEN RETURN private.slide_integer(c->'max_commands',6,32);
 WHEN 'loopBuilder' THEN RETURN private.slide_integer(c->'target_repeat',1,4) AND jsonb_typeof(c->'target_body')='array' AND jsonb_array_length(c->'target_body')=2 AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements(c->'target_body') x WHERE x NOT IN ('"R"','"D"','"L"','"U"'));
 WHEN 'globe3D' THEN RETURN private.slide_integer(c->'target_latitude',-90,90) AND private.slide_integer(c->'target_longitude',-180,180) AND (c->>'target_latitude')::int%15=0 AND (c->>'target_longitude')::int%15=0;
 WHEN 'causalLab','causalExperiment' THEN RETURN private.slide_integer(c->'target_product',0,9) AND private.studio_strings(c->'axes',2,2) AND EXISTS(SELECT 1 FROM generate_series(0,3) x,generate_series(0,3) y WHERE x*y=(c->>'target_product')::int);
 WHEN 'symmetryMirror','tangramRotate','strata3D' THEN RETURN true;
 WHEN 'resourceBudget' THEN RETURN private.studio_strings(c->'items',2,6) AND private.studio_numbers(c->'minima',0,10) AND jsonb_array_length(c->'minima')=jsonb_array_length(c->'items') AND (SELECT sum((x#>>'{}')::int) FROM jsonb_array_elements(c->'minima') x)<=10;
 WHEN 'sequenceTiles','evidenceBoard','categorySort','clozeBank','matchPairs' THEN
   IF NOT private.studio_strings(c->'items') OR NOT private.studio_numbers(a,0,7) THEN RETURN false; END IF;
   n:=jsonb_array_length(c->'items');
   IF engine IN ('sequenceTiles','evidenceBoard') THEN
     RETURN jsonb_array_length(a) BETWEEN 1 AND n AND (engine<>'sequenceTiles' OR jsonb_array_length(a)=n)
       AND (SELECT count(DISTINCT x) FROM jsonb_array_elements(a) x)=jsonb_array_length(a)
       AND private.studio_numbers(a,0,n-1);
   END IF;
   RETURN private.studio_strings(c->'choices') AND jsonb_array_length(a)=n AND private.studio_numbers(a,0,jsonb_array_length(c->'choices')-1)
     AND (engine<>'matchPairs' OR (SELECT count(DISTINCT x) FROM jsonb_array_elements(a) x)=n);
 ELSE RETURN false;
 END CASE;
EXCEPTION WHEN OTHERS THEN RETURN false; END $$;

CREATE OR REPLACE FUNCTION private.initial_extended_slide(engine text,c jsonb)
RETURNS jsonb LANGUAGE sql IMMUTABLE SET search_path='' AS $$
 SELECT CASE engine
 WHEN 'numberLine' THEN jsonb_build_object('position',c->'start')
 WHEN 'fractionBoard' THEN '{"selected":[]}'::jsonb
 WHEN 'numberInput' THEN '{"value":""}'::jsonb
 WHEN 'quadraticGraph' THEN '{"a":0,"b":0,"c":0}'::jsonb
 WHEN 'barChart' THEN jsonb_build_object('values',(SELECT jsonb_agg(0) FROM jsonb_array_elements(c->'labels')))
 WHEN 'coordinatePoint' THEN '{"x":0,"y":0}'::jsonb
 WHEN 'vennDiagram' THEN jsonb_build_object('values',(SELECT jsonb_agg(-1) FROM jsonb_array_elements(c->'items')))
 WHEN 'fractionCompare' THEN '{"comparison":-1}'::jsonb
 WHEN 'shapeMatch' THEN '{"shape":""}'::jsonb

 WHEN 'solid3D' THEN '{"width":2,"height":2,"depth":2}'::jsonb
 WHEN 'polygonVertices' THEN '{"points":[[0,0],[4,0],[4,4],[0,4]]}'::jsonb
 WHEN 'symmetryMirror' THEN '{"cells":[]}'::jsonb
 WHEN 'tangramRotate' THEN '{"turns":[1,1],"placed":[false,false]}'::jsonb
 WHEN 'robotRoute' THEN '{"commands":[]}'::jsonb
 WHEN 'loopBuilder' THEN '{"body":["D","R"],"repeat":1}'::jsonb
 WHEN 'balanceScale' THEN '{"weight":0}'::jsonb
 WHEN 'causalLab' THEN '{"x":0,"y":0,"prediction":-1,"trials":[],"observed":[]}'::jsonb
 WHEN 'causalExperiment' THEN '{"x":0,"y":0,"prediction":-1,"trials":[],"observed":[]}'::jsonb
 WHEN 'globe3D' THEN '{"latitude":0,"longitude":0}'::jsonb
 WHEN 'strata3D' THEN '{"layers":[30,10,20]}'::jsonb
 WHEN 'evidenceBoard' THEN '{"selected":[]}'::jsonb
 WHEN 'sequenceTiles' THEN jsonb_build_object('values',(SELECT jsonb_agg(i ORDER BY i DESC) FROM generate_series(0,jsonb_array_length(c->'items')-1) i))
 ELSE jsonb_build_object('values',(SELECT jsonb_agg(CASE WHEN engine='resourceBudget' THEN 0 ELSE -1 END) FROM jsonb_array_elements(c->'items'))) END
$$;

CREATE OR REPLACE FUNCTION private.evaluate_extended_slide(engine text,c jsonb,s jsonb)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE SET search_path='' AS $$
DECLARE p jsonb; cmd jsonb; x integer:=0; y integer:=0; i integer; a jsonb; b jsonb;
BEGIN
 IF jsonb_typeof(s) IS DISTINCT FROM 'object' THEN RETURN false; END IF;
 CASE engine
 WHEN 'numberLine' THEN RETURN private.slide_integer(s->'position',(c->>'min')::int,(c->>'max')::int) AND s->'position'=c->'target';
 WHEN 'fractionBoard' THEN RETURN private.studio_numbers(s->'selected',0,(c->>'denominator')::int-1) AND jsonb_array_length(s->'selected')=(c->>'numerator')::int AND (SELECT count(DISTINCT v) FROM jsonb_array_elements(s->'selected') v)=jsonb_array_length(s->'selected');
 WHEN 'numberInput' THEN RETURN jsonb_typeof(s->'value')='string' AND length(s->>'value')<=6 AND s->>'value' ~ '^-?\d+$' AND (s->>'value')::numeric=(c->>'target_value')::int;
 WHEN 'quadraticGraph' THEN RETURN private.slide_integer(s->'a',-3,3) AND private.slide_integer(s->'b',-5,5) AND private.slide_integer(s->'c',-5,5) AND s->'a'=c->'target_a' AND s->'b'=c->'target_b' AND s->'c'=c->'target_c';
 WHEN 'barChart' THEN RETURN private.studio_numbers(s->'values',0,10) AND s->'values'=c->'target_values';
 WHEN 'coordinatePoint' THEN RETURN private.slide_integer(s->'x',-5,5) AND private.slide_integer(s->'y',-5,5) AND s->'x'=c->'target_x' AND s->'y'=c->'target_y';
 WHEN 'vennDiagram' THEN RETURN private.studio_numbers(s->'values',0,3) AND s->'values'=c->'answer_values';
 WHEN 'fractionCompare' THEN RETURN private.slide_integer(s->'comparison',0,2) AND (s->>'comparison')::int=CASE WHEN (c->>'left_numerator')::int*(c->>'right_denominator')::int<(c->>'right_numerator')::int*(c->>'left_denominator')::int THEN 0 WHEN (c->>'left_numerator')::int*(c->>'right_denominator')::int=(c->>'right_numerator')::int*(c->>'left_denominator')::int THEN 1 ELSE 2 END;
 WHEN 'shapeMatch' THEN RETURN s->'shape'=c->'target_shape';

 WHEN 'solid3D' THEN RETURN private.slide_integer(s->'width',1,5) AND private.slide_integer(s->'height',1,5) AND private.slide_integer(s->'depth',1,5) AND (s->>'width')::int*(s->>'height')::int*(s->>'depth')::int=(c->>'target_volume')::int;
 WHEN 'balanceScale' THEN RETURN private.slide_integer(s->'weight',0,10) AND s->'weight'=c->'target_weight';
 WHEN 'polygonVertices' THEN
   p:=s->'points';
   IF jsonb_typeof(p) IS DISTINCT FROM 'array' OR jsonb_array_length(p)<>4 THEN RETURN false; END IF;
   FOR a IN SELECT value FROM jsonb_array_elements(p) LOOP IF NOT private.studio_numbers(a,0,4) OR jsonb_array_length(a)<>2 THEN RETURN false; END IF; END LOOP;
   RETURN p#>'{0,1}'=p#>'{1,1}' AND p#>'{1,0}'=p#>'{2,0}' AND p#>'{2,1}'=p#>'{3,1}' AND p#>'{3,0}'=p#>'{0,0}'
     AND abs(((p#>>'{1,0}')::int-(p#>>'{0,0}')::int)*((p#>>'{3,1}')::int-(p#>>'{0,1}')::int))=(c->>'target_area')::int;
 WHEN 'symmetryMirror' THEN RETURN private.studio_numbers(s->'cells',0,35) AND jsonb_array_length(s->'cells')=3 AND s->'cells' @> '[11,16,23]'::jsonb;
 WHEN 'tangramRotate' THEN RETURN private.studio_numbers(s->'turns',0,3) AND jsonb_array_length(s->'turns')=2 AND abs((s#>>'{turns,0}')::int-(s#>>'{turns,1}')::int)=2 AND s->'placed'='[true,true]'::jsonb;
 WHEN 'strata3D' THEN RETURN private.studio_numbers(s->'layers',10,30) AND s->'layers'='[10,20,30]'::jsonb;
 WHEN 'globe3D' THEN RETURN private.slide_integer(s->'latitude',-90,90) AND private.slide_integer(s->'longitude',-180,180) AND s->'latitude'=c->'target_latitude' AND s->'longitude'=c->'target_longitude';
 WHEN 'loopBuilder' THEN RETURN private.slide_integer(s->'repeat',1,4) AND s->'repeat'=c->'target_repeat' AND s->'body'=c->'target_body';
 WHEN 'robotRoute' THEN
   IF jsonb_typeof(s->'commands') IS DISTINCT FROM 'array' OR jsonb_array_length(s->'commands')>(c->>'max_commands')::int THEN RETURN false; END IF;
   FOR cmd IN SELECT value FROM jsonb_array_elements(s->'commands') LOOP
     CASE cmd WHEN '"R"' THEN x:=x+1; WHEN '"L"' THEN x:=x-1; WHEN '"D"' THEN y:=y+1; WHEN '"U"' THEN y:=y-1; ELSE RETURN false; END CASE;
     IF x<0 OR x>3 OR y<0 OR y>3 OR (x=1 AND y=1) THEN RETURN false; END IF;
   END LOOP;
   RETURN x=3 AND y=3;
 WHEN 'causalLab','causalExperiment' THEN RETURN private.slide_integer(s->'x',0,3) AND private.slide_integer(s->'y',0,3) AND private.slide_integer(s->'prediction',0,9) AND private.studio_numbers(s->'observed',0,9)
   AND (s->>'x')::int*(s->>'y')::int=(c->>'target_product')::int AND s->'prediction'=c->'target_product' AND s->'observed'=jsonb_build_array(s->'x',s->'y',c->'target_product');
 WHEN 'resourceBudget' THEN
   a:=s->'values';
   IF NOT private.studio_numbers(a,0,10) OR jsonb_array_length(a)<>jsonb_array_length(c->'items') OR (SELECT sum((v#>>'{}')::int) FROM jsonb_array_elements(a) v)<>10 THEN RETURN false; END IF;
   FOR i IN 0..jsonb_array_length(a)-1 LOOP IF (a->>i)::int<(c->'minima'->>i)::int THEN RETURN false; END IF; END LOOP;
   RETURN true;
 WHEN 'evidenceBoard' THEN
   IF NOT private.studio_numbers(s->'selected',0,7) THEN RETURN false; END IF;
   SELECT jsonb_agg(v ORDER BY v) INTO a FROM jsonb_array_elements(s->'selected') v;
   SELECT jsonb_agg(v ORDER BY v) INTO b FROM jsonb_array_elements(c->'answer_values') v;
   RETURN a=b;
 WHEN 'sequenceTiles','categorySort','clozeBank','matchPairs' THEN RETURN private.studio_numbers(s->'values',0,7) AND s->'values'=c->'answer_values';
 ELSE RETURN false;
 END CASE;
EXCEPTION WHEN OTHERS THEN RETURN false; END $$;

CREATE OR REPLACE FUNCTION private.admin_content_mutate(operation_id uuid,payload jsonb) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor('admin'); item public.activities; previous public.activity_versions;
  edit public.lesson_edits; op private.admin_audit_logs; base public.content_releases;
  rid uuid := gen_random_uuid(); version_number integer; result jsonb; manifest jsonb; is_slides boolean; converting boolean:=false;
  request_hash text := encode(extensions.digest(admin_content_mutate.payload::text,'sha256'),'hex');
BEGIN
  IF operation_id IS NULL OR jsonb_typeof(admin_content_mutate.payload) IS DISTINCT FROM 'object' OR octet_length(admin_content_mutate.payload::text)>100000
    THEN RAISE EXCEPTION 'Invalid content' USING ERRCODE='22023'; END IF;
  -- Serialize catalog publication globally so simultaneous admins cannot lose changes.
  PERFORM pg_advisory_xact_lock(750040);
  SELECT * INTO op FROM private.admin_audit_logs WHERE actor_user_id=actor AND request_id=operation_id;
  IF FOUND THEN
    IF op.action<>'lesson.save' OR op.summary->>'request_hash' IS DISTINCT FROM request_hash THEN
      RAISE EXCEPTION 'Operation mismatch' USING ERRCODE='22023'; END IF;
    RETURN op.summary->'response';
  END IF;
  IF admin_content_mutate.payload->>'id' !~ '^[a-z][a-z0-9-]{0,79}$' OR admin_content_mutate.payload->>'id' IS NULL
    OR NOT EXISTS(SELECT 1 FROM public.topics WHERE id=admin_content_mutate.payload->>'topic_id')
    OR admin_content_mutate.payload->>'status' IS NULL OR admin_content_mutate.payload->>'status' NOT IN ('active','archived')
    THEN RAISE EXCEPTION 'Invalid lesson metadata' USING ERRCODE='22023'; END IF;
  SELECT * INTO item FROM public.activities WHERE id=admin_content_mutate.payload->>'id';
  IF FOUND AND item.topic_id IS DISTINCT FROM admin_content_mutate.payload->>'topic_id' THEN
    RAISE EXCEPTION 'Activity topic cannot change' USING ERRCODE='22023'; END IF;
  SELECT * INTO edit FROM public.lesson_edits WHERE activity_id=admin_content_mutate.payload->>'id';
  IF coalesce(edit.revision,0) IS DISTINCT FROM (admin_content_mutate.payload->>'revision')::int OR NOT admin_content_mutate.payload ? 'revision' THEN
    RAISE EXCEPTION 'Content revision conflict' USING ERRCODE='PT409'; END IF;
  SELECT * INTO previous FROM public.activity_versions WHERE activity_id=admin_content_mutate.payload->>'id' ORDER BY content_version DESC LIMIT 1;
  is_slides := coalesce(admin_content_mutate.payload->>'mechanism',previous.mechanism,'reasonedChoice')='slideLesson';
  converting := previous.activity_id IS NOT NULL AND previous.mechanism<>'slideLesson' AND is_slides AND coalesce(private.slide_integer(admin_content_mutate.payload->'convert_from_version',1,2147483647) AND (admin_content_mutate.payload->>'convert_from_version')::int=previous.content_version,false);
  IF is_slides AND EXISTS(SELECT 1 FROM public.lesson_builder_drafts WHERE id=admin_content_mutate.payload->>'id'
    AND revision IS DISTINCT FROM (admin_content_mutate.payload->>'builder_revision')::int)
    THEN RAISE EXCEPTION 'Builder revision conflict' USING ERRCODE='PT409'; END IF;
  -- Packaged evaluators remain immutable; reasonedChoice can migrate to the
  -- declarative authored evaluator in a new version without altering old sessions.
  IF previous.activity_id IS NOT NULL AND previous.evaluator_version NOT IN (3,4)
    AND previous.mechanism<>'reasonedChoice' AND NOT converting
    AND ((admin_content_mutate.payload ? 'config' AND admin_content_mutate.payload->'config' IS DISTINCT FROM previous.config)
      OR (admin_content_mutate.payload ? 'mechanism' AND admin_content_mutate.payload->>'mechanism' IS DISTINCT FROM previous.mechanism))
    THEN RAISE EXCEPTION 'Packaged engine configuration is immutable' USING ERRCODE='22023'; END IF;
  IF previous.activity_id IS NULL OR previous.evaluator_version IN (3,4) OR converting
    OR (previous.mechanism='reasonedChoice' AND admin_content_mutate.payload->>'mechanism'='reasonedChoice') THEN
    IF (is_slides AND NOT private.valid_slide_lesson(admin_content_mutate.payload->'config'))
      OR (NOT is_slides AND NOT private.valid_authored_choice(admin_content_mutate.payload->'config')) THEN
      RAISE EXCEPTION 'Invalid engine configuration' USING ERRCODE='22023'; END IF;
    INSERT INTO public.activities(id,topic_id,status,created_by)
      VALUES(admin_content_mutate.payload->>'id',admin_content_mutate.payload->>'topic_id','active',actor) ON CONFLICT DO NOTHING;
    version_number := coalesce(previous.content_version,0)+1;
    INSERT INTO public.activity_versions(activity_id,content_version,title,stage,prompt,hint_levels,explanation,
      mechanism,mechanism_version,evaluator_version,config,initial_state,status,published_at,created_by)
      VALUES(admin_content_mutate.payload->>'id',version_number,admin_content_mutate.payload->>'title',admin_content_mutate.payload->>'stage',admin_content_mutate.payload->>'prompt',
        jsonb_build_array(admin_content_mutate.payload->>'hint'),admin_content_mutate.payload->>'explanation',CASE WHEN is_slides THEN 'slideLesson' ELSE 'reasonedChoice' END,1,
        CASE WHEN is_slides THEN 4 ELSE 3 END,admin_content_mutate.payload->'config',
        CASE WHEN is_slides THEN private.initial_slide_state(admin_content_mutate.payload->'config') ELSE '{"answer":-1,"reason":-1}'::jsonb END,'draft',NULL,actor);
    UPDATE public.activity_versions SET status='published',published_at=now()
      WHERE activity_id=admin_content_mutate.payload->>'id' AND content_version=version_number;
  END IF;
  INSERT INTO public.lesson_edits(activity_id,title,stage,prompt,hint,explanation,status,sort_order)
    VALUES(admin_content_mutate.payload->>'id',admin_content_mutate.payload->>'title',admin_content_mutate.payload->>'stage',admin_content_mutate.payload->>'prompt',admin_content_mutate.payload->>'hint',
      admin_content_mutate.payload->>'explanation',admin_content_mutate.payload->>'status',(admin_content_mutate.payload->>'sort_order')::int)
    ON CONFLICT(activity_id) DO UPDATE SET title=excluded.title,stage=excluded.stage,prompt=excluded.prompt,
      hint=excluded.hint,explanation=excluded.explanation,status=excluded.status,sort_order=excluded.sort_order,
      revision=lesson_edits.revision+1,updated_at=now();
  SELECT * INTO base FROM public.content_releases WHERE status='published' ORDER BY published_at DESC,id DESC LIMIT 1;
  INSERT INTO public.content_releases(id,version_label,min_app_version,created_by)
    VALUES(rid,'admin-'||rid::text,CASE WHEN string_to_array(base.min_app_version,'.')::int[]>=ARRAY[1,3,6] THEN base.min_app_version WHEN is_slides THEN '1.3.6' WHEN string_to_array(base.min_app_version,'.')::int[]>=ARRAY[1,3,3] THEN base.min_app_version ELSE '1.3.3' END,actor);
  INSERT INTO public.release_activities(release_id,activity_id,content_version,topic_id,position,required)
    SELECT rid,a.id,v.content_version,a.topic_id,
      (row_number() OVER(PARTITION BY a.topic_id ORDER BY coalesce(e.sort_order,ra.position,0),a.id)-1)::int,true
    FROM public.activities a
    JOIN LATERAL (SELECT * FROM public.activity_versions x WHERE x.activity_id=a.id AND x.status='published'
      ORDER BY content_version DESC LIMIT 1) v ON true
    LEFT JOIN public.lesson_edits e ON e.activity_id=a.id
    LEFT JOIN public.release_activities ra ON ra.release_id=base.id AND ra.activity_id=a.id
    WHERE coalesce(e.status,'active')='active' AND (ra.activity_id IS NOT NULL OR v.evaluator_version IN (3,4) OR e.status='active');
  SELECT jsonb_agg(to_jsonb(ra) ORDER BY topic_id,position) INTO manifest FROM public.release_activities ra WHERE release_id=rid;
  UPDATE public.content_releases SET status='published',published_at=clock_timestamp(),
    manifest_hash=encode(extensions.digest(manifest::text,'sha256'),'hex') WHERE id=rid;
  UPDATE public.lesson_builder_drafts SET status='published' WHERE id=admin_content_mutate.payload->>'id';
  result := jsonb_build_object('release_id',rid,'id',admin_content_mutate.payload->>'id','revision',coalesce(edit.revision,0)+1);
  INSERT INTO private.admin_audit_logs(actor_user_id,actor_kind,action,target_type,target_id,request_id,summary)
    VALUES(actor,'admin','lesson.save','activity',admin_content_mutate.payload->>'id',operation_id,
      jsonb_build_object('request_hash',request_hash,'response',result));
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION private.valid_extended_slide(text,jsonb),private.initial_extended_slide(text,jsonb),private.evaluate_extended_slide(text,jsonb,jsonb) FROM PUBLIC,anon,authenticated;
NOTIFY pgrst,'reload schema';
