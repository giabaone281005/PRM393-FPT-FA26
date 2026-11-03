# Báo cáo commit, merge và kiểm thử tự động — 03/11/2026

Root workspace: `D:\Brilliant Clone\brilliant_mobile\repo-history`. Múi giờ: UTC+7. Yêu cầu: commit/push lên nhánh, merge vào main, bật emulator chạy test tự động và bàn giao tài liệu toàn dự án.

## 1. Git và phạm vi bàn giao

| Bước | Kết quả |
|---|---|
| Baseline | `36bf699` trên main; nhiều thay đổi có sẵn của người dùng |
| Nhánh tính năng | `feat/catalog-sync-final-validation` |
| Commit source | `65d8c72` — Complete mobile catalog sync and preserve versioned server evaluators |
| Push nhánh | Thành công lên origin, không force push |
| Merge source vào main | `8d10419` — merge không xung đột, giữ lịch sử nhánh |
| Push main | Thành công, trước khi chạy emulator theo yêu cầu |
| Fix JSONB phát hiện trong E2E | `aed2384`, merge/push main `70e9699` |
| Rà soát harness responsive/Realtime | `715a3b0`, merge/push main `72e3e2a` — nền mã của lượt traversal đầy đủ |
| Fix cùng khác biệt JSONB trong canonical sync | `81cd00d`, merge/push main `9ccece9` — nền mã của lượt xác minh tập trung sau traversal |
| Harness chờ backup/logout | `d33a2f3`, merge/push main `ef4a687` |
| Harness Admin tập trung | `09801ef`, merge/push main `9c17c2d` — source cuối trước commit tài liệu |

Source commit gồm 44 file: catalog/cache mobile theo owner, metadata/visibility, evaluator v2 và tương thích v1, migration additive đã có sẵn trong workspace, dashboard, bản sửa reduced-motion, tests, exporter và báo cáo liên quan. Không chỉnh migration cũ. Lượt này không triển khai lại Edge Function hoặc áp dụng migration lên live database.

Các tệp local ngoài source như bản ghi hội thoại, `output/` và thư mục skill `ui-ux-pro-max-skill-main/` được giữ nguyên và không đưa vào commit sản phẩm. Không commit config mobile, credential fixture, APK hay cache build. Secret scan có mục tiêu trên 44 file staged không phát hiện session/service-role JWT, private key hoặc mẫu secret provider được kiểm tra; không phải quét toàn bộ lịch sử Git.

Tài liệu cuối cùng và bằng chứng được commit/push tiếp sau khi tổng hợp kết quả; xem mục kết quả cuối ở cuối báo cáo.

## 2. Môi trường thực thi

- Flutter 3.47.4 stable, Dart 3.13.3, DevTools 2.60.0.
- Deno 2.9.6; binary tìm thấy trong npm cache, không nằm trực tiếp trên PATH.
- Windows, Android SDK tại `C:\Users\kzrok\AppData\Local\Android\sdk`.
- Emulator Pixel_9 được khởi động bằng Flutter, serial `emulator-5554`, Android 15/API 35/x86_64; sử dụng native storage và kết nối mạng thật.
- Backend Supabase project `seoswmcldwwytdrfrrrb`: learning-api v6, tutor-chat v4 ACTIVE; hai release published baseline và frontend-complete.
- Hai tài khoản disposable của lượt test có marker riêng; learner và Admin không dùng tài khoản cá nhân.

## 3. Kiểm tra tự động ngoài emulator

| Kiểm tra đã thực sự chạy | Kết quả |
|---|---|
| `flutter analyze` | PASS, không issue, 61,9 giây phần analyze |
| `flutter analyze --no-pub` sau merge | PASS, không issue |
| `flutter test --no-pub --reporter expanded` | PASS, 240/240 ban đầu; 241/241 sau fix catalog; 242/242 sau fix sync |
| Node server/mobile evaluator parity | PASS, 1.577 expanded + 729 legacy; đủ 139 activities |
| `dart tools/check_diverse.dart` | PASS, 50 checks |
| `dart tools/check_depth.dart` | PASS, 2.491 checks |
| `dart tools/check_space.dart` | PASS, 17.552 checks |
| Deno check learning-api/tutor-chat | PASS, exit 0 |
| Deno lint các file cùng phạm vi CI | PASS, checked 9 files, exit 0 |
| Deno handler + app knowledge tests | PASS, 22/22 |
| SQL admin_dashboard_smoke | PASS, BEGIN/ROLLBACK |
| SQL learning_api_smoke | PASS, BEGIN/ROLLBACK |
| SQL catalog_visibility_smoke | PASS, BEGIN/ROLLBACK |
| `git diff --check`, staged diff check | PASS trước source commit; kiểm lại khi bàn giao |

SQL kiểm quyền owner/Admin/anonymous/suspended, chống tự ghi XP/kết quả verified, receipt/idempotency, revision conflict, completion, change cursor, assets và topic metadata/visibility. Các fixture của smoke transaction đã rollback. Đây là test trên schema deployed, không phải khẳng định cả chuỗi migration legacy replay sạch từ database rỗng.

GitHub Actions của source `72e3e2a` trên main: [Verify Matlingo — PASS cả Flutter và Edge](https://github.com/giabaone281005/PRM393-FPT-FA26/actions/runs/41636568472). [CI bản sửa app đầy đủ `9ccece9`](https://github.com/giabaone281005/PRM393-FPT-FA26/actions/runs/41639404599) cũng PASS. Pipeline gồm build debug APK và Admin web; không suy ra đã publish Admin hosting từ việc build thành công. Hai merge sau đó chỉ sửa harness integration; trạng thái CI source cuối được ghi ở mục 8.

## 4. Bộ test emulator và điều chỉnh harness

Bộ chạy: [full_stack_journey_test.dart](<D:/Brilliant Clone/brilliant_mobile/repo-history/integration_test/full_stack_journey_test.dart>). Test dùng tap/drag/text qua Flutter integration driver trên emulator thật; Auth, REST/RPC, Edge và storage preferences là dịch vụ thật.

Harness cũ viết trước release đầy đủ nên chỉ nộp sáu activity Logic và kỳ vọng tổng verified XP bằng 30. Đã cập nhật để chờ tổng 600 XP sau traversal 20 chủ đề, nộp đủ tám activity Logic trong session kiểm tra lại và kỳ vọng thưởng thêm 0. Vẫn kiểm receipt retry bằng equality để chống thưởng lặp. Cập nhật tooltip edit topic theo UI hiện tại và yêu cầu event Realtime tăng sau baseline subscribe.

Giới hạn tương tác: các cơ chế có driver dùng controls thật; một số mô hình cũ dùng public answer fixture qua callback workspace rồi bấm Kiểm tra/Hoàn thành. Số lượng chính xác lấy từ result của lượt chạy ở mục kết quả cuối; không gọi toàn bộ 139 bài là hoàn toàn gesture native.

Một lần khởi chạy host dừng ngay sau build vì stdout Python mặc định cp1252 không mã hóa được ký tự dấu tick của Flutter. Đây là lỗi encoding của runner host, chưa phải kết quả test ứng dụng. Đã giữ log lần đó và chạy lại bằng `python -X utf8`; không nới assertion hay sửa code app để bỏ lỗi.

Lượt E2E tiếp theo đi được 52 activity/sáu chủ đề rồi dừng tại Mạch điện. Đây là **lỗi ứng dụng thật**: JSONB trả RGB `[0,0,1]`, catalog Dart dùng `[0.0,0.0,1.0]`; so sánh chuỗi JSON loại nhầm topic dù payload số tương đương. Đã sửa nhỏ trong `lib/data/models/mobile_catalog.dart`, thêm regression trong `test/mobile_catalog_test.dart`: nhận đủ 20/139 sau chuẩn hóa kiểu số, vẫn loại scene có `0.5` hoặc chuỗi `"1"` sai. Chẩn đoán lại bằng payload live thấy đủ 20 topic. Lượt fail được giữ riêng; fixture của lượt đó đã dọn trước khi tạo fixture sạch để chạy lại.

Một lượt sau được chủ động dừng sớm khi rà soát phát hiện selector edit Admin chỉ khớp bảng desktop trong khi emulator dùng card mobile. Harness đã hỗ trợ cả hai tooltip và chuyển observer sang Auth client riêng để tránh dùng chung channel của dashboard. Đây là lượt bị hủy để chỉnh harness, không phải PASS hay một lỗi app bổ sung. Fixture được dọn rồi tạo run mới.

Lượt đầy đủ trên `72e3e2a` đã PASS traversal **139 activity / 20 chủ đề**, trong đó **92 controls + 47 answer fixtures**, cùng snapshot retry/conflict. Tuy nhiên assertion canonical XP dừng ở 570 thay vì 600: cùng phép so sánh JSON theo kiểu số còn tồn tại trong `LearningSyncController`, khiến session Mạch điện bị hoãn. Truy vấn độc lập xác nhận đúng 19 session/completion, thiếu circuits. Đây là lượt tổng thể FAIL, không được đổi nhãn thành PASS chỉ vì UI đã hoàn tất.

Đã dùng chung `equivalentCatalogValue` cho catalog và bộ lọc sync, không thay canonical request hash/receipt của metadata. Regression mới kiểm completed circuits với RGB dạng integer được sync ra khỏi journal, nhận 30 XP và retry không tăng completion. Toàn bộ 242 Flutter tests và analyze PASS. Sau đó dùng cờ `E2E_RESUME_AFTER_TRAVERSAL` để đăng nhập từ namespace native trống, lấy snapshot thật của cùng fixture và chạy phần sync/offline/restore/Admin còn lại. Lượt tiếp theo có counter traversal bằng 0; không cộng 139 hoạt động cũ thành lượt gesture mới. Bằng chứng các giai đoạn được lưu riêng.

Lượt tiếp nối đầu xác nhận sync/600 XP/offline/history nhưng gặp race ở nút Đăng xuất khi automatic backup đang busy; harness chờ rảnh và thử lại hành động UI theo thông báo sẵn có. Lượt tiếp theo qua logout/restore/ownership nhưng dừng ở một read tìm tài khoản Admin với thông báo kết nối; cùng RPC trên host trả đúng một fixture và emulator ping/DNS hoạt động khi kiểm lại. Cuối cùng dùng `E2E_ADMIN_ONLY`, xác thực lại đúng hai fixture và kiểm riêng Admin. Đây là chiến lược kiểm theo phạm vi ảnh hưởng, không nới assertion quyền hay sửa dữ liệu để giả lập thành công.

## 5. Đối chiếu backend và an toàn dữ liệu

Trước lượt emulator: 8 tài khoản có sẵn ngoài fixture, 20 topic; fingerprint backup ngoài fixture theo JSON đã sắp xếp là `842ed94722fdc5e8385ff6264f5afb94`. Mỗi lần query fingerprint phải dùng cùng biểu thức để so sánh, không so với hash báo cáo lịch sử dùng thứ tự khác.

Inventory live xác nhận 139 activities, 140 activity_versions, hai published releases. Tất cả 24 bảng ứng dụng public/private bật RLS; public tables thiếu RLS = 0. Advisors còn tám INFO private deny-all không policy và một WARN Auth leaked-password protection disabled. Không thay cấu hình Auth trong lượt này.

Fixture provision dùng service credential chỉ trong bộ nhớ host; không in key, không đưa service-role vào Flutter/APK. Mật khẩu fixture nằm trong file ignored ở build; runner lọc password/JWT khỏi log công khai. Cleanup có kiểm hai UUID và marker run, chỉ xóa dữ liệu test cùng topic tạm đúng marker, không reset/truncate bảng.

Sau test: fixture có **1 profile canonical, 20 completion, 20 dòng thưởng, tổng 600 XP và 156 attempts**; topic thử archived. Sau cleanup, cả ba run fixture đã tạo trong lượt làm việc còn **0 user thử/0 topic thử**, số account có sẵn = 8 và topic thật = 20. Phiên/refresh token của fixture được dọn trước user.

Fingerprint toàn bộ backup hiện tại khác baseline vì có **một backup mới ngoài fixture lúc 19:54:55 UTC+7**. Khi lọc đúng các hàng có trước thời điểm baseline, hash vẫn là `842ed94722fdc5e8385ff6264f5afb94`: các hàng cũ không đổi. Hash toàn bộ hiện tại là `692254ac192ac242d40205e86d539b21`. Không đủ dữ liệu để quy nguồn thao tác tạo backup mới; bản ghi đó được giữ nguyên, không hoàn tác. Không dùng hash tổng đã thay đổi để tuyên bố toàn bộ database bất biến.

## 6. Phạm vi chưa xác nhận

- Không chứng minh chất lượng âm thanh nghe được, STT/phát âm trên thiết bị thật; traversal có fallback nhập chữ.
- Khôi phục storage namespace mới trên cùng emulator không phải test hai điện thoại vật lý hoặc mọi tình huống merge đồng thời.
- Không kiểm delivery email OTP/recovery thực, iOS hoặc physical-device QA.
- Không triển khai/test live mọi provider cá nhân, Docker/Judge0/Pyodide sandbox.
- Không build phát hành store với production keystore trong lượt này.
- RLS/advisors và secret scan có phạm vi nêu trên, không phải pentest/toàn bộ Git history.
- Không có một lượt fresh từ onboarding đến Admin PASS toàn bộ sau bản sửa sync cuối. Phần UI đủ 139 hoạt động và các checkpoint còn lại được xác minh qua các lượt tập trung riêng như mục 8; không gọi các lượt tổng thể FAIL là PASS.

## 7. Tài liệu dự án đi kèm

[PROJECT_ARCHITECTURE_VI.md](<D:/Brilliant Clone/brilliant_mobile/repo-history/final docs/PROJECT_ARCHITECTURE_VI.md>) có kiến trúc frontend/backend, stack theo module, 24 bảng Supabase, API/RPC, sync/offline, AI/code/audio engines, 40 mechanisms và ma trận từng activity trong 139 hoạt động, kèm chỉ mục đường dẫn tuyệt đối.

## 8. Kết quả cuối của lượt emulator, CI và bàn giao

**Các nhóm chức năng yêu cầu đã có bằng chứng thực thi; kết quả được tách theo từng lượt.**

CI source cuối `9c17c2d` trên main đã **PASS cả Flutter và Edge**, gồm Android debug APK và Admin web build: [Verify Matlingo](https://github.com/giabaone281005/PRM393-FPT-FA26/actions/runs/41640899204). [CI nhánh](https://github.com/giabaone281005/PRM393-FPT-FA26/actions/runs/41640894144) cũng PASS. Commit tài liệu sau đó chỉ bổ sung Markdown và bằng chứng, không đổi source app/backend.

| Lượt / thời gian UTC+7 | Kết quả phạm vi | Trạng thái cả lượt |
|---|---|---|
| Traversal, 19:32:39–19:50:15, `72e3e2a` | 20/20 topic, 139/139 activities, 92 controls + 47 answer fixtures; snapshot retry/conflict PASS | FAIL ở canonical XP 570; đã tìm và sửa nguyên nhân |
| Học/tài khoản tiếp nối, 19:57:40–20:01:04, `ef4a687` | 600 XP, completion retry không thưởng thêm, offline lưu/gửi lại, history, logout, native restore, owner/Admin RPC denial PASS | FAIL ở read tìm account Admin; không tính là lượt xanh toàn bộ |
| Admin tập trung, 20:03:25–20:04:44, `9c17c2d` | Khóa/mở fixture, broadcast DB trên observer riêng, create/edit/archive topic, learner UI denial PASS | **PASS, exit 0, 79,24 giây gồm build/cài; native test 44 giây** |

Không đếm lại activity trong hai lượt tập trung (counter = 0). Lượt Admin cuối không cần sử dụng nhánh retry read; các assertion mutation và Realtime đều chạy thành công. Kết quả 600 XP được query độc lập trước cleanup, không chỉ dựa vào text UI.

APK thường được build lại bằng `config/app.mobile.json`, không truyền config E2E; đã quét nội dung giải nén, **0 dấu vết email/password/run marker của fixture được kiểm tra**, cài `adb install -r` và mở `.MainActivity`. Process app đang foreground trên emulator, không có AndroidRuntime/Flutter error trong log kiểm tra khởi động. Wi-Fi/data về `1`, RECORD_AUDIO về `granted=false`. Hai file credential tạm `app.e2e.json` và `fixture.json` đã xóa đúng đường dẫn trong build.

- APK local: [app-debug.apk](<D:/Brilliant Clone/brilliant_mobile/repo-history/build/app/outputs/flutter-apk/app-debug.apk>), 233.348.749 bytes.
- SHA-256: `ae53a71ea769a8ceabb34d3ffd4d7a92c9ed768d0a4454ebc3a27a8f03237136`.
- [Audit APK](<D:/Brilliant Clone/brilliant_mobile/repo-history/final docs/evidence/normal-apk-audit.json>), [audit backend/cleanup](<D:/Brilliant Clone/brilliant_mobile/repo-history/final docs/evidence/backend-checks.json>).
- [Kết quả traversal](<D:/Brilliant Clone/brilliant_mobile/repo-history/final docs/evidence/ui-traversal-result.json>), [kết quả học/tài khoản](<D:/Brilliant Clone/brilliant_mobile/repo-history/final docs/evidence/account-validation-result.json>), [kết quả Admin](<D:/Brilliant Clone/brilliant_mobile/repo-history/final docs/evidence/admin-validation-result.json>).
- [Log Flutter 242 tests](<D:/Brilliant Clone/brilliant_mobile/repo-history/final docs/evidence/flutter-tests.txt>), [log Edge 22 tests](<D:/Brilliant Clone/brilliant_mobile/repo-history/final docs/evidence/edge-tests.txt>), [parity](<D:/Brilliant Clone/brilliant_mobile/repo-history/final docs/evidence/evaluator-parity.txt>), [ảnh emulator](<D:/Brilliant Clone/brilliant_mobile/repo-history/final docs/evidence/emulator-learning.png>).

Các log `.txt`/kết quả `.json` trong thư mục evidence được sao chép từ lượt thực thi, lọc credential và chuẩn hóa trailing whitespace/xuống dòng; raw logs cục bộ trong build được giữ nguyên. APK và config riêng không được commit. `git diff --check` và staged diff check cuối PASS; JSON, liên kết file và code fences của tài liệu đã kiểm tra. Tài liệu được đưa lên cùng nhánh rồi merge/push main; Git history lưu chính xác commit bàn giao.
