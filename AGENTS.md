# MATHLINGO PROJECT AGENT RULES

> **BẮT BUỘC:** Áp dụng cho tất cả AI/coding agent làm việc trong repository MathLingo (`PRM393-FPT-FA26`). Mọi agent phải đọc và tuân thủ file này trước khi đọc, sửa, tạo hoặc xóa code, migration, test, cấu hình hoặc tài liệu dự án.
>
> Khi có xung đột, yêu cầu trực tiếp của người dùng được ưu tiên trong phạm vi không vi phạm an toàn dữ liệu, bảo mật và tính đúng đắn của dự án. Nếu không đủ thông tin, agent phải kiểm tra repository hoặc hỏi người dùng thay vì tự suy đoán.

## 1. Nguyên tắc cốt lõi: phạm vi và tránh tác động ngoài ý muốn

### 1.1. Surgical changes

- Chỉ chạm vào đúng file, hàm hoặc widget trực tiếp giải quyết yêu cầu.
- Không tự ý sửa phần không liên quan.
- Cấm tự ý format lại toàn bộ file, đổi tên biến, xóa comment cũ hoặc refactor cấu trúc thư mục khi không được yêu cầu.
- Trước khi chỉnh sửa phải thu thập đủ context: convention, framework, dependency, luồng gọi và test hiện có.
- Sau khi chỉnh sửa phải kiểm tra lại chính xác các file đã thay đổi và `git diff`.

### 1.2. Tương thích ngược

- Không xóa các file re-export/cầu nối trong `lib/features/<feature_name>/`, ví dụ `lib/features/home/home_screen.dart`.
- Với Database và Commerce, phải giữ tương thích schema cũ theo `legacy_commerce_compatibility.sql` và các tài liệu liên quan.

### 1.3. Kiến trúc và tài liệu

- Trước khi làm tính năng liên quan phân quyền hoặc thanh toán, phải đối chiếu:
  - `ROLE_COMMERCE_DEVELOPMENT_PLAN.md`
  - `SUPABASE_INTEGRATION_STATUS.md`
  - `DB_AUDIT.md` nếu file tồn tại
- UI/UX phải tuân thủ `lib/core/theme/` (`app_colors.dart`, `app_theme.dart`, `app_typography.dart`) và `ui_ux_pro_max/SKILL.md`.

## 2. An toàn cơ sở dữ liệu Supabase/PostgreSQL

### 2.1. Migration forward-only và idempotent

- Cấm chỉnh sửa trực tiếp migration đã tồn tại trong `supabase/migrations/` (đặc biệt các migration từ `20261013000000_...` đến `20261021000000_...`), trừ khi người dùng yêu cầu sửa lỗi cú pháp trực tiếp trên file đó.
- Mọi thay đổi schema, RPC, trigger hoặc policy phải nằm trong migration mới với timestamp tiếp theo.
- SQL migration phải idempotent, dùng các mẫu phù hợp như:
  - `CREATE TABLE IF NOT EXISTS`
  - `ADD COLUMN IF NOT EXISTS`
  - `CREATE OR REPLACE FUNCTION`
  - `DROP POLICY IF EXISTS ...` rồi `CREATE POLICY`

### 2.2. Không phá hủy dữ liệu

- Cấm dùng `DROP TABLE`, `DROP COLUMN` hoặc `TRUNCATE` trên bảng có dữ liệu người dùng, bao gồm nhưng không giới hạn: `profiles`, `kid_profiles`, `study_sessions`, `subscriptions`, `payment_orders`, `wardrobe_items`, `questions`, `lessons`.
- Nếu cần thay đổi dữ liệu/schema có rủi ro, phải chọn phương án backward-compatible và nêu rõ trong kết quả.

### 2.3. RLS và server-side authority

- Mọi bảng mới trong schema `public` bắt buộc bật RLS bằng `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;` và có policy rõ ràng cho role phù hợp (`admin`, `parent`, `kid`/authenticated user).
- Các thao tác nhạy cảm liên quan tiền tệ/điểm thưởng bắt buộc qua Supabase RPC `SECURITY DEFINER` có kiểm tra `auth.uid()` hoặc Edge Function.
- Không tính toán và ghi đè trực tiếp số dư từ Flutter Client.
- Quy định này áp dụng cho Stars, Gems, vật phẩm `mascot_wardrobe`, `subscriptions`, `verified_learning_sessions` và thanh toán VNPay.

### 2.4. Secrets

- Không hardcode hoặc commit `SUPABASE_SERVICE_ROLE_KEY`, `VNPAY_HASH_SECRET` hoặc API key vào `lib/` hay source code.
- Chỉ cấu hình secrets qua biến môi trường hoặc file mẫu như `config/app.example.json`.

## 3. Kiến trúc Flutter và Edge Functions

### 3.1. Phân tách tầng

- `lib/features/` chỉ đảm nhận UI và bắt sự kiện; không gọi trực tiếp `Supabase.instance.client` trong Widget.
- `lib/data/providers/app_state_provider.dart` quản lý state ứng dụng, đồng bộ `KidProfile`, gói cước, hearts và streak.
- Mọi truy vấn Supabase/cache cục bộ phải nằm trong Repository tương ứng tại `lib/data/repositories/` và model tại `lib/data/models/`.
- Các repository chuẩn gồm: `auth_repository`, `commerce_repository`, `kid_repository`, `lesson_repository`, `mascot_repository`, `study_repository`, `subscription_repository` và các repository phù hợp khác đang có trong dự án.

### 3.2. Role và Parent Gate

- Tính năng dành cho phụ huynh (`parent_portal`, đổi PIN, Plus, thanh toán) phải đi qua `parent_gate_dialog.dart` để xác thực.
- Tính năng quản trị trong `lib/features/admin/` phải kiểm tra đúng quyền Admin từ `role_ui.dart` và Database.

### 3.3. Edge Functions

- Khi sửa `ai-tutor`, `commerce-reconcile` hoặc các hàm `vnpay-*` (`checkout`, `ipn`, `query`, `refund`, `return`), phải dùng các tiện ích chung trong `supabase/functions/_shared/http.ts` và `supabase/functions/_shared/vnpay.mjs`.
- Phải giữ nhất quán CORS, checksum/chữ ký bảo mật và xử lý lỗi.

## 4. Quy trình kiểm thử bắt buộc

Sau mọi tính năng mới hoặc bugfix, agent bắt buộc thực hiện các bước phù hợp với pipeline `.github/workflows/verify.yml` và `VALIDATION.md` trước khi kết thúc.

### 4.1. Static analysis và cú pháp Flutter

Chạy:

```bash
flutter analyze
```

Không được kết luận hoàn thành nếu chưa chạy hoặc chưa báo rõ lý do không thể chạy.

### 4.2. Format và diff

- Chỉ format các file đã chạm vào, không format toàn bộ repository nếu không cần thiết.
- Chạy formatter phù hợp với loại file.
- Chạy:

```bash
git diff --check
```

### 4.3. Test liên quan

- Chạy test trực tiếp liên quan đến thay đổi và các test bắt buộc theo `VALIDATION.md` nếu có.
- Nếu thay đổi Flutter UI/navigation, phải ưu tiên widget test hoặc kiểm tra build/analyze tương ứng.
- Nếu thay đổi SQL/RPC/Edge Function, phải chạy validation backend tương ứng và kiểm tra idempotency/RLS.
- Nếu môi trường không cho phép chạy một bước, phải nêu rõ bước nào bị bỏ qua, lý do và ảnh hưởng.

### 4.4. Kiểm tra cuối

Trước khi trả kết quả:

1. Đọc lại các file đã tạo/sửa.
2. Kiểm tra `git status` và `git diff`.
3. Xác nhận không có thay đổi ngoài phạm vi yêu cầu.
4. Báo cáo rõ các file đã thay đổi, kiểm thử đã chạy và giới hạn còn lại.

## 5. Quy tắc thao tác của agent

- Luôn trình bày kế hoạch ngắn gọn trước khi thực hiện task.
- Luôn dùng đường dẫn tuyệt đối khi tham chiếu file trong báo cáo hoặc thao tác.
- Không tự ý xóa dữ liệu, migration, file cầu nối hoặc secrets.
- Không tuyên bố đã kiểm thử nếu chưa thực sự chạy lệnh kiểm thử.
- Nếu phát hiện thay đổi có sẵn của người dùng, không ghi đè hoặc hoàn tác nếu chưa được yêu cầu.
- Khi phát hiện rủi ro bảo mật, mất dữ liệu hoặc xung đột kiến trúc, phải dừng thay đổi rủi ro và nêu rõ vấn đề.

