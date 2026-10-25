-- Explicitly authorized application database reset, 2026-10-26.
-- Preserve Auth identities; retain existing admin assignments only.
CREATE TEMP TABLE matlingo_access_snapshot ON COMMIT DROP AS
SELECT u.id AS user_id, coalesce(bool_or(r.role::text = 'admin'),false) AS was_admin
FROM auth.users u LEFT JOIN public.user_roles r ON r.user_id=u.id GROUP BY u.id;
DROP SCHEMA private CASCADE;
DROP SCHEMA public CASCADE;
CREATE SCHEMA public AUTHORIZATION postgres;
CREATE SCHEMA private AUTHORIZATION postgres;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA public,private TO authenticated,service_role;
GRANT USAGE ON SCHEMA public TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon,authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA private REVOKE ALL ON TABLES FROM anon,authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA private REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

CREATE TABLE private.account_access (
user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
role text NOT NULL DEFAULT 'user' CHECK(role IN ('admin','user')),
status text NOT NULL DEFAULT 'active' CHECK(status IN ('active','suspended','deleting')),
created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE private.account_access ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.account_access FROM anon,authenticated;

CREATE TABLE public.accounts (
id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
display_name text NOT NULL CHECK(length(btrim(display_name)) BETWEEN 1 AND 80),
locale text NOT NULL DEFAULT 'vi', timezone text NOT NULL DEFAULT 'Asia/Bangkok',
avatar_asset_id uuid, created_at timestamptz NOT NULL DEFAULT now(),
updated_at timestamptz NOT NULL DEFAULT now(), deleted_at timestamptz
);
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.accounts FROM anon,authenticated;

CREATE TABLE public.learner_profiles (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
owner_user_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
name text NOT NULL CHECK(length(btrim(name)) BETWEEN 1 AND 60),
daily_minutes smallint NOT NULL DEFAULT 10 CHECK(daily_minutes BETWEEN 1 AND 120),
onboarded_at timestamptz, interest_topic_ids text[] NOT NULL DEFAULT '{}',
revision bigint NOT NULL DEFAULT 1 CHECK(revision>0),
created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
deleted_at timestamptz, UNIQUE(id,owner_user_id)
);
ALTER TABLE public.learner_profiles ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.learner_profiles FROM anon,authenticated;

CREATE TABLE public.assets (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
owner_user_id uuid REFERENCES public.accounts(id),
bucket_id text NOT NULL CHECK(bucket_id IN ('learning-assets','user-avatars')),
object_path text NOT NULL CHECK(length(object_path)>0),
kind text NOT NULL CHECK(kind IN ('image','texture','model','avatar')),
mime_type text NOT NULL, byte_size bigint NOT NULL CHECK(byte_size>=0),
sha256 text NOT NULL CHECK(sha256 ~ '^[0-9a-f]{64}$'),
source_url text, license text, attribution text,
status text NOT NULL DEFAULT 'uploading' CHECK(status IN ('uploading','ready','archived')),
created_by uuid REFERENCES public.accounts(id) ON DELETE SET NULL,
created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
UNIQUE(bucket_id,object_path),
CHECK((bucket_id='user-avatars' AND kind='avatar' AND owner_user_id IS NOT NULL) OR
(bucket_id='learning-assets' AND kind<>'avatar' AND owner_user_id IS NULL))
);
ALTER TABLE public.assets ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.assets FROM anon,authenticated;

CREATE TABLE public.topics (
id text PRIMARY KEY CHECK(id ~ '^[a-z][a-z0-9-]*$'),
title text NOT NULL CHECK(length(title) BETWEEN 1 AND 160), subtitle text NOT NULL DEFAULT '',
subject text NOT NULL, action_label text NOT NULL DEFAULT '', icon_key text NOT NULL,
sort_order integer NOT NULL CHECK(sort_order>=0),
status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','active','archived')),
created_by uuid REFERENCES public.accounts(id) ON DELETE SET NULL,
created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.topics FROM anon,authenticated;

CREATE TABLE public.activities (
id text PRIMARY KEY, topic_id text NOT NULL REFERENCES public.topics(id),
status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','active','archived')),
created_by uuid REFERENCES public.accounts(id) ON DELETE SET NULL,
created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
UNIQUE(id,topic_id)
);
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.activities FROM anon,authenticated;

CREATE TABLE private.evaluator_versions (
mechanism text NOT NULL, version integer NOT NULL CHECK(version>0),
handler_key text NOT NULL, implementation_hash text NOT NULL CHECK(implementation_hash ~ '^[0-9a-f]{64}$'),
input_schema jsonb NOT NULL CHECK(jsonb_typeof(input_schema)='object'),
status text NOT NULL DEFAULT 'testing' CHECK(status IN ('testing','active','retired')),
created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(mechanism,version)
);
ALTER TABLE private.evaluator_versions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.evaluator_versions FROM anon,authenticated;

CREATE TABLE public.activity_versions (
activity_id text NOT NULL REFERENCES public.activities(id),
content_version integer NOT NULL CHECK(content_version>0),
title text NOT NULL CHECK(length(title) BETWEEN 1 AND 160), stage text NOT NULL,
prompt text NOT NULL, hint_levels jsonb NOT NULL CHECK(jsonb_typeof(hint_levels)='array' AND jsonb_array_length(hint_levels) BETWEEN 1 AND 3),
explanation text NOT NULL, mechanism text NOT NULL,
mechanism_version integer NOT NULL CHECK(mechanism_version>0),
evaluator_version integer NOT NULL CHECK(evaluator_version>0),
config jsonb NOT NULL DEFAULT '{}' CHECK(jsonb_typeof(config)='object'),
initial_state jsonb NOT NULL CHECK(jsonb_typeof(initial_state)='object'),
skill_ids text[] NOT NULL DEFAULT '{}',
status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','published','archived')),
created_by uuid REFERENCES public.accounts(id) ON DELETE SET NULL,
created_at timestamptz NOT NULL DEFAULT now(), published_at timestamptz,
PRIMARY KEY(activity_id,content_version),
FOREIGN KEY(mechanism,evaluator_version) REFERENCES private.evaluator_versions(mechanism,version),
CHECK(status<>'published' OR published_at IS NOT NULL)
);
ALTER TABLE public.activity_versions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.activity_versions FROM anon,authenticated;

CREATE TABLE public.content_releases (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
version_label text NOT NULL UNIQUE,
status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','published','retired')),
min_app_version text NOT NULL CHECK(min_app_version ~ '^[0-9]+\.[0-9]+\.[0-9]+$'),
manifest_hash text CHECK(manifest_hash ~ '^[0-9a-f]{64}$'),
created_by uuid REFERENCES public.accounts(id) ON DELETE SET NULL,
created_at timestamptz NOT NULL DEFAULT now(), published_at timestamptz,
CHECK(status='draft' OR (manifest_hash IS NOT NULL AND published_at IS NOT NULL))
);
ALTER TABLE public.content_releases ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.content_releases FROM anon,authenticated;

CREATE TABLE public.release_activities (
release_id uuid NOT NULL REFERENCES public.content_releases(id),
activity_id text NOT NULL, content_version integer NOT NULL,
topic_id text NOT NULL REFERENCES public.topics(id), position integer NOT NULL CHECK(position>=0),
required boolean NOT NULL DEFAULT true,
PRIMARY KEY(release_id,activity_id), UNIQUE(release_id,topic_id,position),
UNIQUE(release_id,activity_id,content_version),
FOREIGN KEY(activity_id,content_version) REFERENCES public.activity_versions(activity_id,content_version),
FOREIGN KEY(activity_id,topic_id) REFERENCES public.activities(id,topic_id)
);
ALTER TABLE public.release_activities ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.release_activities FROM anon,authenticated;

CREATE TABLE public.activity_assets (
activity_id text NOT NULL, content_version integer NOT NULL,
slot text NOT NULL, asset_id uuid NOT NULL REFERENCES public.assets(id), required boolean NOT NULL DEFAULT false,
PRIMARY KEY(activity_id,content_version,slot),
FOREIGN KEY(activity_id,content_version) REFERENCES public.activity_versions(activity_id,content_version)
);
ALTER TABLE public.activity_assets ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.activity_assets FROM anon,authenticated;

CREATE TABLE public.learning_sessions (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
profile_id uuid NOT NULL, owner_user_id uuid NOT NULL,
topic_id text NOT NULL REFERENCES public.topics(id), release_id uuid REFERENCES public.content_releases(id),
source text NOT NULL DEFAULT 'mobile' CHECK(source IN ('mobile','legacy_import')),
status text NOT NULL DEFAULT 'in_progress' CHECK(status IN ('in_progress','pending','verified','legacy_imported','abandoned')),
device_id uuid, started_at timestamptz NOT NULL, received_at timestamptz NOT NULL DEFAULT now(),
completed_at timestamptz, hints_used integer NOT NULL DEFAULT 0 CHECK(hints_used>=0),
attempts_count integer NOT NULL DEFAULT 0 CHECK(attempts_count>=0),
active_ms bigint NOT NULL DEFAULT 0 CHECK(active_ms>=0),
revision bigint NOT NULL DEFAULT 1 CHECK(revision>0),
created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
FOREIGN KEY(profile_id,owner_user_id) REFERENCES public.learner_profiles(id,owner_user_id),
UNIQUE(id,profile_id,owner_user_id), UNIQUE(id,release_id),
CHECK(source='legacy_import' OR release_id IS NOT NULL)
);
ALTER TABLE public.learning_sessions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.learning_sessions FROM anon,authenticated;

CREATE TABLE public.lesson_drafts (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
session_id uuid NOT NULL, profile_id uuid NOT NULL, owner_user_id uuid NOT NULL,
current_activity_id text REFERENCES public.activities(id), state_schema_version integer NOT NULL DEFAULT 1 CHECK(state_schema_version>0),
snapshot jsonb NOT NULL CHECK(jsonb_typeof(snapshot)='object' AND octet_length(snapshot::text)<=262144),
base_revision bigint NOT NULL CHECK(base_revision>=0), revision bigint NOT NULL DEFAULT 1 CHECK(revision>0),
conflict_of_draft_id uuid REFERENCES public.lesson_drafts(id),
created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), deleted_at timestamptz,
FOREIGN KEY(session_id,profile_id,owner_user_id) REFERENCES public.learning_sessions(id,profile_id,owner_user_id)
);
ALTER TABLE public.lesson_drafts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.lesson_drafts FROM anon,authenticated;

CREATE TABLE public.activity_attempts (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
operation_id uuid NOT NULL, session_id uuid NOT NULL, profile_id uuid NOT NULL, owner_user_id uuid NOT NULL,
release_id uuid NOT NULL, activity_id text NOT NULL, content_version integer NOT NULL,
submitted_state jsonb NOT NULL CHECK(jsonb_typeof(submitted_state)='object' AND octet_length(submitted_state::text)<=65536),
hint_level smallint NOT NULL DEFAULT 0 CHECK(hint_level BETWEEN 0 AND 3),
evaluation_status text NOT NULL CHECK(evaluation_status IN ('verified','unsupported','rejected')),
is_correct boolean, misconception_codes text[] NOT NULL DEFAULT '{}', satisfied_constraints text[] NOT NULL DEFAULT '{}',
feedback_key text, evaluator_version integer, attempted_at timestamptz, received_at timestamptz NOT NULL DEFAULT now(),
UNIQUE(owner_user_id,operation_id),
FOREIGN KEY(session_id,profile_id,owner_user_id) REFERENCES public.learning_sessions(id,profile_id,owner_user_id),
FOREIGN KEY(session_id,release_id) REFERENCES public.learning_sessions(id,release_id),
FOREIGN KEY(release_id,activity_id,content_version) REFERENCES public.release_activities(release_id,activity_id,content_version),
CHECK(evaluation_status<>'verified' OR (is_correct IS NOT NULL AND evaluator_version IS NOT NULL))
);
ALTER TABLE public.activity_attempts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.activity_attempts FROM anon,authenticated;

CREATE TABLE public.topic_completions (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
profile_id uuid NOT NULL, owner_user_id uuid NOT NULL, topic_id text NOT NULL REFERENCES public.topics(id),
release_id uuid REFERENCES public.content_releases(id), session_id uuid NOT NULL,
source text NOT NULL CHECK(source IN ('verified','legacy_import')), completed_at timestamptz NOT NULL,
verified_at timestamptz, created_at timestamptz NOT NULL DEFAULT now(),
FOREIGN KEY(session_id,profile_id,owner_user_id) REFERENCES public.learning_sessions(id,profile_id,owner_user_id),
CHECK(source<>'verified' OR (verified_at IS NOT NULL AND release_id IS NOT NULL)),
UNIQUE(id,profile_id,owner_user_id,topic_id)
);
ALTER TABLE public.topic_completions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.topic_completions FROM anon,authenticated;

CREATE TABLE public.xp_ledger (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
profile_id uuid NOT NULL, owner_user_id uuid NOT NULL,
reward_key text NOT NULL, topic_id text NOT NULL REFERENCES public.topics(id), completion_id uuid NOT NULL,
source text NOT NULL CHECK(source IN ('first_completion','legacy_import')),
delta integer NOT NULL DEFAULT 30 CHECK(delta=30), created_at timestamptz NOT NULL DEFAULT now(),
UNIQUE(profile_id,reward_key),
FOREIGN KEY(profile_id,owner_user_id) REFERENCES public.learner_profiles(id,owner_user_id),
FOREIGN KEY(completion_id,profile_id,owner_user_id,topic_id) REFERENCES public.topic_completions(id,profile_id,owner_user_id,topic_id),
CHECK(reward_key='topic:'||topic_id||':first_completion')
);
ALTER TABLE public.xp_ledger ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.xp_ledger FROM anon,authenticated;

CREATE TABLE public.activity_events (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(), operation_id uuid NOT NULL,
session_id uuid NOT NULL, profile_id uuid NOT NULL, owner_user_id uuid NOT NULL,
event_type text NOT NULL CHECK(event_type IN ('active_time','hint_opened')),
activity_id text REFERENCES public.activities(id),
active_ms_delta bigint NOT NULL DEFAULT 0 CHECK(active_ms_delta>=0),
hint_level smallint NOT NULL DEFAULT 0 CHECK(hint_level BETWEEN 0 AND 3),
occurred_at timestamptz NOT NULL, local_date date NOT NULL, timezone text,
utc_offset_minutes smallint CHECK(utc_offset_minutes BETWEEN -840 AND 840),
received_at timestamptz NOT NULL DEFAULT now(), UNIQUE(owner_user_id,operation_id),
FOREIGN KEY(session_id,profile_id,owner_user_id) REFERENCES public.learning_sessions(id,profile_id,owner_user_id)
);
ALTER TABLE public.activity_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.activity_events FROM anon,authenticated;

CREATE TABLE private.sync_heads (
owner_user_id uuid PRIMARY KEY REFERENCES public.accounts(id) ON DELETE CASCADE,
revision bigint NOT NULL DEFAULT 0 CHECK(revision>=0),
min_available_revision bigint NOT NULL DEFAULT 0 CHECK(min_available_revision>=0 AND min_available_revision<=revision),
updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE private.sync_heads ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.sync_heads FROM anon,authenticated;

CREATE TABLE private.sync_operations (
owner_user_id uuid NOT NULL REFERENCES public.accounts(id),
operation_id uuid NOT NULL, profile_id uuid, device_id uuid, operation_type text NOT NULL,
payload_hash text NOT NULL CHECK(payload_hash ~ '^[0-9a-f]{64}$'),
status text NOT NULL CHECK(status IN ('applied','conflict','rejected')),
response jsonb NOT NULL CHECK(jsonb_typeof(response)='object'),
server_revision bigint, created_at timestamptz NOT NULL DEFAULT now(),
PRIMARY KEY(owner_user_id,operation_id),
FOREIGN KEY(profile_id,owner_user_id) REFERENCES public.learner_profiles(id,owner_user_id)
);
ALTER TABLE private.sync_operations ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.sync_operations FROM anon,authenticated;

CREATE TABLE private.sync_changes (
owner_user_id uuid NOT NULL REFERENCES public.accounts(id),
revision bigint NOT NULL CHECK(revision>0), change_index integer NOT NULL CHECK(change_index>=0),
entity_type text NOT NULL, entity_id text NOT NULL, action text NOT NULL CHECK(action IN ('upsert','delete')),
payload jsonb, created_at timestamptz NOT NULL DEFAULT now(),
PRIMARY KEY(owner_user_id,revision,change_index), CHECK(action<>'delete' OR payload IS NULL)
);
ALTER TABLE private.sync_changes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.sync_changes FROM anon,authenticated;

CREATE TABLE private.legacy_imports (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(), owner_user_id uuid NOT NULL REFERENCES public.accounts(id),
source_profile_key text NOT NULL, target_profile_id uuid,
source_schema_version integer NOT NULL, snapshot_hash text NOT NULL CHECK(snapshot_hash ~ '^[0-9a-f]{64}$'),
payload jsonb, status text NOT NULL CHECK(status IN ('pending','completed','failed')),
result jsonb NOT NULL DEFAULT '{}' CHECK(jsonb_typeof(result)='object'), error_code text,
created_at timestamptz NOT NULL DEFAULT now(), completed_at timestamptz, payload_expires_at timestamptz,
UNIQUE(owner_user_id,source_profile_key),
FOREIGN KEY(target_profile_id,owner_user_id) REFERENCES public.learner_profiles(id,owner_user_id)
);
ALTER TABLE private.legacy_imports ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.legacy_imports FROM anon,authenticated;

CREATE TABLE private.admin_audit_logs (
id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
actor_user_id uuid REFERENCES public.accounts(id) ON DELETE SET NULL,
actor_kind text NOT NULL CHECK(actor_kind IN ('admin','system')),
action text NOT NULL, target_type text NOT NULL, target_id text NOT NULL, request_id uuid NOT NULL,
summary jsonb NOT NULL CHECK(jsonb_typeof(summary)='object'), created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE private.admin_audit_logs ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.admin_audit_logs FROM anon,authenticated;

ALTER TABLE public.accounts ADD CONSTRAINT accounts_avatar_fk FOREIGN KEY(avatar_asset_id) REFERENCES public.assets(id) ON DELETE SET NULL;
CREATE UNIQUE INDEX topic_completion_verified_unique ON public.topic_completions(profile_id,topic_id,release_id) WHERE source='verified';
CREATE UNIQUE INDEX topic_completion_legacy_unique ON public.topic_completions(profile_id,topic_id) WHERE source='legacy_import';
CREATE FUNCTION private.has_role(wanted text) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM private.account_access a WHERE a.user_id=(SELECT auth.uid()) AND a.role=wanted AND a.status='active')
$$;
REVOKE ALL ON FUNCTION private.has_role(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.has_role(text) TO authenticated,service_role;
CREATE FUNCTION private.touch_updated_at() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$
BEGIN NEW.updated_at=now(); RETURN NEW; END $$;

CREATE TRIGGER touch_updated_at BEFORE UPDATE ON private.account_access FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at();

CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.accounts FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at();

CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.learner_profiles FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at();

CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.assets FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at();

CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.topics FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at();

CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.activities FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at();

CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.learning_sessions FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at();

CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.lesson_drafts FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at();

CREATE TRIGGER touch_updated_at BEFORE UPDATE ON private.sync_heads FOR EACH ROW EXECUTE FUNCTION private.touch_updated_at();

INSERT INTO public.accounts(id,display_name)
 SELECT id,coalesce(nullif(left(btrim(raw_user_meta_data->>'display_name'),80),''),'Người học') FROM auth.users;
INSERT INTO private.account_access(user_id,role)
 SELECT user_id,CASE WHEN was_admin THEN 'admin' ELSE 'user' END FROM matlingo_access_snapshot;
INSERT INTO private.sync_heads(owner_user_id) SELECT id FROM public.accounts;
INSERT INTO private.admin_audit_logs(actor_kind,action,target_type,target_id,request_id,summary)
VALUES('system','database.reset','application','matlingo',gen_random_uuid(),
'{"authorization":"explicit_user_request_2026_10_26","auth_identities_preserved":true,"old_learning_data_imported":false}');
CREATE FUNCTION private.handle_auth_signup() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 INSERT INTO public.accounts(id,display_name) VALUES(NEW.id,coalesce(nullif(left(btrim(NEW.raw_user_meta_data->>'display_name'),80),''),'Người học'));
 INSERT INTO private.account_access(user_id,role) VALUES(NEW.id,'user');
 INSERT INTO private.sync_heads(owner_user_id) VALUES(NEW.id);
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION private.handle_auth_signup() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER matlingo_auth_signup AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION private.handle_auth_signup();
GRANT ALL ON ALL TABLES IN SCHEMA public,private TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public,private TO service_role;

GRANT SELECT ON public.accounts TO authenticated;
CREATE POLICY owner_read ON public.accounts FOR SELECT TO authenticated USING(
private.has_role('user') AND id=(SELECT auth.uid()) AND deleted_at IS NULL);

GRANT SELECT ON public.learner_profiles TO authenticated;
CREATE POLICY owner_read ON public.learner_profiles FOR SELECT TO authenticated USING(
private.has_role('user') AND owner_user_id=(SELECT auth.uid()) AND deleted_at IS NULL);

GRANT SELECT ON public.learning_sessions TO authenticated;
CREATE POLICY owner_read ON public.learning_sessions FOR SELECT TO authenticated USING(
private.has_role('user') AND owner_user_id=(SELECT auth.uid()));

GRANT SELECT ON public.lesson_drafts TO authenticated;
CREATE POLICY owner_read ON public.lesson_drafts FOR SELECT TO authenticated USING(
private.has_role('user') AND owner_user_id=(SELECT auth.uid()));

GRANT SELECT ON public.activity_attempts TO authenticated;
CREATE POLICY owner_read ON public.activity_attempts FOR SELECT TO authenticated USING(
private.has_role('user') AND owner_user_id=(SELECT auth.uid()));

GRANT SELECT ON public.topic_completions TO authenticated;
CREATE POLICY owner_read ON public.topic_completions FOR SELECT TO authenticated USING(
private.has_role('user') AND owner_user_id=(SELECT auth.uid()));

GRANT SELECT ON public.xp_ledger TO authenticated;
CREATE POLICY owner_read ON public.xp_ledger FOR SELECT TO authenticated USING(
private.has_role('user') AND owner_user_id=(SELECT auth.uid()));

GRANT SELECT ON public.activity_events TO authenticated;
CREATE POLICY owner_read ON public.activity_events FOR SELECT TO authenticated USING(
private.has_role('user') AND owner_user_id=(SELECT auth.uid()));

GRANT SELECT ON public.topics TO authenticated;
CREATE POLICY admin_read ON public.topics FOR SELECT TO authenticated USING(private.has_role('admin'));

GRANT SELECT ON public.activities TO authenticated;
CREATE POLICY admin_read ON public.activities FOR SELECT TO authenticated USING(private.has_role('admin'));

GRANT SELECT ON public.activity_versions TO authenticated;
CREATE POLICY admin_read ON public.activity_versions FOR SELECT TO authenticated USING(private.has_role('admin'));

GRANT SELECT ON public.content_releases TO authenticated;
CREATE POLICY admin_read ON public.content_releases FOR SELECT TO authenticated USING(private.has_role('admin'));

GRANT SELECT ON public.release_activities TO authenticated;
CREATE POLICY admin_read ON public.release_activities FOR SELECT TO authenticated USING(private.has_role('admin'));

GRANT SELECT ON public.assets TO authenticated;
CREATE POLICY admin_read ON public.assets FOR SELECT TO authenticated USING(private.has_role('admin'));

GRANT SELECT ON public.activity_assets TO authenticated;
CREATE POLICY admin_read ON public.activity_assets FOR SELECT TO authenticated USING(private.has_role('admin'));

CREATE POLICY user_release_read ON public.content_releases FOR SELECT TO authenticated USING(private.has_role('user') AND status IN ('published','retired'));
CREATE POLICY user_release_activity_read ON public.release_activities FOR SELECT TO authenticated USING(private.has_role('user') AND EXISTS(SELECT 1 FROM public.content_releases r WHERE r.id=release_id AND r.status IN ('published','retired')));
CREATE POLICY user_activity_version_read ON public.activity_versions FOR SELECT TO authenticated USING(private.has_role('user') AND EXISTS(SELECT 1 FROM public.release_activities ra WHERE ra.activity_id=activity_versions.activity_id AND ra.content_version=activity_versions.content_version));
CREATE POLICY user_activity_read ON public.activities FOR SELECT TO authenticated USING(private.has_role('user') AND EXISTS(SELECT 1 FROM public.release_activities ra WHERE ra.activity_id=activities.id));
CREATE POLICY user_topic_read ON public.topics FOR SELECT TO authenticated USING(private.has_role('user') AND EXISTS(SELECT 1 FROM public.release_activities ra WHERE ra.topic_id=topics.id));
CREATE POLICY user_activity_asset_read ON public.activity_assets FOR SELECT TO authenticated USING(private.has_role('user') AND EXISTS(SELECT 1 FROM public.activity_versions av WHERE av.activity_id=activity_assets.activity_id AND av.content_version=activity_assets.content_version));
CREATE POLICY user_asset_read ON public.assets FOR SELECT TO authenticated USING(private.has_role('user') AND (owner_user_id=(SELECT auth.uid()) OR (bucket_id='learning-assets' AND status='ready' AND EXISTS(SELECT 1 FROM public.activity_assets aa WHERE aa.asset_id=assets.id))));
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA private FROM PUBLIC,anon;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC,anon,authenticated;
NOTIFY pgrst,'reload schema';
CREATE FUNCTION private.guard_activity_version() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$
BEGIN
 IF OLD.status='published' THEN RAISE EXCEPTION 'Published activity versions are immutable'; END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER immutable_activity_version BEFORE UPDATE OR DELETE ON public.activity_versions
FOR EACH ROW EXECUTE FUNCTION private.guard_activity_version();
CREATE FUNCTION private.guard_release_rows() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$
DECLARE rid uuid;
BEGIN
 IF TG_OP<>'INSERT' THEN
   IF EXISTS(SELECT 1 FROM public.content_releases WHERE id=OLD.release_id AND status<>'draft')
   THEN RAISE EXCEPTION 'Published release manifests are immutable'; END IF;
 END IF;
 IF TG_OP<>'DELETE' THEN
   IF EXISTS(SELECT 1 FROM public.content_releases WHERE id=NEW.release_id AND status<>'draft')
   THEN RAISE EXCEPTION 'Published release manifests are immutable'; END IF;
   RETURN NEW;
 END IF;
 RETURN OLD;
END $$;
CREATE TRIGGER immutable_release_rows BEFORE INSERT OR UPDATE OR DELETE ON public.release_activities
FOR EACH ROW EXECUTE FUNCTION private.guard_release_rows();
CREATE FUNCTION private.guard_release_publish() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$
BEGIN
 IF TG_OP='DELETE' THEN
   IF OLD.status<>'draft' THEN RAISE EXCEPTION 'Release history cannot be deleted'; END IF;
   RETURN OLD;
 END IF;
 IF TG_OP='UPDATE' AND OLD.status<>'draft' AND
    (to_jsonb(NEW)-'status' IS DISTINCT FROM to_jsonb(OLD)-'status' OR NEW.status='draft')
 THEN RAISE EXCEPTION 'Published release metadata is immutable'; END IF;
 IF NEW.status='published' THEN
   IF NOT EXISTS(SELECT 1 FROM public.release_activities WHERE release_id=NEW.id)
   OR EXISTS(
     SELECT 1 FROM public.release_activities ra
     JOIN public.activity_versions av ON av.activity_id=ra.activity_id AND av.content_version=ra.content_version
     JOIN private.evaluator_versions ev ON ev.mechanism=av.mechanism AND ev.version=av.evaluator_version
     WHERE ra.release_id=NEW.id AND (av.status<>'published' OR ev.status<>'active')
   ) THEN RAISE EXCEPTION 'Cannot publish without verified backend evaluator coverage'; END IF;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER guard_release_publish BEFORE INSERT OR UPDATE OR DELETE ON public.content_releases
FOR EACH ROW EXECUTE FUNCTION private.guard_release_publish();
CREATE FUNCTION private.my_access() RETURNS TABLE(user_id uuid,role text,status text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT a.user_id,a.role,a.status FROM private.account_access a WHERE a.user_id=(SELECT auth.uid())
$$;
REVOKE ALL ON FUNCTION private.my_access() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.my_access() TO authenticated;
CREATE FUNCTION public.get_my_access() RETURNS TABLE(user_id uuid,role text,status text)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT * FROM private.my_access() $$;
REVOKE ALL ON FUNCTION public.get_my_access() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_my_access() TO authenticated;
-- Index FK columns to support ownership checks and safe lifecycle operations.
DO $indexes$
DECLARE r record; columns_sql text;
BEGIN
 FOR r IN
 SELECT con.oid, con.conrelid, con.conkey, ns.nspname, cl.relname, con.conname
 FROM pg_constraint con JOIN pg_class cl ON cl.oid=con.conrelid
 JOIN pg_namespace ns ON ns.oid=cl.relnamespace
 WHERE con.contype='f' AND ns.nspname IN ('public','private')
 LOOP
   SELECT string_agg(quote_ident(att.attname),', ' ORDER BY keys.ord)
   INTO columns_sql FROM unnest(r.conkey) WITH ORDINALITY keys(attnum,ord)
   JOIN pg_attribute att ON att.attrelid=r.conrelid AND att.attnum=keys.attnum;
   EXECUTE format('CREATE INDEX %I ON %I.%I (%s)',
     'fk_'||r.oid::text,r.nspname,r.relname,columns_sql);
 END LOOP;
END $indexes$;
CREATE INDEX profile_owner_active ON public.learner_profiles(owner_user_id) WHERE deleted_at IS NULL;
CREATE INDEX session_history ON public.learning_sessions(profile_id,received_at DESC,id);
CREATE INDEX attempt_history ON public.activity_attempts(profile_id,received_at DESC,id);
CREATE INDEX draft_updated ON public.lesson_drafts(profile_id,updated_at DESC);
CREATE INDEX event_daily ON public.activity_events(profile_id,local_date);
CREATE INDEX audit_history ON private.admin_audit_logs(created_at DESC,id);
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA private FROM PUBLIC,anon;
