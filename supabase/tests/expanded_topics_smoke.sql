-- Read-only assertions after applying expanded_learning_topics.
BEGIN;
DO $$
BEGIN
  IF (SELECT count(*) FROM public.topics WHERE id IN
      ('english','vietnamese','biology','chemistry','astronomy','finance','digital')) <> 7 THEN
    RAISE EXCEPTION 'Expanded topic metadata missing';
  END IF;
  IF EXISTS (SELECT 1 FROM public.topics WHERE id IN
      ('english','vietnamese','biology','chemistry','astronomy','finance','digital') AND status <> 'draft') THEN
    RAISE EXCEPTION 'Local-only topics must not be implicitly published';
  END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.topics'::regclass) THEN
    RAISE EXCEPTION 'Topics RLS must stay enabled';
  END IF;
END $$;
SELECT count(*) AS topics FROM public.topics;
ROLLBACK;
