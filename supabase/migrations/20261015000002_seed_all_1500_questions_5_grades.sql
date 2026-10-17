-- ==============================================================================
-- MIGRATION: SEED 150 LESSONS & 1,500 QUESTIONS FOR GRADES 1 TO 5
-- Compliant with: 5 Grades x 30 Lessons x 10 Questions = 1,500 Questions
-- Idempotent: Can be run multiple times safely on Supabase SQL Editor
-- ==============================================================================

-- 1. Nâng cấp cấu trúc bảng lessons để lưu trữ lý thuyết, tự luận và minigame
ALTER TABLE public.lessons ADD COLUMN IF NOT EXISTS theory TEXT;
ALTER TABLE public.lessons ADD COLUMN IF NOT EXISTS essay_prompt TEXT;
ALTER TABLE public.lessons ADD COLUMN IF NOT EXISTS essay_guidance TEXT;
ALTER TABLE public.lessons ADD COLUMN IF NOT EXISTS mini_game_type TEXT DEFAULT 'number';

-- 2. Đảm bảo bảng topics cho 5 khối lớp
INSERT INTO public.topics (id, grade, topic_number, title, description, icon_name)
VALUES
  ('c0000000-0000-0000-0000-000000000001', 1, 1, 'Hành Trình Số Học Lớp 1', 'Làm quen các số, phép cộng trừ & hình khối trực quan', 'drag_handle'),
  ('c0000000-0000-0000-0000-000000000002', 2, 1, 'Khám Phá Bảng Tính Lớp 2', 'Bảng cửu chương 2-5, cộng trừ có nhớ & đồng hồ', 'close'),
  ('c0000000-0000-0000-0000-000000000003', 3, 1, 'Toán Tư Duy Cơ Bản Lớp 3', 'Phép nhân chia nâng cao, góc xoay & chu vi', 'access_time'),
  ('c0000000-0000-0000-0000-000000000004', 4, 1, 'Thám Tử Hình Học & Lưới Ô Lớp 4', 'Phân số cơ bản, diện tích & toán trung bình cộng', 'grid_on'),
  ('c0000000-0000-0000-0000-000000000005', 5, 1, 'Toán Đỉnh Cao Lớp 5', 'Phân số, số thập phân, hình thang & chuyển động đều', 'functions')
ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description;

-- 3. Xây dựng thủ tục nạp toàn bộ 150 Bài Học và 1,500 Câu Hỏi Trắc Nghiệm chuẩn SGK
DO $$
DECLARE
  v_grade INT;
  v_topic_id UUID;
  v_lesson_num INT;
  v_q_num INT;
  v_lesson_id UUID;
  v_q_id UUID;
  v_title TEXT;
  v_subtitle TEXT;
  v_theory TEXT;
  v_essay_p TEXT;
  v_essay_g TEXT;
  v_mini_game TEXT;
  v_q_prompt TEXT;
  v_q_type TEXT;
  v_payload JSONB;
  v_hints JSONB;
  v_ans TEXT;
  v_opt1 TEXT;
  v_opt2 TEXT;
  v_opt3 TEXT;
  v_opt4 TEXT;
BEGIN
  -- LẶP QUA 5 KHỐI LỚP (GRADE 1 ĐẾN 5)
  FOR v_grade IN 1..5 LOOP
    IF v_grade = 1 THEN v_topic_id := 'c0000000-0000-0000-0000-000000000001'::UUID;
    ELSIF v_grade = 2 THEN v_topic_id := 'c0000000-0000-0000-0000-000000000002'::UUID;
    ELSIF v_grade = 3 THEN v_topic_id := 'c0000000-0000-0000-0000-000000000003'::UUID;
    ELSIF v_grade = 4 THEN v_topic_id := 'c0000000-0000-0000-0000-000000000004'::UUID;
    ELSE v_topic_id := 'c0000000-0000-0000-0000-000000000005'::UUID;
    END IF;

    -- LẶP QUA 30 BÀI HỌC CỦA MỖI LỚP
    FOR v_lesson_num IN 1..30 LOOP
      v_lesson_id := ('d' || LPAD(v_grade::text, 3, '0') || '0000-0000-0000-0000-' || LPAD(v_lesson_num::text, 12, '0'))::UUID;

      -- Đặt tên bài học & Lý thuyết chi tiết theo từng khối lớp
      IF v_grade = 1 THEN
        v_title := 'Bài ' || v_lesson_num || ': Số Học & Đếm Lớp 1 (Mốc ' || v_lesson_num || ')';
        v_subtitle := 'Làm quen các số, so sánh lớn bé và phép cộng trừ';
        v_mini_game := 'number';
        v_theory := '📚 LÝ THUYẾT SGK TOÁN LỚP 1:\n\n1. KHÁI NIỆM:\nCác số tự nhiên từ 1 đến 10 dùng để biểu diễn số lượng đồ vật quanh ta.\n\n2. QUY TẮC CỘNG TRỪ:\n• Thêm vào nghĩa là làm phép CỘNG (+).\n• Bớt đi hoặc cho bạn nghĩa là làm phép TRỪ (-).\n\n3. MẸO CỦA CÚ:\nĐếm que tính hoặc ngón tay từ bé đến lớn để không bị sót!';
        v_essay_p := 'Trong rổ có 5 quả táo, mẹ cho thêm 3 quả táo nữa. Hỏi trong rổ có tất cả bao nhiêu quả táo?';
        v_essay_g := 'Thực hiện phép tính cộng: 5 + 3 = 8 quả táo.';

      ELSIF v_grade = 2 THEN
        v_title := 'Bài ' || v_lesson_num || ': Phép Tính & Bảng Nhân Chia Lớp 2 (Mốc ' || v_lesson_num || ')';
        v_subtitle := 'Khám phá bảng cửu chương 2, 3, 5, đồng hồ và đơn vị đo';
        v_mini_game := 'number';
        v_theory := '📚 LÝ THUYẾT SGK TOÁN LỚP 2:\n\n1. BẢNG NHÂN & BẢNG CHIA:\nPhép nhân là phép cộng các số hạng bằng nhau. Ví dụ 2 × 3 = 2 + 2 + 2 = 6.\n\n2. ĐỒNG HỒ THỜI GIAN:\n• Kim ngắn chỉ giờ, kim dài chỉ phút.\n• Khoảng cách giữa 2 số liên tiếp trên mặt đồng hồ là 5 phút.\n\n3. ĐƠN VỊ ĐO:\n1 dm = 10 cm; 1 m = 100 cm; 1 kg = 1000 g.';
        v_essay_p := 'Có 18 viên kẹo chia đều cho 2 bạn. Hỏi mỗi bạn nhận được bao nhiêu viên kẹo?';
        v_essay_g := 'Thực hiện phép chia: 18 : 2 = 9 viên kẹo.';

      ELSIF v_grade = 3 THEN
        v_title := 'Bài ' || v_lesson_num || ': Toán Tư Duy & Chu Vi Lưới Ô Lớp 3 (Mốc ' || v_lesson_num || ')';
        v_subtitle := 'Nhân chia số có 3 chữ số, góc vuông và chu vi diện tích';
        v_mini_game := 'number';
        v_theory := '📚 LÝ THUYẾT SGK TOÁN LỚP 3:\n\n1. CHU VI & DIỆN TÍCH:\n• Chu vi hình chữ nhật: (Dài + Rộng) × 2.\n• Chu vi hình vuông: Cạnh × 4.\n\n2. ĐƠN VỊ ĐO THỜI GIAN & KHỐI LƯỢNG:\n1 giờ = 60 phút; 1 ngày = 24 giờ; 1 kg = 1000 gam.\n\n3. MẸO TÍNH NHANH:\nNhân nhẩm với số tròn chục: 20 × 4 = 80.';
        v_essay_p := 'Một mảnh sân hình chữ nhật có chiều dài 12m, chiều rộng 8m. Tính chu vi của mảnh sân đó.';
        v_essay_g := 'Chu vi mảnh sân = (12 + 8) × 2 = 40 (m).';

      ELSIF v_grade = 4 THEN
        v_title := 'Bài ' || v_lesson_num || ': Phân Số & Trung Bình Cộng Lớp 4 (Mốc ' || v_lesson_num || ')';
        v_subtitle := 'Khái niệm phân số, diện tích mét vuông và bài toán tìm hai số';
        v_mini_game := 'fraction';
        v_theory := '📚 LÝ THUYẾT SGK TOÁN LỚP 4:\n\n1. KHÁI NIỆM PHÂN SỐ:\nPhân số gồm tử số và mẫu số (khác 0). Rút gọn phân số bằng cách chia cả tử và mẫu cho ước chung lớn nhất.\n\n2. TRUNG BÌNH CỘNG:\nMuốn tìm trung bình cộng, ta tính tổng các số rồi chia cho số các số hạng.\n\n3. DIỆN TÍCH HÌNH BÌNH HÀNH:\nDiện tích = Đáy × Chiều cao.';
        v_essay_p := 'Trung bình cộng số tuổi của bố và con là 25 tuổi. Bố hơn con 30 tuổi. Tính tuổi của mỗi người.';
        v_essay_g := 'Tổng số tuổi = 25 × 2 = 50. Tuổi con = (50 - 30) : 2 = 10 tuổi. Tuổi bố = 40 tuổi.';

      ELSE
        -- LỚP 5
        IF v_lesson_num = 14 THEN
          v_title := 'Bài 14: Vận tốc trong Chuyển động đều';
          v_subtitle := 'Công thức v = s / t và bài toán thực tế chuyển động';
          v_mini_game := 'speed';
        ELSIF v_lesson_num < 14 THEN
          v_title := 'Bài ' || v_lesson_num || ': Phân Số & Quy Đồng Lớp 5 (Mốc ' || v_lesson_num || ')';
          v_subtitle := 'Tính chất phân số, cộng trừ cùng mẫu và khác mẫu số';
          v_mini_game := 'fraction';
        ELSE
          v_title := 'Bài ' || v_lesson_num || ': Số Thập Phân & Chuyển Động Lớp 5 (Mốc ' || v_lesson_num || ')';
          v_subtitle := 'Phép tính số thập phân, hình thang và toán chuyển động';
          v_mini_game := 'speed';
        END IF;

        v_theory := '📚 LÝ THUYẾT SGK TOÁN LỚP 5 CHI TIẾT:\n\n1. ĐẶT VẤN ĐỀ & ĐỊNH NGHĨA KHÁI NIỆM:\nNắm vững bản chất của Phân số, Số thập phân và Đại lượng chuyển động đều.\n\n2. CÔNG THỨC TOÁN HỌC CỐT LÕI:\n• Phân số: Quy đồng mẫu số chung rồi thực hiện phép tính.\n• Chuyển động đều: v = s : t; s = v × t; t = s : v.\n\n3. ĐƠN VỊ ĐO & BẢNG QUY ĐỔI:\n• 1 km = 1.000 m; 1 tấn = 1.000 kg; 1 m² = 100 dm² = 10.000 cm².\n• 1 giờ = 60 phút = 3.600 giây.\n\n4. MẸO TÍNH NHANH CỦA CÚ:\n★ Chuyển động ngược chiều: Tính Tổng vận tốc (v1 + v2).\n★ Chuyển động cùng chiều: Tính Hiệu vận tốc (v1 - v2).\n★ Dịch dấu phẩy khi nhân/chia với 10, 100, 1000.';
        v_essay_p := 'Một ô tô đi quãng đường 150 km trong 3 giờ. Sau đó đi tiếp 100 km trong 2 giờ. Tính vận tốc trung bình của ô tô trên cả quãng đường.';
        v_essay_g := 'Tổng quãng đường = 150 + 100 = 250 km. Tổng thời gian = 3 + 2 = 5 giờ. Vận tốc trung bình = 250 : 5 = 50 km/h.';
      END IF;

      -- Cập nhật hoặc thêm bài học vào bảng lessons
      INSERT INTO public.lessons (
        id, topic_id, lesson_number, title, subtitle, estimated_minutes, xp_reward, star_reward, order_index,
        theory, essay_prompt, essay_guidance, mini_game_type
      )
      VALUES (
        v_lesson_id,
        v_topic_id,
        v_lesson_num,
        v_title,
        v_subtitle,
        5,
        30 + (v_lesson_num * 2),
        3,
        v_lesson_num,
        v_theory,
        v_essay_p,
        v_essay_g,
        v_mini_game
      )
      ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title,
        subtitle = EXCLUDED.subtitle,
        theory = EXCLUDED.theory,
        essay_prompt = EXCLUDED.essay_prompt,
        essay_guidance = EXCLUDED.essay_guidance,
        mini_game_type = EXCLUDED.mini_game_type,
        order_index = EXCLUDED.order_index;

      -- Xóa các câu hỏi cũ của bài học này để nạp mới đủ 10 câu
      DELETE FROM public.questions WHERE lesson_id = v_lesson_id;

      -- NẠP CHÍNH XÁC 10 CÂU HỎI TRẮC NGHIỆM CHO TỪNG BÀI HỌC (Xen kẽ Toán Thực Tế & Hàn Lâm)
      FOR v_q_num IN 1..10 LOOP
        v_q_id := ('e' || LPAD(v_grade::text, 3, '0') || LPAD(v_lesson_num::text, 4, '0') || '-0000-0000-0000-' || LPAD(v_q_num::text, 12, '0'))::UUID;

        IF v_grade = 1 THEN
          v_q_type := 'multiplication_table';
          IF v_q_num % 2 = 1 THEN
            v_q_prompt := 'Câu ' || v_q_num || ' [Toán thực tế 🍎]: Trong giỏ có ' || (v_q_num + 2) || ' quả táo, bạn Nam cho thêm 2 quả nữa. Trong giỏ có tất cả:';
            v_ans := ((v_q_num + 2) + 2)::text || ' quả';
            v_opt1 := v_ans;
            v_opt2 := ((v_q_num + 2) + 1)::text || ' quả';
            v_opt3 := ((v_q_num + 2) + 3)::text || ' quả';
            v_opt4 := ((v_q_num + 2) + 4)::text || ' quả';
          ELSE
            v_q_prompt := 'Câu ' || v_q_num || ' [Toán hàn lâm]: Điền số thích hợp: ' || v_q_num || ' + 3 = ?';
            v_ans := (v_q_num + 3)::text;
            v_opt1 := v_ans;
            v_opt2 := (v_q_num + 2)::text;
            v_opt3 := (v_q_num + 4)::text;
            v_opt4 := (v_q_num + 5)::text;
          END IF;

        ELSIF v_grade = 2 THEN
          v_q_type := 'multiplication_table';
          IF v_q_num % 2 = 1 THEN
            v_q_prompt := 'Câu ' || v_q_num || ' [Toán thực tế 🐰]: Mỗi con thỏ có 2 chiếc tai. Hỏi ' || (v_q_num + 1) || ' con thỏ có tất cả bao nhiêu chiếc tai?';
            v_ans := ((v_q_num + 1) * 2)::text || ' chiếc tai';
            v_opt1 := v_ans;
            v_opt2 := ((v_q_num + 1) * 2 - 2)::text || ' chiếc tai';
            v_opt3 := ((v_q_num + 1) * 2 + 2)::text || ' chiếc tai';
            v_opt4 := ((v_q_num + 1) * 2 + 4)::text || ' chiếc tai';
          ELSE
            v_q_prompt := 'Câu ' || v_q_num || ' [Toán hàn lâm]: Kết quả của phép tính: 5 × ' || v_q_num || ' = ?';
            v_ans := (5 * v_q_num)::text;
            v_opt1 := v_ans;
            v_opt2 := (5 * v_q_num - 5)::text;
            v_opt3 := (5 * v_q_num + 5)::text;
            v_opt4 := (5 * v_q_num + 10)::text;
          END IF;

        ELSIF v_grade = 3 THEN
          v_q_type := 'multiplication_table';
          IF v_q_num % 2 = 1 THEN
            v_q_prompt := 'Câu ' || v_q_num || ' [Toán thực tế 📦]: Một mảnh vườn hình chữ nhật có chiều dài ' || (v_q_num + 5) || 'm, chiều rộng 4m. Diện tích là:';
            v_ans := ((v_q_num + 5) * 4)::text || ' m²';
            v_opt1 := v_ans;
            v_opt2 := ((v_q_num + 5) * 4 - 4)::text || ' m²';
            v_opt3 := ((v_q_num + 5) * 4 + 4)::text || ' m²';
            v_opt4 := ((v_q_num + 5) * 4 + 8)::text || ' m²';
          ELSE
            v_q_prompt := 'Câu ' || v_q_num || ' [Toán hàn lâm]: Tìm x biết x : 4 = ' || (v_q_num * 2) || '. Giá trị của x là:';
            v_ans := (v_q_num * 2 * 4)::text;
            v_opt1 := v_ans;
            v_opt2 := (v_q_num * 2 * 4 - 4)::text;
            v_opt3 := (v_q_num * 2 * 4 + 4)::text;
            v_opt4 := (v_q_num * 2 * 4 + 8)::text;
          END IF;

        ELSIF v_grade = 4 THEN
          v_q_type := 'multiplication_table';
          IF v_q_num % 2 = 1 THEN
            v_q_prompt := 'Câu ' || v_q_num || ' [Toán thực tế 🍕]: Một chiếc bánh pizza chia 8 phần, bạn ăn ' || (v_q_num % 4 + 1) || ' phần. Phân số chỉ số bánh đã ăn là:';
            v_ans := (v_q_num % 4 + 1)::text || '/8';
            v_opt1 := v_ans;
            v_opt2 := (8 - (v_q_num % 4 + 1))::text || '/8';
            v_opt3 := (v_q_num % 4 + 1)::text || '/10';
            v_opt4 := '8/' || (v_q_num % 4 + 1)::text;
          ELSE
            v_q_prompt := 'Câu ' || v_q_num || ' [Toán hàn lâm]: Rút gọn phân số ' || (v_q_num * 2) || '/' || (v_q_num * 4) || ' về dạng tối giản nhất:';
            v_ans := '1/2';
            v_opt1 := '1/2';
            v_opt2 := '2/4';
            v_opt3 := '1/4';
            v_opt4 := '3/4';
          END IF;

        ELSE
          -- LỚP 5: CHUYỂN ĐỘNG ĐỀU, PHÂN SỐ & SỐ THẬP PHÂN
          IF v_lesson_num = 14 OR v_title LIKE '%Vận tốc%' OR v_title LIKE '%chuyển động%' THEN
            v_q_type := 'word_problem';
            IF v_q_num = 1 THEN
              v_q_prompt := 'Câu 1 [Toán thực tế 🚗]: Ô tô đi từ Hà Nội đến Hải Phòng 120 km trong 2 giờ. Vận tốc ô tô là:';
              v_ans := '60 km/h'; v_opt1 := '60 km/h'; v_opt2 := '50 km/h'; v_opt3 := '240 km/h'; v_opt4 := '70 km/h';
            ELSIF v_q_num = 2 THEN
              v_q_prompt := 'Câu 2 [Toán hàn lâm]: Công thức tính quãng đường khi biết vận tốc (v) và thời gian (t) là:';
              v_ans := 's = v × t'; v_opt1 := 's = v × t'; v_opt2 := 's = v : t'; v_opt3 := 's = t : v'; v_opt4 := 's = v + t';
            ELSIF v_q_num = 3 THEN
              v_q_prompt := 'Câu 3 [Toán thực tế 🏍️]: Xe máy đi vận tốc 40 km/h trong 2,5 giờ. Quãng đường đi được là:';
              v_ans := '100 km'; v_opt1 := '100 km'; v_opt2 := '80 km'; v_opt3 := '90 km'; v_opt4 := '120 km';
            ELSIF v_q_num = 4 THEN
              v_q_prompt := 'Câu 4 [Toán hàn lâm]: Muốn tính thời gian (t) chuyển động ta làm phép tính gì?';
              v_ans := 't = s : v'; v_opt1 := 't = s : v'; v_opt2 := 't = s × v'; v_opt3 := 't = v : s'; v_opt4 := 't = s - v';
            ELSIF v_q_num = 5 THEN
              v_q_prompt := 'Câu 5 [Toán thực tế 🏃]: Vận động viên chạy 100m hết 20 giây. Vận tốc chạy là:';
              v_ans := '5 m/s'; v_opt1 := '5 m/s'; v_opt2 := '10 m/s'; v_opt3 := '20 m/s'; v_opt4 := '2 m/s';
            ELSIF v_q_num = 6 THEN
              v_q_prompt := 'Câu 6 [Toán thực tế ✈️]: Máy bay bay với vận tốc 800 km/h trên tuyến đường 1.600 km. Thời gian bay là:';
              v_ans := '2 giờ'; v_opt1 := '2 giờ'; v_opt2 := '3 giờ'; v_opt3 := '1.5 giờ'; v_opt4 := '4 giờ';
            ELSIF v_q_num = 7 THEN
              v_q_prompt := 'Câu 7 [Toán hàn lâm]: Hai xe chuyển động NGƯỢC CHIỀU gặp nhau, vận tốc gặp nhau được tính bằng:';
              v_ans := 'Tổng vận tốc (v1 + v2)'; v_opt1 := 'Tổng vận tốc (v1 + v2)'; v_opt2 := 'Hiệu vận tốc (v1 - v2)'; v_opt3 := 'Tích vận tốc (v1 × v2)'; v_opt4 := 'Thương vận tốc (v1 : v2)';
            ELSIF v_q_num = 8 THEN
              v_q_prompt := 'Câu 8 [Toán thực tế 🚲]: Đi xe đạp với vận tốc 15 km/h trong 4 giờ. Quãng đường đi được là:';
              v_ans := '60 km'; v_opt1 := '60 km'; v_opt2 := '45 km'; v_opt3 := '50 km'; v_opt4 := '75 km';
            ELSIF v_q_num = 9 THEN
              v_q_prompt := 'Câu 9 [Toán hàn lâm]: Đổi đơn vị thời gian: 1 giờ 15 phút bằng bao nhiêu giờ?';
              v_ans := '1.25 giờ'; v_opt1 := '1.25 giờ'; v_opt2 := '1.15 giờ'; v_opt3 := '1.5 giờ'; v_opt4 := '1.3 giờ';
            ELSE
              v_q_prompt := 'Câu 10 [Toán thực tế 🚂]: Đoàn tàu 200m chạy qua cây cầu 800m với vận tốc 20 m/s. Thời gian tàu qua cầu là:';
              v_ans := '50 giây'; v_opt1 := '50 giây'; v_opt2 := '40 giây'; v_opt3 := '10 giây'; v_opt4 := '60 giây';
            END IF;
          ELSE
            v_q_type := 'multiplication_table';
            IF v_q_num % 2 = 1 THEN
              v_q_prompt := 'Câu ' || v_q_num || ' [Toán thực tế 🍕]: Chia chiếc bánh làm 8 phần, đã ăn ' || (v_q_num % 5 + 1) || ' phần. Phân số chỉ phần đã ăn là:';
              v_ans := (v_q_num % 5 + 1)::text || '/8';
              v_opt1 := v_ans;
              v_opt2 := (8 - (v_q_num % 5 + 1))::text || '/8';
              v_opt3 := (v_q_num % 5 + 1)::text || '/10';
              v_opt4 := '8/' || (v_q_num % 5 + 1)::text;
            ELSE
              v_q_prompt := 'Câu ' || v_q_num || ' [Toán hàn lâm]: Thực hiện phép tính quy đồng: 1/2 + 1/4 = ?';
              v_ans := '3/4';
              v_opt1 := '3/4';
              v_opt2 := '2/6';
              v_opt3 := '1/3';
              v_opt4 := '5/8';
            END IF;
          END IF;
        END IF;

        v_payload := jsonb_build_object(
          'formula', v_q_prompt,
          'options', jsonb_build_array(v_opt1, v_opt2, v_opt3, v_opt4),
          'correctAnswer', v_ans
        );

        v_hints := jsonb_build_array(
          jsonb_build_object(
            'step', 1,
            'questionText', 'Hãy đọc kỹ dữ kiện và câu hỏi:',
            'hintText', 'Quan sát công thức hoặc phép tính phù hợp để chọn kết quả chính xác!'
          )
        );

        -- Insert câu hỏi vào bảng questions
        INSERT INTO public.questions (id, lesson_id, question_type, prompt, payload, socratic_hints, order_index)
        VALUES (v_q_id, v_lesson_id, v_q_type, v_q_prompt, v_payload, v_hints, v_q_num);

      END LOOP;
    END LOOP;
  END LOOP;
END $$;
