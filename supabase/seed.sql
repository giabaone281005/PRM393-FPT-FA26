-- ==============================================================================
-- MATHLINGO DATABASE SEED DATA (Supabase Postgres)
-- End-to-End Test Data for Parent Role, Kid Role, Curriculum & Gamification
-- ==============================================================================

-- 1. PARENT ACCOUNTS (Tài khoản phụ huynh mẫu)
-- Note: In Supabase production, auth.users is populated via Auth API.
-- For local/direct SQL seeding or mock setups:
INSERT INTO public.parents (id, email, parent_pin_hash, created_at, updated_at)
VALUES 
  ('a0000000-0000-0000-0000-000000000001', 'phuhuynh@mathlingo.vn', '1234', now(), now()),
  ('a0000000-0000-0000-0000-000000000002', 'parent.demo@mathlingo.vn', '1234', now(), now())
ON CONFLICT (id) DO UPDATE 
SET email = EXCLUDED.email, parent_pin_hash = EXCLUDED.parent_pin_hash, updated_at = now();

-- 2. KID PROFILES (Hồ sơ học sinh: Tối đa 3 bé / phụ huynh theo BR-04)
INSERT INTO public.kid_profiles (
  id, parent_id, nickname, grade, current_hearts, max_hearts, energy_stars, screen_time_limit_minutes, avatar_id
)
VALUES
  ('k0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Bé Bo', 5, 5, 5, 180, 30, 'owl_detective'),
  ('k0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Bé Bắp', 2, 4, 5, 95, 20, 'owl_scholar'),
  ('k0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Bé Miu', 1, 5, 5, 40, 15, 'owl_wizard')
ON CONFLICT (id) DO UPDATE 
SET nickname = EXCLUDED.nickname, grade = EXCLUDED.grade, energy_stars = EXCLUDED.energy_stars, current_hearts = EXCLUDED.current_hearts;

-- 3. KID STREAKS (Chuỗi ngày rèn luyện liên tục & BR-02 chốt 21:00)
INSERT INTO public.kid_streaks (kid_id, streak_count, last_activity_date, shields_available, cutoff_time)
VALUES
  ('k0000000-0000-0000-0000-000000000001', 7, CURRENT_DATE, 1, '21:00:00'),
  ('k0000000-0000-0000-0000-000000000002', 4, CURRENT_DATE, 1, '21:00:00'),
  ('k0000000-0000-0000-0000-000000000003', 2, CURRENT_DATE, 0, '21:00:00')
ON CONFLICT (kid_id) DO UPDATE 
SET streak_count = EXCLUDED.streak_count, last_activity_date = EXCLUDED.last_activity_date;

-- 4. CURRICULUM TOPICS (Chuyên đề toán Lớp 1 - 5)
INSERT INTO public.topics (id, grade, topic_number, title, description, icon_name)
VALUES
  ('t0000000-0000-0000-0000-000000000001', 1, 1, 'Làm Quen Các Số & Đếm Trực Quan', 'Kéo thả que tính và đếm quả trong giỏ', 'drag_handle'),
  ('t0000000-0000-0000-0000-000000000002', 2, 1, 'Phép Nhân & Bảng Cửu Chương Cơ Bản', 'Khám phá thế giới bảng cửu chương 2, 3, 5', 'close'),
  ('t0000000-0000-0000-0000-000000000003', 3, 1, 'Đồng Hồ Thời Gian & Góc Xoay', 'Xoay kim giờ, kim phút chuẩn xác', 'access_time'),
  ('t0000000-0000-0000-0000-000000000004', 4, 1, 'Lưới Ô Vuông Diện Tích & Chu Vi', 'Thám tử đo lường hình chữ nhật và hình vuông', 'grid_on'),
  ('t0000000-0000-0000-0000-000000000005', 5, 1, 'Giải Đố Toán Lời Văn Socratic', 'Phân tích từ khóa đề bài từng bước cùng Cú', 'functions')
ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title;

-- 5. LESSONS (Lộ trình bài học 3–5 phút cho Lớp 5)
INSERT INTO public.lessons (id, topic_id, lesson_number, title, subtitle, estimated_minutes, xp_reward, star_reward, order_index)
VALUES
  ('l0000000-0000-0000-0000-000000000001', 't0000000-0000-0000-0000-000000000005', 1, 'Bài 1: Làm Quen & Đếm Trực Quan', 'Kéo thả que tính và hoa quả vui nhộn', 3, 30, 3, 1),
  ('l0000000-0000-0000-0000-000000000002', 't0000000-0000-0000-0000-000000000005', 2, 'Bài 2: Kim Đồng Hồ Tích Tắc', 'Xoay kim giờ và kim phút chính xác', 4, 35, 3, 2),
  ('l0000000-0000-0000-0000-000000000003', 't0000000-0000-0000-0000-000000000005', 3, 'Bài 3: Mê Cung Bảng Cửu Chương', 'Tính nhẩm thần tốc bảng nhân 7 và 8', 4, 40, 3, 3),
  ('l0000000-0000-0000-0000-000000000004', 't0000000-0000-0000-0000-000000000005', 4, 'Bài 4: Thám Tử Đo Lưới Ô Vuông', 'Tính diện tích hình chữ nhật trên lưới', 5, 45, 3, 4),
  ('l0000000-0000-0000-0000-000000000005', 't0000000-0000-0000-0000-000000000005', 5, 'Bài 5: Giải Đố Toán Lời Văn', 'Phân tích từ khóa và tìm cách giải', 5, 50, 3, 5)
ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, subtitle = EXCLUDED.subtitle;

-- 6. QUESTIONS (Bộ câu hỏi tương tác 60 FPS kèm gợi ý Socratic)
INSERT INTO public.questions (id, lesson_id, question_type, prompt, payload, socratic_hints, order_index)
VALUES
  -- Q1: Kéo thả que tính / quả táo (Drag Counters)
  (
    'q0000000-0000-0000-0000-000000000001',
    'l0000000-0000-0000-0000-000000000001',
    'drag_counters',
    'Kéo đúng 5 quả táo vào chiếc rổ phép thuật!',
    '{"itemIcon": "🍎", "targetCount": 5, "availableCount": 8}'::jsonb,
    '[
      {"step": 1, "questionText": "Trong rổ hiện đang có bao nhiêu quả táo?", "hintText": "Hãy đếm xem trong rổ đã có mấy quả rồi, chúng ta cần thêm cho đủ 5 quả nhé!"},
      {"step": 2, "questionText": "Nếu rổ có 3 quả, cần kéo thêm mấy quả nữa để được 5?", "hintText": "Thử lấy 5 trừ đi 3 xem nào bạn nhỏ ơi!"}
    ]'::jsonb,
    1
  ),
  -- Q2: Xoay kim đồng hồ (Clock Rotation)
  (
    'q0000000-0000-0000-0000-000000000002',
    'l0000000-0000-0000-0000-000000000002',
    'clock_rotation',
    'Hãy xoay kim đồng hồ để chỉ đúng 3 giờ 30 phút!',
    '{"targetHour": 3, "targetMinute": 30}'::jsonb,
    '[
      {"step": 1, "questionText": "Mỗi khoảng giữa hai số trên mặt đồng hồ là bao nhiêu phút?", "hintText": "Cứ mỗi số cách nhau 5 phút. Hãy đếm từ số 12 nhé: 5, 10, 15...!"},
      {"step": 2, "questionText": "30 phút thì kim dài phải chỉ vào số mấy?", "hintText": "Lấy 30 chia cho 5 sẽ ra số trên mặt đồng hồ!"}
    ]'::jsonb,
    1
  ),
  -- Q3: Điền bảng cửu chương (Multiplication Table)
  (
    'q0000000-0000-0000-0000-000000000003',
    'l0000000-0000-0000-0000-000000000003',
    'multiplication_table',
    'Điền số thích hợp: 7 × 8 = ?',
    '{"factorA": 7, "factorB": 8, "options": [48, 54, 56, 63], "correctAnswer": 56}'::jsonb,
    '[
      {"step": 1, "questionText": "Em có nhớ 7 × 7 bằng bao nhiêu không?", "hintText": "7 × 7 = 49. Vậy 7 × 8 sẽ bằng 49 cộng thêm mấy nữa nhỉ?"},
      {"step": 2, "questionText": "49 + 7 bằng mấy?", "hintText": "Tính nhẩm: 49 + 1 = 50, 50 + 6 = 56!"}
    ]'::jsonb,
    1
  ),
  -- Q4: Lưới ô vuông diện tích (Area Grid)
  (
    'q0000000-0000-0000-0000-000000000004',
    'l0000000-0000-0000-0000-000000000004',
    'area_grid',
    'Hình chữ nhật có chiều dài 5 ô, chiều rộng 3 ô. Diện tích là bao nhiêu ô vuông?',
    '{"rows": 3, "cols": 5, "correctAnswer": 15}'::jsonb,
    '[
      {"step": 1, "questionText": "Mỗi hàng có bao nhiêu ô vuông?", "hintText": "Có 3 hàng, mỗi hàng có 5 ô vuông."},
      {"step": 2, "questionText": "Công thức tính diện tích hình chữ nhật là gì?", "hintText": "Lấy chiều dài nhân với chiều rộng (5 × 3)."}
    ]'::jsonb,
    1
  ),
  -- Q5: Phân tích bài toán có lời văn (Word Problem)
  (
    'q0000000-0000-0000-0000-000000000005',
    'l0000000-0000-0000-0000-000000000005',
    'word_problem',
    'Một rổ có 24 quả cam. Mẹ đem chia đều cho 4 anh em. Hỏi mỗi người nhận được mấy quả cam?',
    '{"total": 24, "parts": 4, "options": ["24 + 4 = 28", "24 - 4 = 20", "24 × 4 = 96", "24 ÷ 4 = 6"], "correctAnswer": "24 ÷ 4 = 6"}'::jsonb,
    '[
      {"step": 1, "questionText": "Từ khóa \"chia đều\" báo hiệu phép tính nào?", "hintText": "Khi chia đều một số lượng cho nhiều phần bằng nhau, ta dùng phép chia."},
      {"step": 2, "questionText": "24 chia cho 4 bằng mấy?", "hintText": "Nhớ lại bảng nhân 4: 4 nhân mấy thì bằng 24?"}
    ]'::jsonb,
    1
  )
ON CONFLICT (id) DO UPDATE SET prompt = EXCLUDED.prompt, payload = EXCLUDED.payload;

-- 7. KID PROGRESS (Tiến độ học tập của Bé Bo)
INSERT INTO public.kid_progress (kid_id, lesson_id, is_completed, accuracy_percent, stars_earned, attempts_count, completed_at)
VALUES
  ('k0000000-0000-0000-0000-000000000001', 'l0000000-0000-0000-0000-000000000001', true, 100, 3, 1, now() - INTERVAL '1 day'),
  ('k0000000-0000-0000-0000-000000000001', 'l0000000-0000-0000-0000-000000000002', false, 0, 0, 0, null)
ON CONFLICT (kid_id, lesson_id) DO UPDATE 
SET is_completed = EXCLUDED.is_completed, stars_earned = EXCLUDED.stars_earned;

-- 8. PRACTICE GARDEN LOGS (Nhật ký hồi tim miễn phí BR-03)
INSERT INTO public.practice_garden_logs (kid_id, hearts_restored, math_drills_completed, completed_at)
VALUES
  ('k0000000-0000-0000-0000-000000000001', 5, 5, now() - INTERVAL '3 hours'),
  ('k0000000-0000-0000-0000-000000000002', 4, 4, now() - INTERVAL '6 hours');

-- 9. TOURNAMENT LEAGUE (Giải đấu thi đua 30 bạn cùng khối lớp)
INSERT INTO public.tournaments (id, grade, week_code, created_at)
VALUES
  ('trn-grade5-w42', 5, '2026-W42', now())
ON CONFLICT (id) DO NOTHING;

-- 30 Thành viên bảng xếp hạng tuần
INSERT INTO public.tournament_members (tournament_id, kid_id, weekly_xp, rank)
VALUES
  ('trn-grade5-w42', 'k0000000-0000-0000-0000-000000000001', 340, 2)
ON CONFLICT (tournament_id, kid_id) DO UPDATE SET weekly_xp = EXCLUDED.weekly_xp, rank = EXCLUDED.rank;
