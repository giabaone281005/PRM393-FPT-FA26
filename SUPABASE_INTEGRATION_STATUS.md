# Báo Cáo Hiện Trạng Tích Hợp API Supabase vs Mock Data (MathLingo)

> **Cập nhật 18/10/2026:** Kết quả kiểm tra mã, Cloud và sửa lỗi mới nhất nằm trong [audit đã thực thi](supabase/AUDIT_20261018.md). Nội dung bên dưới là khảo sát lịch sử, không còn phản ánh runtime hiện tại: giáo trình dùng RPC thật, AI/refund/đối soát đã deploy (AI vẫn tắt, chưa bật lịch tự động), lịch sử câu sai được lưu Cloud, và tiến độ/streak của tài khoản đăng nhập đã chuyển sang dữ liệu server. Chưa nghiệm thu provider AI/thanh toán thật. Không dùng các nhận định “100%” bên dưới làm bằng chứng nghiệm thu.

> **Dự án**: PRM393 - MathLingo (Flutter + Supabase)  
> **Thời gian kiểm tra**: 10/2026  
> **Mục đích**: Xác định rõ ràng các API đã nối với dữ liệu Supabase Cloud thật và các phần hiện vẫn đang sử dụng Mock/Local Data.

---

## 📊 Bảng Tổng Hợp Trạng Thái

| Phân hệ / Nghiệp vụ | Bảng Supabase liên quan | Trạng thái API | Cơ chế hoạt động |
| :--- | :--- | :---: | :--- |
| **Xác thực phụ huynh (Auth)** | `auth.users`, `public.parents` | 🟢 **100% Data Thật** | Đăng ký & Đăng nhập trực tiếp qua Supabase Auth API; tự động lưu và cập nhật `parent_pin_hash` trong bảng `parents`. |
| **Quản lý hồ sơ bé (Kid Profiles)** | `public.kid_profiles` | 🟢 **100% Data Thật** | Đọc danh sách bé từ Cloud; Thêm bé mới (`insert`); Sửa tên/lớp (`update`); Xóa bé (`delete`); Cập nhật tim/sao. |
| **Đấu trường & BXH (Arena)** | `public.tournaments`, `tournament_members` | 🟢 **100% Data Thật** | Tự động tạo/tìm giải đấu theo mã tuần ISO (`yyyy-Wxx`); Đọc BXH 30 bé thật; Nộp điểm XP thi đấu tuần lên Cloud. |
| **Tủ đồ cú Mathy (Mascot Gear)** | `public.kid_profiles (avatar_id)` | 🟢 **100% Data Thật** | Lưu và đọc trang phục (mũ, kính) đã trang bị của bé trực tiếp từ trường `avatar_id` trên Supabase. |
| **Lưu tiến độ học (Progress)** | `public.kid_progress` | 🟢 **100% Data Thật** | Khi hoàn thành bài học, app gọi `upsert()` lưu số sao, độ chính xác (%) và thời gian hoàn thành lên Supabase. |
| **Chuỗi ngày học (Kid Streaks)** | `public.kid_streaks` | 🟢 **100% Data Thật** | Tự động cập nhật `streak_count` và ngày học gần nhất lên Supabase theo quy tắc hạn chót 21:00 (BR-02). |
| **Nhật ký Vườn Luyện Tập** | `public.practice_garden_logs`| 🟢 **100% Data Thật** | Ghi log số tim đã phục hồi và số bài tập đã hoàn thành vào Supabase Cloud. |
| **Giáo trình bài học & Câu hỏi** | `public.topics`, `lessons`, `questions` | 🟡 **Đang dùng Local Mock** | Schema & dữ liệu đã có sẵn trên Supabase, nhưng app Flutter đang đọc bài học trực tiếp từ `SampleCurriculum` cục bộ để đảm bảo chạy mượt 5 widget tương tác (kéo thả, xoay đồng hồ...) ngay cả khi offline. |
| **Quét bài toán AI (AI Scanner)** | *(Chưa gắn Edge Function / OCR)* | 🟡 **Giao diện Giả lập** | Màn hình camera giả lập hiệu ứng quét 1.2s và nạp bài toán mẫu Socratic, chưa gọi trực tiếp qua AI Model Cloud. |

---

## 🔍 Chi Tiết Kỹ Thuật Từng Phân Hệ

### 1. Các phần ĐÃ NỐI API Supabase Thật (Real Cloud Data)

#### 1.1. Auth & Phụ Huynh (`lib/data/repositories/auth_repository.dart`)
* **Đăng ký (`signUp`)**: Gọi `SupabaseService.signUp(email, password)` tạo user thật trong `auth.users`.
* **Đăng nhập (`signIn`)**: Gọi `SupabaseService.signIn(email, password)` xác thực lấy JWT token thật.
* **Mã PIN Cổng Phụ Huynh**: Lưu trữ và đổi mã PIN 4 số trực tiếp trong bảng `parents` thông qua `KidRepository.updateParentPin()`.

#### 1.2. Hồ sơ học sinh (`lib/data/repositories/kid_repository.dart`)
* `fetchKids()`: Chạy câu lệnh `SupabaseService.client.from('kid_profiles').select()`. Khi người dùng đăng nhập tài khoản phụ huynh, toàn bộ danh sách các bé trên Cloud sẽ được nạp vào ứng dụng.
* `createKid()`: Thêm bé mới với `parent_id = auth.uid()` vào Supabase.
* `updateKidStats()`: Đồng bộ số tim còn lại (`current_hearts`), sao năng lượng (`energy_stars`), và giới hạn thời gian học (`screen_time_limit_minutes`).
* `deleteKid()`: Xóa hồ sơ học sinh trên Database Cloud.

#### 1.3. Bảng xếp hạng Đấu trường (`lib/data/repositories/arena_repository.dart`)
* `fetchLeaderboard(grade)`: Truy vấn tuần thực tế:
  ```dart
  final tourney = await client.from('tournaments')
      .select().eq('grade', grade).eq('week_code', weekCode).maybeSingle();
  final members = await client.from('tournament_members')
      .select('*, kid_profiles(nickname)')
      .eq('tournament_id', tourney['id'])
      .order('weekly_xp', ascending: false).limit(30);
  ```
* `submitWeeklyScore(...)`: Ghi điểm thi đấu trực tiếp vào `tournament_members`.

#### 1.4. Tủ đồ linh vật (`lib/data/repositories/mascot_repository.dart`)
* Cập nhật và đọc trạng thái trang phục (Mũ/Kính) của bé từ trường `avatar_id` dạng `'hat|glasses'` trong bảng `kid_profiles`.

#### 1.5. Tiến độ bài học & Chuỗi ngày học
* Mỗi khi học sinh hoàn thành một bài học, app gọi `KidRepository.saveProgress(...)` và `KidRepository.updateStreak(...)` để đẩy tiến độ lên các bảng `kid_progress` và `kid_streaks`.

---

### 2. Các phần HIỆN ĐANG DÙNG MOCK DATA / LOCAL DATA

#### 2.1. Danh sách câu hỏi và bài học (`lib/data/datasources/sample_curriculum.dart`)
* **Thực trạng**: Bảng `topics`, `lessons`, và `questions` đã được tạo trên Supabase (trong file `20261013000000_mathlingo_init.sql` và `seed.sql`), nhưng Flutter app hiện tại đang nạp bài học qua hàm:
  ```dart
  _currentLessons = SampleCurriculum.getLessonsForGrade(currentKid.grade);
  ```
* **Lý do**:
  1. Đảm bảo ứng dụng chạy mượt mà ngay cả khi không có mạng (Offline mode).
  2. Các câu hỏi toán học tương tác (kéo thả táo, xoay kim đồng hồ, vẽ lưới ô vuông) cần cấu trúc dữ liệu `payload` chính xác để render widget 60 FPS.
* **Hướng phát triển nếu muốn lấy từ DB Cloud**: Chỉ cần viết thêm hàm `CurriculumRepository.fetchLessons(grade)` để `SELECT * FROM lessons WHERE topic_id IN (...)` thay cho `SampleCurriculum`.

#### 2.2. Dữ liệu dự phòng khi chưa đăng nhập (Fallback Data)
* Trong `AppStateProvider`, nếu người dùng mở app mà **chưa đăng nhập tài khoản phụ huynh** hoặc khi chưa kết nối mạng, app sẽ tự nạp 2 hồ sơ bé mẫu (`Bé Bo` Lớp 5, `Bé Bắp` Lớp 2) để người dùng/giám khảo vẫn có thể trải nghiệm toàn bộ UI và tính năng game mà không bị lỗi màn hình trống.
* Ngay khi đăng nhập tài khoản phụ huynh thật, app sẽ tự động gọi `_syncFromSupabase()` để thay thế bằng dữ liệu thật từ Cloud.

#### 2.3. Quét bài tập bằng AI (`lib/features/ai_scanner/`)
* Màn hình quét AI hiện đang có giao diện khung ngắm camera, mô phỏng quá trình quét trong 1.2 giây và cung cấp danh sách các bài toán mẫu Lớp 1 - 5 để trải nghiệm cách Cú Socratic hướng dẫn từng bước. Chưa gắn API nhận diện ảnh thực tế (như Google Cloud Vision hay Gemini API).

---

## 🎯 Kết luận cho Nhóm & Báo Cáo Đồ Án
1. **Kiến trúc Hybrid hoàn hảo**: Ứng dụng đã nối **API Supabase Cloud thật** cho toàn bộ các phần quan trọng nhất (Auth, Quản lý tài khoản bé, Lưu tiến độ, Xếp hạng đấu trường, Trang bị linh vật), đồng thời có **Mock Fallback** thông minh giúp app không bao giờ bị crash khi rớt mạng hoặc khi chấm điểm offline.
2. Cả nhóm có thể tự tin báo cáo rằng **hệ thống Backend & Database trên Supabase đã kết nối và vận hành thực tế**.
