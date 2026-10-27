-- Publish the existing baseline only after evaluator parity and transactional
-- ownership/reward/cursor tests, and deployment of learning-api, have passed.
DO $publish$
DECLARE release public.content_releases; manifest jsonb;
BEGIN
  SELECT * INTO release FROM public.content_releases
    WHERE version_label='frontend-baseline-2026-10-26' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Baseline release is missing'; END IF;
  IF release.status='draft' THEN
    IF EXISTS(SELECT 1 FROM public.release_activities ra JOIN public.activity_versions av
      ON av.activity_id=ra.activity_id AND av.content_version=ra.content_version
      WHERE ra.release_id=release.id AND NOT private.supported_activity(av))
    THEN RAISE EXCEPTION 'Baseline does not match deployed evaluators'; END IF;
    UPDATE public.activity_versions av SET status='published',published_at=now()
      WHERE av.status='draft' AND EXISTS(SELECT 1 FROM public.release_activities ra
        WHERE ra.release_id=release.id AND ra.activity_id=av.activity_id AND ra.content_version=av.content_version);
    SELECT jsonb_agg(to_jsonb(ra) ORDER BY ra.topic_id,ra.position) INTO manifest
      FROM public.release_activities ra WHERE ra.release_id=release.id;
    UPDATE public.content_releases SET status='published',published_at=now(),
      manifest_hash=encode(extensions.digest(convert_to(manifest::text,'UTF8'),'sha256'),'hex') WHERE id=release.id;
    INSERT INTO private.admin_audit_logs(actor_kind,action,target_type,target_id,request_id,summary)
      VALUES('system','content.publish','release',release.id::text,gen_random_uuid(),
        jsonb_build_object('version_label',release.version_label,'reason','Verified server evaluator rollout'));
  END IF;
END $publish$;
NOTIFY pgrst,'reload schema';
