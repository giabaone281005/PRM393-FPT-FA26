-- ==============================================================================
-- MathLingo Migration: Tủ đồ linh vật, Lịch sử học, Siết bảo mật, Trigger tiện ích
-- Chạy SAU: 20261013000000_mathlingo_init.sql
-- Idempotent: có thể chạy lại nhiều lần mà không lỗi
-- ==============================================================================

-- 1. SIẾT BẢO MẬT kid_profiles (trước đây USING (true) cho public)
DROP POLICY IF EXISTS "Allow select kid profiles for leaderboard" ON public.kid_profiles;
DROP POLICY IF EXISTS "Parents read own kids" ON public.kid_profiles;
CREATE POLICY "Parents read own kids" ON public.kid_profiles
  FOR SELECT TO authenticated USING (parent_id = (select auth.uid()));

-- View BXH: chỉ lộ biệt danh + điểm, không lộ thông tin khác của bé
CREATE OR REPLACE VIEW public.v_leaderboard AS
SELECT tm.tournament_id, tm.kid_id, k.nickname, tm.weekly_xp,
       RANK() OVER (PARTITION BY tm.tournament_id ORDER BY tm.weekly_xp DESC) AS rank
FROM public.tournament_members tm
JOIN public.kid_profiles k ON k.id = tm.kid_id;
GRANT SELECT ON public.v_leaderboard TO authenticated;

-- 2. TỦ ĐỒ LINH VẬT
CREATE TABLE IF NOT EXISTS public.mascot_items (
  id TEXT PRIMARY KEY,
  slot TEXT NOT NULL CHECK (slot IN ('hat','glasses')),
  name TEXT NOT NULL,
  price_stars INT NOT NULL DEFAULT 0 CHECK (price_stars >= 0),
  is_active BOOLEAN NOT NULL DEFAULT true,
  icon TEXT
);

CREATE TABLE IF NOT EXISTS public.kid_inventory (
  kid_id UUID REFERENCES public.kid_profiles(id) ON DELETE CASCADE,
  item_id TEXT REFERENCES public.mascot_items(id),
  purchased_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (kid_id, item_id)
);

CREATE TABLE IF NOT EXISTS public.kid_equipment (
  kid_id UUID PRIMARY KEY REFERENCES public.kid_profiles(id) ON DELETE CASCADE,
  hat_id TEXT REFERENCES public.mascot_items(id),
  glasses_id TEXT REFERENCES public.mascot_items(id)
);

ALTER TABLE public.mascot_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kid_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kid_equipment ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read items" ON public.mascot_items;
CREATE POLICY "Public read items" ON public.mascot_items
  FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Parents manage inventory" ON public.kid_inventory;
CREATE POLICY "Parents manage inventory" ON public.kid_inventory
  FOR ALL TO authenticated
  USING (kid_id IN (SELECT id FROM public.kid_profiles WHERE parent_id = (select auth.uid())));

DROP POLICY IF EXISTS "Parents manage equipment" ON public.kid_equipment;
CREATE POLICY "Parents manage equipment" ON public.kid_equipment
  FOR ALL TO authenticated
  USING (kid_id IN (SELECT id FROM public.kid_profiles WHERE parent_id = (select auth.uid())))
  WITH CHECK (kid_id IN (SELECT id FROM public.kid_profiles WHERE parent_id = (select auth.uid())));

-- Dữ liệu khớp mascot_wardrobe_screen.dart
INSERT INTO public.mascot_items (id, slot, name, price_stars, icon) VALUES
  ('hat_detective',     'hat',     'Mũ Thám Tử',    0,  '🕵️'),
  ('hat_scholar',       'hat',     'Mũ Bác Học',    40, '🎓'),
  ('hat_wizard',        'hat',     'Mũ Phù Thủy',   80, '🧙'),
  ('glasses_wisdom',    'glasses', 'Kính Tri Thức', 0,  '👓'),
  ('glasses_star',      'glasses', 'Kính Ngôi Sao', 35, '🕶️'),
  ('glasses_detective', 'glasses', 'Kính Thám Tử',  60, '🔍')
ON CONFLICT (id) DO UPDATE
  SET slot = EXCLUDED.slot, name = EXCLUDED.name,
      price_stars = EXCLUDED.price_stars, icon = EXCLUDED.icon;

-- Mua đồ: kiểm tra quyền, đủ sao, trừ sao + nhận đồ trong cùng một giao dịch
CREATE OR REPLACE FUNCTION public.purchase_item(p_kid UUID, p_item TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE v_price INT; v_stars INT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.kid_profiles
                 WHERE id = p_kid AND parent_id = auth.uid()) THEN
    RAISE EXCEPTION 'Không có quyền với hồ sơ bé này';
  END IF;

  SELECT price_stars INTO v_price FROM public.mascot_items
   WHERE id = p_item AND is_active;
  IF NOT FOUND THEN RAISE EXCEPTION 'Món đồ không tồn tại'; END IF;

  IF EXISTS (SELECT 1 FROM public.kid_inventory
             WHERE kid_id = p_kid AND item_id = p_item) THEN
    RETURN;
  END IF;

  SELECT energy_stars INTO v_stars FROM public.kid_profiles
   WHERE id = p_kid FOR UPDATE;
  IF v_stars < v_price THEN RAISE EXCEPTION 'Bé chưa đủ Sao'; END IF;

  UPDATE public.kid_profiles SET energy_stars = energy_stars - v_price WHERE id = p_kid;
  INSERT INTO public.kid_inventory (kid_id, item_id) VALUES (p_kid, p_item);
END $$;

-- 3. LỊCH SỬ HỌC (cấp dữ liệu cho biểu đồ Cổng phụ huynh)
CREATE TABLE IF NOT EXISTS public.study_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kid_id UUID NOT NULL REFERENCES public.kid_profiles(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES public.lessons(id) ON DELETE SET NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  duration_seconds INT NOT NULL DEFAULT 0,
  xp_earned INT NOT NULL DEFAULT 0,
  hearts_lost INT NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_sessions_kid_time
  ON public.study_sessions (kid_id, started_at DESC);

CREATE TABLE IF NOT EXISTS public.question_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.study_sessions(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
  is_correct BOOLEAN NOT NULL,
  hints_used INT NOT NULL DEFAULT 0,
  answered_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_attempts_session
  ON public.question_attempts (session_id);

ALTER TABLE public.study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_attempts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Parents manage sessions" ON public.study_sessions;
CREATE POLICY "Parents manage sessions" ON public.study_sessions
  FOR ALL TO authenticated
  USING (kid_id IN (SELECT id FROM public.kid_profiles WHERE parent_id = (select auth.uid())))
  WITH CHECK (kid_id IN (SELECT id FROM public.kid_profiles WHERE parent_id = (select auth.uid())));

DROP POLICY IF EXISTS "Parents manage attempts" ON public.question_attempts;
CREATE POLICY "Parents manage attempts" ON public.question_attempts
  FOR ALL TO authenticated
  USING (session_id IN (
    SELECT s.id FROM public.study_sessions s
    JOIN public.kid_profiles k ON k.id = s.kid_id
    WHERE k.parent_id = (select auth.uid())))
  WITH CHECK (session_id IN (
    SELECT s.id FROM public.study_sessions s
    JOIN public.kid_profiles k ON k.id = s.kid_id
    WHERE k.parent_id = (select auth.uid())));

-- 4. TRIGGER TIỆN ÍCH
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END $$;

CREATE OR REPLACE TRIGGER trg_parents_updated_at
  BEFORE UPDATE ON public.parents
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE TRIGGER trg_kids_updated_at
  BEFORE UPDATE ON public.kid_profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Tự tạo dòng parents khi có tài khoản mới đăng ký
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.parents (id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END $$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Bù cho tài khoản cũ chưa có dòng parents
INSERT INTO public.parents (id, email)
SELECT id, email FROM auth.users
ON CONFLICT (id) DO NOTHING;
