# Bản cài Android Matlingo 1.3.1

Đã kiểm tra ngày 26/10/2026. Giữ codebase và hệ giao diện REA hiện có.

## File để cài

- APK: `build/releases/Matlingo-1.3.1.apk` (59.645.225 byte, khoảng 56,9 MiB).
- Package: `com.learningstudio.brilliant_mobile`, versionName `1.3.1`, versionCode `5`.
- Android tối thiểu: **7.0 / API 24**. ABI: arm64-v8a, armeabi-v7a, x86_64.
- Target/compile SDK 36. Có Internet permission; Android OS Auto Backup bị tắt.
- SHA-256: `092b161ad4c67930e2ab875f6004ae65718e6476491ac51ecaf9b2124ad55931`.
- Chữ ký hiện dùng Android Debug identity của workspace, dành cho cài thử trực tiếp;
  chưa là cấu hình ký/phân phối Play Store. `apksigner verify` đã đạt.
- Bản cài đã được quét: không có email/password/ID của tài khoản readiness fixture.
  Build chỉ nhận URL và publishable key trong config mobile, không có service-role key.

## Cách cài và dùng

1. Chép/tải APK trên vào điện thoại Android, mở file và cấp quyền cài từ nguồn đó
   nếu Android yêu cầu. Nếu đang có bản cũ cùng chữ ký, cài cập nhật để giữ dữ liệu.
2. Mở Matlingo, đăng nhập tài khoản đã xác nhận; hoặc chọn Đăng ký.
3. Với tài khoản mới, nhập **mã 8 chữ số** trong email vào ô Mã xác nhận của app.
   Có Gửi lại mã và mục Đã có mã xác nhận? Nhập mã khi mở lại app.
4. Tạo/chọn hồ sơ, chọn lĩnh vực và mục tiêu, sau đó học.
5. Tiến độ lưu trên thiết bị; khi có mạng, personal backup và canonical API được gửi
   tự động cho hồ sơ đang mở. Màn hoàn thành/Tài khoản có trạng thái đồng bộ và XP
   được server xác nhận. Có nút Đồng bộ tiến độ ngay.
6. Chuyển máy bằng Tài khoản & sao lưu → tải danh sách → khôi phục thành hồ sơ riêng.
   Bản nháp local cũ vẫn giữ. Nếu thông tin hồ sơ khác nhau, xem và chọn bản muốn giữ.

App dùng Supabase được host công khai qua HTTPS, không cần máy tính/emulator chạy
để điện thoại kết nối. Đăng nhập lần đầu/xác nhận email cần Internet. Sau khi đã có
phiên đăng nhập và hồ sơ trên thiết bị, có thể học offline; kết quả chờ gửi khi có
mạng và app hoạt động lại. Không hứa background upload sau khi process bị Android dừng.

## Kiểm tra đã thực hiện

| Kiểm tra | Kết quả |
|---|---|
| `flutter analyze --no-pub` | Không có issues |
| Toàn bộ Flutter unit/widget tests | 147 passed |
| Deno check/lint/handler | 12 tests passed |
| Evaluator mobile/server | 729 ca, đủ 53 hoạt động |
| Standalone domain/depth/geometry | 50 / 2.491 / 17.552 checks |
| SQL học/backup smoke | Đạt, fixtures transaction-local rollback |
| HTTP stale canonical revision | HTTP 409, 1,54 giây trong lần đo |
| HTTP stale backup revision | HTTP 409, 0,12 giây trong lần đo |
| Android integration với Supabase thật | Passed trên Pixel 9 Android 15 / API 35 |
| APK release | Build, kiểm tra manifest/chữ ký, install -r và cold launch đạt |
| Runtime chính APK release | Process chạy, không có fatal exception/Flutter error trong lần kiểm tra |

Integration test kiểm tra đăng nhập sai/đúng qua UI, onboarding, hoàn thành cả topic
Logic, chấm server/cấp 30 XP, retry không thưởng thêm, metadata bị sửa ở phía cloud,
dialog lựa chọn bản trên máy và cập nhật thành công, mở lại LearningStore từ platform
preferences, cloud backup/restore và logout quay về Auth gate.

Auth/REST/Edge HTTP và SharedPreferences platform là thật. Thao tác văn bản dùng
test input để native IME không ghi đè sự kiện của test. Các workspace được cung cấp
trạng thái đáp án qua callback đang có; unit/widget tests riêng kiểm tra gesture và
toàn bộ 11 topic. Không gọi đây là kiểm thử thủ công trên điện thoại vật lý.

Test dùng một tài khoản được tạo riêng, namespace preferences riêng. Sau khi test,
đã xóa chính account/records/session của fixture và xác nhận readiness users = 0;
không xóa tài khoản hoặc preferences thực của người dùng. APK release khởi động
bằng entrypoint production và config mobile, không dùng config E2E.

Ảnh kiểm tra launch: `build/app-readiness/release-launch.png`.
Metadata artifact: `build/releases/Matlingo-1.3.1.json`.

## Những thay đổi giúp bản cài sử dụng được

- LearningJournal lưu pending session/attempt/completion cùng snapshot local trước
  network I/O. Draft đang gửi được đóng băng để retry cùng ID/payload khi mất response.
- JWT/request được gắn với owner đã chụp; đổi tài khoản/profile không nhận ack cũ.
- Backup restore fork ID mutable để hai thiết bị không dùng chung nhánh draft.
- Profile revision conflict có lựa chọn rõ ràng; bài làm và bản nháp không bị ghi đè.
- Backup HTTP có timeout, lỗi hiển thị đúng lý do. UI phân biệt local XP và verified XP.
- Sửa HTTP RPC conflict: custom 40001 khiến PostgREST retry vòng lặp. Wrapper mới
  trả PT409, giữ nguyên kiểm tra owner/CAS; Edge v4 trả safe HTTP 409.
  [Ghi nhận chính thức của Supabase](https://supabase.com/kb/troubleshooting/high-cpu-and-infinite-transaction-retries-when-using-custom-error-codes-in-rpc-functions).
- Mẫu confirmation email, subject và sender name Matlingo đã áp dụng và đọc lại
  xác minh trên hosted Auth; giữ SMTP credentials, Confirm email và OTP 8 chữ số.

## Phạm vi còn cần kiểm tra trên điện thoại của người dùng

- Chưa có điện thoại vật lý kết nối: cài, bàn phím thật, thông báo và điều kiện mạng
  của chính điện thoại vẫn cần người dùng xác nhận.
- Chưa quan sát hộp thư thật để xác nhận SMTP delivery/Spam/OTP end-to-end. Không
  tắt email confirmation, đổi mật khẩu hay xác nhận thủ công tài khoản của người dùng.
- AI chat/chạy code cần chọn engine và cấu hình provider/sandbox riêng. Không có
  LLM/code compiler dùng chung được cấp sẵn; thiếu engine phải hiện hướng dẫn.
- Chưa có tự merge incremental changes giữa hai máy. Backup restore là nhánh riêng,
  không tự ghi đè dữ liệu local chưa gửi. Nội dung vẫn bundled và được kiểm tra với
  release server; không tải/chạy mã evaluator do người dùng gửi.
- Voice/native notifications/Pyodide runtime và iOS chưa thuộc bản kiểm tra này.

## Build lại

```powershell
Set-Location -LiteralPath 'D:\Brilliant Clone\brilliant_mobile\repo-history'
flutter test --no-pub --reporter expanded
flutter analyze --no-pub
flutter build apk --release --dart-define-from-file='D:\Brilliant Clone\brilliant_mobile\repo-history\config\app.mobile.json'
```

Build release tuần tự sau tests, có pub/plugin generation. Trên SDK hiện tại,
`--no-pub` sau integration run có thể giữ debug registrant trong khi Gradle bỏ dev
plugins, gây lỗi IntegrationTestPlugin khi compile release. Không sửa tay generated
registrant hoặc đưa test dependency vào dependencies production để né lỗi.

Integration test live là lệnh riêng, cần account fixture/namespace riêng qua
config E2E được ignore; không chạy bằng tài khoản cá nhân, không commit credentials
và không dùng config E2E để build APK phân phối.
