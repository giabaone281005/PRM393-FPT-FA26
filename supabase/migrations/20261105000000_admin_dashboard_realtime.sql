-- Additive dashboard API. The public wrapper runs with the caller's identity;
-- all privileged reads re-check the active admin role in the database.
CREATE OR REPLACE FUNCTION private.admin_dashboard_read(
  section text, search_text text, page_offset integer, page_size integer
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor('admin'); result jsonb; total bigint;
  needle text := '%' || btrim(coalesce(search_text,'')) || '%';
BEGIN
  IF section IS NULL OR length(coalesce(search_text,''))>100 OR page_offset IS NULL
    OR page_size IS NULL OR page_offset NOT BETWEEN 0 AND 100000 OR page_size NOT BETWEEN 1 AND 100
    THEN RAISE EXCEPTION 'Invalid page' USING ERRCODE='22023'; END IF;
  IF section='overview' THEN
    RETURN jsonb_build_object(
      'users',(SELECT count(*) FROM private.account_access x JOIN public.accounts a ON a.id=x.user_id WHERE x.role='user' AND a.deleted_at IS NULL),
      'active_users',(SELECT count(*) FROM private.account_access x JOIN public.accounts a ON a.id=x.user_id WHERE x.role='user' AND x.status='active' AND a.deleted_at IS NULL),
      'suspended_users',(SELECT count(*) FROM private.account_access x JOIN public.accounts a ON a.id=x.user_id WHERE x.role='user' AND x.status='suspended' AND a.deleted_at IS NULL),
      'topics',(SELECT count(*) FROM public.topics),
      'profiles',(SELECT count(*) FROM public.learner_profiles WHERE deleted_at IS NULL),
      'sessions',(SELECT count(*) FROM public.learning_sessions),
      'verified_completions',(SELECT count(*) FROM public.topic_completions WHERE source='verified'));
  ELSIF section='accounts' THEN
    SELECT count(*) INTO total FROM public.accounts a JOIN private.account_access x ON x.user_id=a.id
      JOIN auth.users u ON u.id=a.id WHERE x.role='user' AND a.deleted_at IS NULL
      AND (a.display_name ILIKE needle OR coalesce(u.email,'') ILIKE needle OR a.id::text ILIKE needle);
    SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]') INTO result FROM (
      SELECT a.id,a.display_name,u.email,a.locale,a.timezone,a.created_at,x.status
      FROM public.accounts a JOIN private.account_access x ON x.user_id=a.id JOIN auth.users u ON u.id=a.id
      WHERE x.role='user' AND a.deleted_at IS NULL
      AND (a.display_name ILIKE needle OR coalesce(u.email,'') ILIKE needle OR a.id::text ILIKE needle)
      ORDER BY a.created_at DESC,a.id LIMIT page_size OFFSET page_offset) r;
  ELSIF section='topics' THEN
    SELECT count(*) INTO total FROM public.topics t
      WHERE t.title ILIKE needle OR t.subject ILIKE needle OR t.id ILIKE needle;
    SELECT coalesce(jsonb_agg(to_jsonb(r)),'[]') INTO result FROM (
      SELECT t.*, (SELECT count(*) FROM public.activities a WHERE a.topic_id=t.id) AS activity_count
      FROM public.topics t WHERE t.title ILIKE needle OR t.subject ILIKE needle OR t.id ILIKE needle
      ORDER BY t.sort_order,t.id LIMIT page_size OFFSET page_offset) r;
  ELSE RAISE EXCEPTION 'Unknown admin section' USING ERRCODE='22023'; END IF;
  RETURN jsonb_build_object('items',result,'total',total,'offset',page_offset,'limit',page_size);
END $$;
REVOKE ALL ON FUNCTION private.admin_dashboard_read(text,text,integer,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.admin_dashboard_read(text,text,integer,integer) TO authenticated;
CREATE OR REPLACE FUNCTION public.admin_dashboard_read(
  section text DEFAULT 'overview', search_text text DEFAULT '', page_offset integer DEFAULT 0, page_size integer DEFAULT 25
) RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$
  SELECT private.admin_dashboard_read(section,search_text,page_offset,page_size)
$$;
REVOKE ALL ON FUNCTION public.admin_dashboard_read(text,text,integer,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_dashboard_read(text,text,integer,integer) TO authenticated;

-- Broadcast only invalidation signals, never account data or email addresses.
-- Existing policies/publication/RLS on business tables are left intact.
CREATE OR REPLACE FUNCTION private.notify_admin_dashboard()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
  PERFORM realtime.send(jsonb_build_object('source',TG_TABLE_NAME),'changed','matlingo:admin',true);
  RETURN NULL;
END $$;
REVOKE ALL ON FUNCTION private.notify_admin_dashboard() FROM PUBLIC,anon,authenticated;
DO $$
DECLARE target text;
BEGIN
  FOREACH target IN ARRAY ARRAY['public.accounts','private.account_access','public.topics',
    'public.learner_profiles','public.learning_sessions','public.topic_completions'] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS admin_dashboard_changed ON %s',target);
    EXECUTE format('CREATE TRIGGER admin_dashboard_changed AFTER INSERT OR UPDATE OR DELETE ON %s FOR EACH STATEMENT EXECUTE FUNCTION private.notify_admin_dashboard()',target);
  END LOOP;
END $$;
-- realtime.messages is Supabase-managed and already has RLS. Only our policy is changed.
DROP POLICY IF EXISTS matlingo_admin_receive ON realtime.messages;
CREATE POLICY matlingo_admin_receive ON realtime.messages FOR SELECT TO authenticated
  USING (extension='broadcast' AND (SELECT realtime.topic())='matlingo:admin' AND private.has_role('admin'));
