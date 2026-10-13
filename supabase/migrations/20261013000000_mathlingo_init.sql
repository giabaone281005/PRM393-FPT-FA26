-- ==============================================================================
-- MathLingo Database Schema Migration (Supabase Postgres)
-- Compliant with: COPPA/GDPR-K, Business Rules (BR-01, BR-02, BR-03, BR-04)
-- ==============================================================================

-- 1. PARENTS TABLE (Links to auth.users)
CREATE TABLE IF NOT EXISTS public.parents (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    parent_pin_hash TEXT NOT NULL DEFAULT '1234',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.parents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Parents can view their own profile"
    ON public.parents FOR SELECT
    TO authenticated
    USING ((select auth.uid()) = id);

CREATE POLICY "Parents can update their own profile"
    ON public.parents FOR UPDATE
    TO authenticated
    USING ((select auth.uid()) = id)
    WITH CHECK ((select auth.uid()) = id);

CREATE POLICY "Parents can insert their own profile"
    ON public.parents FOR INSERT
    TO authenticated
    WITH CHECK ((select auth.uid()) = id);

-- 2. KID PROFILES TABLE (COPPA Compliant: No child PII)
CREATE TABLE IF NOT EXISTS public.kid_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID NOT NULL REFERENCES public.parents(id) ON DELETE CASCADE,
    nickname TEXT NOT NULL,
    grade INT NOT NULL CHECK (grade BETWEEN 1 AND 5),
    current_hearts INT NOT NULL DEFAULT 5 CHECK (current_hearts BETWEEN 0 AND 5),
    max_hearts INT NOT NULL DEFAULT 5,
    energy_stars INT NOT NULL DEFAULT 0,
    screen_time_limit_minutes INT NOT NULL DEFAULT 30,
    avatar_id TEXT NOT NULL DEFAULT 'owl_detective',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_kid_profiles_parent_id ON public.kid_profiles(parent_id);

ALTER TABLE public.kid_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Parents can view own kid profiles"
    ON public.kid_profiles FOR SELECT
    TO authenticated
    USING (parent_id = (select auth.uid()));

CREATE POLICY "Parents can insert kid profiles"
    ON public.kid_profiles FOR INSERT
    TO authenticated
    WITH CHECK (parent_id = (select auth.uid()));

CREATE POLICY "Parents can update kid profiles"
    ON public.kid_profiles FOR UPDATE
    TO authenticated
    USING (parent_id = (select auth.uid()))
    WITH CHECK (parent_id = (select auth.uid()));

CREATE POLICY "Parents can delete kid profiles"
    ON public.kid_profiles FOR DELETE
    TO authenticated
    USING (parent_id = (select auth.uid()));

-- Enforce BR-04: Maximum 3 kids per parent account
CREATE OR REPLACE FUNCTION public.check_max_kids_limit()
RETURNS TRIGGER AS $$
DECLARE
    kid_count INT;
BEGIN
    SELECT count(*) INTO kid_count
    FROM public.kid_profiles
    WHERE parent_id = NEW.parent_id;

    IF kid_count >= 3 THEN
        RAISE EXCEPTION 'BR-04: Mỗi tài khoản phụ huynh chỉ được tạo tối đa 3 hồ sơ học sinh';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_check_max_kids ON public.kid_profiles;
CREATE TRIGGER trigger_check_max_kids
    BEFORE INSERT ON public.kid_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.check_max_kids_limit();

-- 3. TOPICS & LESSONS (Curriculum Engine)
CREATE TABLE IF NOT EXISTS public.topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grade INT NOT NULL CHECK (grade BETWEEN 1 AND 5),
    topic_number INT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    icon_name TEXT DEFAULT 'functions',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_topics_grade ON public.topics(grade);
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read topics"
    ON public.topics FOR SELECT
    TO authenticated
    USING (true);

CREATE TABLE IF NOT EXISTS public.lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID NOT NULL REFERENCES public.topics(id) ON DELETE CASCADE,
    lesson_number INT NOT NULL,
    title TEXT NOT NULL,
    subtitle TEXT,
    estimated_minutes INT NOT NULL DEFAULT 3,
    xp_reward INT NOT NULL DEFAULT 30,
    star_reward INT NOT NULL DEFAULT 3,
    order_index INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_lessons_topic_id ON public.lessons(topic_id);
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read lessons"
    ON public.lessons FOR SELECT
    TO authenticated
    USING (true);

-- 4. QUESTIONS TABLE (Visual Manipulatives Data)
CREATE TABLE IF NOT EXISTS public.questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
    question_type TEXT NOT NULL CHECK (question_type IN (
        'drag_counters',
        'multiplication_table',
        'clock_rotation',
        'area_grid',
        'word_problem'
    )),
    prompt TEXT NOT NULL,
    payload JSONB NOT NULL,
    socratic_hints JSONB NOT NULL DEFAULT '[]'::jsonb,
    order_index INT NOT NULL DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_questions_lesson_id ON public.questions(lesson_id);
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read questions"
    ON public.questions FOR SELECT
    TO authenticated
    USING (true);

-- 5. PROGRESS & STREAKS (Gamification & BR-02, BR-03)
CREATE TABLE IF NOT EXISTS public.kid_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kid_id UUID NOT NULL REFERENCES public.kid_profiles(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    accuracy_percent INT NOT NULL DEFAULT 0,
    stars_earned INT NOT NULL DEFAULT 0,
    attempts_count INT NOT NULL DEFAULT 1,
    completed_at TIMESTAMPTZ,
    UNIQUE(kid_id, lesson_id)
);

CREATE INDEX IF NOT EXISTS idx_kid_progress_kid_id ON public.kid_progress(kid_id);
ALTER TABLE public.kid_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Parents can read/manage kid progress"
    ON public.kid_progress FOR ALL
    TO authenticated
    USING (kid_id IN (SELECT id FROM public.kid_profiles WHERE parent_id = (select auth.uid())));

CREATE TABLE IF NOT EXISTS public.kid_streaks (
    kid_id UUID PRIMARY KEY REFERENCES public.kid_profiles(id) ON DELETE CASCADE,
    streak_count INT NOT NULL DEFAULT 1,
    last_activity_date DATE NOT NULL DEFAULT CURRENT_DATE,
    shields_available INT NOT NULL DEFAULT 1,
    cutoff_time TIME NOT NULL DEFAULT '21:00:00'
);

ALTER TABLE public.kid_streaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Parents can manage kid streaks"
    ON public.kid_streaks FOR ALL
    TO authenticated
    USING (kid_id IN (SELECT id FROM public.kid_profiles WHERE parent_id = (select auth.uid())));

-- 6. PRACTICE GARDEN (BR-03: Free heart restoration)
CREATE TABLE IF NOT EXISTS public.practice_garden_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kid_id UUID NOT NULL REFERENCES public.kid_profiles(id) ON DELETE CASCADE,
    hearts_restored INT NOT NULL DEFAULT 1,
    math_drills_completed INT NOT NULL DEFAULT 5,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.practice_garden_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Parents can read practice logs"
    ON public.practice_garden_logs FOR ALL
    TO authenticated
    USING (kid_id IN (SELECT id FROM public.kid_profiles WHERE parent_id = (select auth.uid())));

-- 7. TOURNAMENTS (30 Kids per weekly arena)
CREATE TABLE IF NOT EXISTS public.tournaments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grade INT NOT NULL CHECK (grade BETWEEN 1 AND 5),
    week_code TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.tournament_members (
    tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
    kid_id UUID NOT NULL REFERENCES public.kid_profiles(id) ON DELETE CASCADE,
    weekly_xp INT NOT NULL DEFAULT 0,
    rank INT NOT NULL DEFAULT 1,
    PRIMARY KEY(tournament_id, kid_id)
);

ALTER TABLE public.tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read tournaments"
    ON public.tournaments FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Public read tournament members"
    ON public.tournament_members FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Update own kid tournament score"
    ON public.tournament_members FOR UPDATE
    TO authenticated
    USING (kid_id IN (SELECT id FROM public.kid_profiles WHERE parent_id = (select auth.uid())));
