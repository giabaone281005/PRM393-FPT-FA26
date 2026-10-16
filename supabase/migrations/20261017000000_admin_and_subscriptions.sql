-- ==============================================================================
-- MathLingo Database Migration: Admin RBAC & Subscription Tiers (Basic / Plus)
-- Compliant with: Supabase Postgres Best Practices, RLS Security, BR-04
-- ==============================================================================

-- 1. ENUMS FOR ROLES & SUBSCRIPTIONS
DO $$ BEGIN
    CREATE TYPE public.app_role AS ENUM ('admin', 'moderator', 'parent');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.subscription_tier AS ENUM ('basic', 'plus');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.subscription_status AS ENUM ('active', 'expired', 'canceled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. ADMINS TABLE (Bảng Admins độc lập đã tạo trên Supabase)
CREATE TABLE IF NOT EXISTS public.admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;

-- 2.1 USER ROLES TABLE
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role public.app_role NOT NULL DEFAULT 'parent',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, role)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Security helper function to check if current user is admin (Check cả bảng admins lẫn user_roles)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
DECLARE
    cur_email TEXT;
BEGIN
    -- Kiểm tra trong bảng public.admins theo UID
    IF EXISTS (
        SELECT 1 FROM public.admins
        WHERE id = (SELECT auth.uid())
    ) THEN
        RETURN true;
    END IF;

    -- Kiểm tra trong bảng public.admins theo email của auth.users
    SELECT email INTO cur_email FROM auth.users WHERE id = (SELECT auth.uid());
    IF cur_email IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.admins
        WHERE lower(email) = lower(cur_email)
    ) THEN
        RETURN true;
    END IF;

    -- Kiểm tra trong bảng public.user_roles
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = (SELECT auth.uid())
          AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- RLS for admins
DROP POLICY IF EXISTS "Admins can view admins list" ON public.admins;
CREATE POLICY "Admins can view admins list"
    ON public.admins FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- RLS for user_roles
DROP POLICY IF EXISTS "Users can view their own roles" ON public.user_roles;
CREATE POLICY "Users can view their own roles"
    ON public.user_roles FOR SELECT
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Admins can manage all roles" ON public.user_roles;
CREATE POLICY "Admins can manage all roles"
    ON public.user_roles FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Cấp quyền cho Admin xem và quản lý toàn bộ parents & kid_profiles
DROP POLICY IF EXISTS "Admins can view all parents" ON public.parents;
CREATE POLICY "Admins can view all parents"
    ON public.parents FOR SELECT
    TO authenticated
    USING (public.is_admin() OR (select auth.uid()) = id);

DROP POLICY IF EXISTS "Admins can view all kid profiles" ON public.kid_profiles;
CREATE POLICY "Admins can view all kid profiles"
    ON public.kid_profiles FOR SELECT
    TO authenticated
    USING (true); -- Public cho leaderboard và admin xem được hết

-- 3. SUBSCRIPTIONS TABLE
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID NOT NULL UNIQUE REFERENCES public.parents(id) ON DELETE CASCADE,
    tier public.subscription_tier NOT NULL DEFAULT 'basic',
    status public.subscription_status NOT NULL DEFAULT 'active',
    max_kids INT NOT NULL DEFAULT 1, -- Basic = 1, Plus = 3
    start_date TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ, -- NULL nghĩa là vĩnh viễn
    upgraded_by UUID REFERENCES auth.users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_parent_id ON public.subscriptions(parent_id);
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- RLS for subscriptions
DROP POLICY IF EXISTS "Parents can view their own subscription" ON public.subscriptions;
CREATE POLICY "Parents can view their own subscription"
    ON public.subscriptions FOR SELECT
    TO authenticated
    USING (parent_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Admins can manage all subscriptions" ON public.subscriptions;
CREATE POLICY "Admins can manage all subscriptions"
    ON public.subscriptions FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- 4. SUBSCRIPTION LOGS TABLE (Audit History)
CREATE TABLE IF NOT EXISTS public.subscription_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID NOT NULL REFERENCES public.parents(id) ON DELETE CASCADE,
    action TEXT NOT NULL, -- 'UPGRADE', 'DOWNGRADE', 'EXTEND', 'CANCEL'
    old_tier public.subscription_tier,
    new_tier public.subscription_tier,
    performed_by UUID REFERENCES auth.users(id),
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_subscription_logs_parent_id ON public.subscription_logs(parent_id);
ALTER TABLE public.subscription_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Parents can view their subscription logs" ON public.subscription_logs;
CREATE POLICY "Parents can view their subscription logs"
    ON public.subscription_logs FOR SELECT
    TO authenticated
    USING (parent_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Admins can view all subscription logs" ON public.subscription_logs;
CREATE POLICY "Admins can view all subscription logs"
    ON public.subscription_logs FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- 5. FUNCTION & TRIGGER: DYNAMIC MAX KIDS CHECK (BASIC = 1, PLUS = 3)
CREATE OR REPLACE FUNCTION public.check_max_kids_limit()
RETURNS TRIGGER AS $$
DECLARE
    kid_count INT;
    allowed_kids INT;
BEGIN
    -- Lấy giới hạn từ bảng subscriptions, mặc định là 1 nếu chưa có record
    SELECT COALESCE(s.max_kids, 1) INTO allowed_kids
    FROM public.subscriptions s
    WHERE s.parent_id = NEW.parent_id;

    IF allowed_kids IS NULL THEN
        allowed_kids := 1;
    END IF;

    SELECT count(*) INTO kid_count
    FROM public.kid_profiles
    WHERE parent_id = NEW.parent_id
      AND id != NEW.id;

    IF kid_count >= allowed_kids THEN
        RAISE EXCEPTION 'Gói hiện tại của bạn chỉ cho phép tối đa % hồ sơ bé. Vui lòng nâng cấp lên gói Plus để thêm bé!', allowed_kids;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_check_max_kids ON public.kid_profiles;
CREATE TRIGGER trigger_check_max_kids
    BEFORE INSERT ON public.kid_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.check_max_kids_limit();

-- 6. RPC FUNCTION: ADMIN UPGRADE PARENT SUBSCRIPTION
CREATE OR REPLACE FUNCTION public.admin_upgrade_subscription(
    target_parent_id UUID,
    new_tier public.subscription_tier,
    duration_days INT DEFAULT NULL,
    upgrade_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    cur_tier public.subscription_tier;
    calc_max_kids INT;
    new_expires TIMESTAMPTZ;
    admin_id UUID := auth.uid();
BEGIN
    -- Kiểm tra quyền admin
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Chỉ quản trị viên (Admin) mới có quyền nâng cấp gói dịch vụ!';
    END IF;

    -- Xác định số lượng bé theo gói
    IF new_tier = 'plus' THEN
        calc_max_kids := 3;
    ELSE
        calc_max_kids := 1;
    END IF;

    -- Tính ngày hết hạn
    IF duration_days IS NOT NULL AND duration_days > 0 THEN
        new_expires := now() + (duration_days || ' days')::INTERVAL;
    ELSE
        new_expires := NULL; -- Vĩnh viễn nếu không chỉ định ngày
    END IF;

    -- Lấy gói hiện tại
    SELECT tier INTO cur_tier
    FROM public.subscriptions
    WHERE parent_id = target_parent_id;

    -- Upsert gói mới
    INSERT INTO public.subscriptions (
        parent_id, tier, status, max_kids, start_date, expires_at, upgraded_by, notes, updated_at
    )
    VALUES (
        target_parent_id, new_tier, 'active', calc_max_kids, now(), new_expires, admin_id, upgrade_notes, now()
    )
    ON CONFLICT (parent_id) DO UPDATE
    SET tier = EXCLUDED.tier,
        status = 'active',
        max_kids = EXCLUDED.max_kids,
        expires_at = EXCLUDED.expires_at,
        upgraded_by = EXCLUDED.upgraded_by,
        notes = EXCLUDED.notes,
        updated_at = now();

    -- Ghi log lịch sử
    INSERT INTO public.subscription_logs (
        parent_id, action, old_tier, new_tier, performed_by, reason
    )
    VALUES (
        target_parent_id,
        CASE WHEN new_tier = 'plus' THEN 'UPGRADE' ELSE 'DOWNGRADE' END,
        cur_tier,
        new_tier,
        admin_id,
        upgrade_notes
    );

    RETURN jsonb_build_object(
        'success', true,
        'parent_id', target_parent_id,
        'tier', new_tier,
        'max_kids', calc_max_kids,
        'expires_at', new_expires
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
