# Đồng bộ frontend/backend — 2026-11-03

## Kết quả

Đã sửa ba điểm lệch được phát hiện trong audit: nội dung/evaluator, danh mục mobile và trạng thái chủ đề. Supabase project `seoswmcldwwytdrfrrrb` hiện có release `frontend-complete-2026-11-03` published, gồm 20 chủ đề / 139 hoạt động, cho client API app_version từ 1.3.2. Cả 20 metadata chủ đề hiện active.

`learning-api` v6 đã được triển khai. Release baseline 11 chủ đề / 53 hoạt động và evaluator v1 vẫn giữ nguyên. Database có 139 activities / 140 activity_versions: phiên bản thứ hai của `math-number-line` bổ sung metadata kỹ năng; phiên bản v1 và các phiên đã pin vẫn dùng được.

## Thay đổi

- `lib/experiments/activity_catalog.dart` là danh mục thuần Dart dùng chung cho mobile, công cụ xuất dữ liệu và evaluator mới; không còn danh mục server bị cố định ở 53 hoạt động.
- `tools/export_catalog.dart`, `tools/server_evaluator_v2.dart`, `tools/build_server_evaluator.py` và `supabase/catalog.json` bao phủ 139 hoạt động. Byte hash evaluator được giữ ổn định trên Windows qua `.gitattributes`.
- Router Edge giữ nguyên evaluator v1, chỉ chuyển nội dung mới sang evaluator v2. Hash do server chọn theo evaluator, không nhận từ client. Registry và các phiên bản published cũ không bị ghi đè.
- Migration mới `supabase/migrations/20261109000000_complete_learning_catalog.sql` thêm registry/content/release; giữ nguyên lịch sử và dữ liệu học. Không chạy db push/reset hoặc sửa migration cũ.
- Mobile tải danh mục qua repository khi đồng bộ, kể cả khi không có phiên đang chờ. Tên, mô tả, lĩnh vực, nhãn hành động, biểu tượng, thứ tự và trạng thái lấy từ backend. Cache tách theo owner, dùng lại khi mất mạng, không đưa danh mục tài khoản trước sang tài khoản mới.
- Chủ đề active chỉ xuất hiện khi có đầy đủ phiên bản bài đã phát hành và app hỗ trợ. Draft/archived được ẩn khỏi khám phá/lộ trình/gợi ý mới. Backend chặn session mới cho chủ đề không active; session đã pin vẫn tiếp tục được. Chưa phát hành nội dung không đồng nghĩa có thể học/xác nhận XP chỉ bằng việc chọn active.
- Dashboard giải thích đúng điều kiện hiển thị mobile. Giữ lại cấu trúc UI, theme hiện hành và các thay đổi có sẵn trong working tree.

## Kiểm chứng đã chạy

| Kiểm tra | Kết quả |
|---|---|
| Flutter toàn bộ | 240 test đạt |
| Flutter tập trung sau chỉnh metadata/visibility | 22 test đạt |
| `flutter analyze` | Không có vấn đề |
| Edge/Deno | 22 test đạt; check và lint đạt |
| Evaluator parity | 1.577 ca expanded + 729 ca legacy đạt |
| Kiểm tra standalone | 50 interaction / 2.491 depth / 17.552 geometry đạt |
| Migration idempotency | Chạy hai lần trong BEGIN/ROLLBACK thành công trước khi áp dụng |
| SQL live | admin_dashboard_smoke, learning_api_smoke, catalog_visibility_smoke đạt, toàn bộ rollback |
| HTTP live | Đăng nhập Auth thật; đủ 20 chủ đề / 139 hoạt động; đúng toàn bộ trường nội dung export |
| HTTP chấm bài/XP | 139 đáp án đúng; một đáp án sai mỗi chủ đề bị từ chối; 20 completion nhận đúng tổng 600 XP; retry giữ nguyên receipt |
| HTTP tương thích cũ | Catalog app_version 1.3.1 vẫn có 53 hoạt động; hoàn thành 6 hoạt động Math của release cũ; không cộng XP trùng |
| HTTP không đăng nhập | Thiếu/sai JWT trả 401, preflight trả 204 |
| Build | APK Android debug có cloud config và web admin có cloud config đạt |
| Diff | `git diff --check` đạt |

SQL visibility smoke đi từ RPC admin sửa tên/lưu trữ tới learning_catalog, xác nhận chặn session mới nhưng vẫn lưu draft cho session đã bắt đầu. Flutter test kiểm tra payload hiển thị, danh mục rỗng, metadata/icon, refresh không cần bài trong hàng đợi, mất mạng và cache theo owner.

Tài khoản HTTP fixture và toàn bộ attempts/sessions/completions/XP của nó đã xóa sau test. Truy vấn độc lập xác nhận 0 Auth user `matching-*@example.invalid` còn lại. Credentials fixture cục bộ đã xóa. Không xóa dữ liệu học của người dùng.

## Artifact và phạm vi xác minh

- APK: `build/app/outputs/flutter-apk/app-debug.apk`. Cần cập nhật APK này để mobile gửi app_version 1.3.2 và nhận metadata live; APK cũ vẫn gửi phiên bản API cũ.
- Web admin: `build/admin-web` (build local, không phải khẳng định đã publish hosting).
- Logs: `build/matching-flutter-tests.log`, `build/matching-live-http.log`, `build/matching-apk.log`, `build/matching-admin-build.log`, `build/matching-live-result.json`.
- Đã kiểm tra API thật và Flutter widgets; lượt này không chạy lại toàn bộ thao tác người dùng có giao diện trên emulator/trình duyệt, delivery WebSocket hay chất lượng microphone/giọng nói. Không suy rộng kết quả sang các phần đó hoặc merge incremental nhiều thiết bị.
- `adb devices` không có thiết bị đang kết nối, nên APK mới chưa được cài/chạy trên emulator hoặc điện thoại trong lượt này.
- Chủ đề/cơ chế hoàn toàn mới vẫn phải có evaluator đã kiểm chứng và app hỗ trợ trước khi phát hành. Đây là điều kiện tương thích, không bỏ kiểm tra để tự cấp XP.
- Security advisors không phát hiện public table thiếu RLS; tám bảng private deny-all vẫn có INFO như trước. Cảnh báo Auth leaked-password protection chưa bật là cấu hình có sẵn, không thay đổi trong task này: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection.
