# Báo cáo kiểm thử tự động toàn dự án Matlingo

Ngày chạy: **31/10/2026**, 08:06:33–08:20:38 (UTC+7), khoảng **14 phút 04 giây**,
bao gồm lượt emulator đầu bị gián đoạn và chạy lại. Đây là kết quả thực thi mới
trên máy hiện tại, không lấy kết quả CI cũ làm kết quả của lần chạy này.

## 1. Kết luận

**Các bộ test chức năng đã thực thi đều đạt ở lượt hoàn tất; toàn bộ quy trình
trên checkout Windows chưa xanh hoàn toàn vì một lỗi kiểm tra hash evaluator.**

- **202/202 Flutter unit/widget tests PASS**, không có test thất bại trong bộ này.
- **18/18 Deno backend handler tests PASS**; Deno check/lint PASS.
- **1/1 Android integration scenario PASS sau cold boot**: onboarding, trả lời sai
  rồi sửa, hoàn thành Logic, mở lại dữ liệu local, ôn lại và cách ly hồ sơ.
- **2/2 SQL smoke suites PASS** trên backend thật; fixture được rollback.
- **7/7 HTTP smoke checks PASS**, gồm một request Gemini có phiên đăng nhập thật.
- **20.093 standalone assertions PASS**: 50 tương tác, 2.491 chiều sâu bài học,
  17.552 hình học.
- **729 evaluator parity cases PASS trên bản LF trong commit**. Lệnh parity trực
  tiếp trên checkout Windows **FAIL** ở kiểm tra SHA-256 do chuyển LF thành CRLF.
- Build Android debug kiểu CI, Android debug có cloud và Web đều **PASS**.

Không kết luận mọi ca thủ công, mọi nền tảng hoặc mọi dịch vụ ngoài đều đã đạt.
Các phần chưa chạy được liệt kê ở mục 7.

## 2. Môi trường và phạm vi

| Thành phần | Giá trị |
|---|---|
| Repository | `D:\Brilliant Clone\brilliant_mobile\repo-history` |
| Branch / commit | `main` / `d79e174e0a29acb494a640bf0454a0a1ae0555f2` |
| Phiên bản khai báo | Matlingo `1.3.2+6` |
| Hệ điều hành | Windows 10.0.26200 |
| Flutter / Dart | Flutter 3.47.4 / Dart 3.13.3 |
| Node / Deno | Node 24.14.0 / Deno 2.9.6 |
| Emulator | Pixel 9, Android 15 / API 35, `emulator-5554` |
| Supabase | Project `seoswmcldwwytdrfrrrb` |
| Trạng thái Git ban đầu | Không có sửa đổi tracked; có ba thư mục untracked tồn tại từ trước |
| Thay đổi source trong lần test | Không sửa source, migration, dependency hoặc cấu hình Git |

Phạm vi lấy từ pipeline và quy trình validation của repo, mở rộng thêm coverage,
integration Android local, SQL/RLS, HTTP thật và build Web. Thư mục công cụ/skill
untracked không thuộc source ứng dụng được kiểm thử.

## 3. Kết quả từng bước

Log gốc tại **`D:\Brilliant Clone\brilliant_mobile\repo-history\build\full-test-20261031`**.
Thời gian dưới đây là thời gian tiến trình, gồm startup/build nếu lệnh có thực hiện.

| Kiểm tra | Kết quả | Thời gian | Bằng chứng trong thư mục log |
|---|---|---:|---|
| `flutter pub get` | PASS, dependency hiện có resolve được | 9,10s | `pub-get.log` |
| `flutter analyze` | PASS, No issues found | 58,89s | `analyze.log` |
| `flutter test --no-pub --coverage --reporter expanded` | PASS, 202 tests | 50,40s | `flutter-tests.log`, `lcov.info` |
| Deno check hai entrypoint | PASS | 7,74s | `deno-check.log` |
| Deno lint hai API, shared HTTP và handler tests | PASS | 4,12s | `deno-lint.log` |
| Deno test hai handler suites | PASS, 18 tests | 3,40s | `deno-tests.log` |
| `check_diverse.dart` | PASS, 50 assertions | 2,97s | `interaction.log` |
| `check_depth.dart` | PASS, 2.491 assertions | 3,12s | `depth.log` |
| `check_space.dart` | PASS, 17.552 assertions | 3,26s | `geometry.log` |
| Parity từ checkout Windows, corpus mới xuất từ tests | FAIL, kiểm tra hash | 0,25s | `parity-fresh-worktree.log` |
| Parity từ bản LF nguyên gốc của cùng commit | PASS, 729 cases / 53 activities | 0,09s | `parity-committed-lf.log`, `parity-diagnosis.json` |
| Android integration lượt đầu | Không hoàn tất, exit 79; sau đó restart theo yêu cầu | 299,21s | `android-integration.log` |
| Android integration chạy lại sau cold boot | PASS, 1 scenario | 155,28s | `android-integration-coldboot.log` |
| Android debug theo CI, `--no-pub` | PASS | 23,44s | `apk-ci.log` |
| Android debug có `config/app.mobile.json` | PASS | 18,95s | `apk-cloud.log` |
| `flutter build web` | PASS; Wasm dry run cũng thành công | 46,66s | `web-build.log` |
| `git diff --check` | PASS sau khi dọn ảnh do tests sinh lại | — | Kiểm tra cuối trên working tree |

Các lệnh Flutter/Gradle được chạy tuần tự; backend độc lập chạy song song với
unit/widget suite. Lệnh parity được chạy lại sau khi Flutter tests xuất corpus mới,
để tránh dùng kết quả dựa vào corpus cũ.

### SQL/RLS trên backend thật

| Suite | Các hành vi được kiểm tra | Kết quả |
|---|---|---|
| `mobile_backup_smoke.sql` | Retry idempotent, tăng revision, chặn stale write, ownership, payload sai, cấm client ghi trực tiếp, RLS giữa tài khoản, suspended/anon | PASS |
| `learning_api_smoke.sql` | Quyền admin/user, request hash, version/asset publish, owner isolation, evaluator authority, hoàn thành/30 XP và chống thưởng trùng, cursor, tombstone, suspended/anon | PASS |

Hai script chạy trong `BEGIN … ROLLBACK`, dùng identities/key ngẫu nhiên riêng.
Kiểm tra trước và sau đều có **0 smoke fixture users, 0 smoke topics**. Không chạy
schema reset, db push hoặc migration replay. Bằng chứng:
`mobile_backup_smoke.json`, `learning_api_smoke.json`, `sql-fixture-check.json`.

### HTTP trên deployment thật

| Request | Mong đợi / thực tế |
|---|---|
| `learning-api` OPTIONS | 204 / 204 |
| `learning-api` POST thiếu JWT | 401 / 401 |
| `learning-api` POST JWT không hợp lệ | 401 / 401 |
| `tutor-chat` OPTIONS | 204 / 204 |
| `tutor-chat` POST thiếu JWT | 401 / 401 |
| `tutor-chat` POST JWT không hợp lệ | 401 / 401 |
| `tutor-chat` với phiên đăng nhập sẵn có trên emulator | 200, có câu trả lời không rỗng; 18,18s trong một lần đo |

Chỉ dùng một câu hỏi toán mẫu, không gửi lịch sử cá nhân. Không ghi API key/JWT
hoặc nội dung preferences vào report/log. Một request thành công không phải kiểm
thử tải, chất lượng mọi câu trả lời hoặc bảo đảm độ trễ. Log: `live-http.json`.

## 4. Coverage và mức bao phủ chức năng

Unit/widget line coverage: **7.047 / 7.978 dòng = 88,33%**, đo trên **68 file**.
Đây là tỷ lệ trên các dòng/file được LCOV ghi nhận, không phải tuyên bố 88,33%
toàn bộ mọi dòng source hay branch coverage. Repo có 71 file Dart dưới `lib`;
`challenges.dart`, `data/engines/engine_contracts.dart`, `interactive_workspace.dart`
không có record trong lần đo này. Integration và SQL không cộng vào tỷ lệ trên.

| Nhóm | Bằng chứng tự động có trong lần chạy |
|---|---|
| Auth/onboarding | Validation, OTP/recovery wire protocol, logout, account gate và UI regressions trong Flutter suite |
| Bài học | Tests widget/domain/depth/geometry; integration Android dùng thao tác thật với Logic |
| Tiến độ | Local persistence/reopen/review/isolation; mock sync/backup; SQL authority/XP/RLS thật |
| AI/code | Adapter/registry/canvas/default tutor tests; handler auth/input/error tests; Gemini HTTP thật |
| UI/UX | Các tests màn nhỏ, text scale, navigation, preferences, profile và menu hiện có |
| Build | Hai cấu hình Android debug và Web compile |

Khoảng trống đáng chú ý trong LCOV của unit/widget suite:

| File dưới repository | Dòng hit / đo được |
|---|---:|
| `lib/data/repositories/backup_repository.dart` | 0 / 17 |
| `lib/main.dart` | 0 / 21 |
| `lib/data/repositories/learning_repository.dart` | 1 / 56 |
| `lib/features/account/learning_sync_scope.dart` | 5 / 46 |

Các khoảng trống này không tự chứng minh có bug. Chúng cho thấy cần thêm kiểm
thử HTTP/session refresh, wiring và kết nối thật; mocks của controller không thay
thế hoàn toàn repository integration. Chi tiết: `coverage-summary.json`.

## 5. Vấn đề phát hiện và chạy lại

### ENV-01 — Parity hash không ổn định trên checkout Windows

**Trạng thái: tái hiện được, chưa sửa. Mức ảnh hưởng: quy trình validation/deploy.**

File:
[evaluator.js](</D:/Brilliant Clone/brilliant_mobile/repo-history/supabase/functions/learning-api/evaluator.js>)
và kiểm tra tại
[evaluator_parity.mjs](</D:/Brilliant Clone/brilliant_mobile/repo-history/supabase/tests/evaluator_parity.mjs:13>).

- `core.autocrlf=true`; Git index chứa LF nhưng working tree chứa **3.256 CRLF**.
- SHA-256 working tree: `e0e79017a87866278b4bf2596924f7f33083717ee3e9fb790e12abe11811e8ff`.
- SHA-256 bản commit LF: `c9b96186271a5eff2cfc099c40ec450bf4846d3e58f49d3f4dd485a7baa21afc`.
- Bản commit LF khớp `implementationHash` trong `version.ts`.
- Chuẩn hóa CRLF → LF cho bytes working tree cho kết quả bằng đúng bytes commit.
- Chạy nguyên script parity trên bản sao LF của **cùng commit**, với corpus mới,
  đạt 729 cases. Không sửa working tree để che kết quả FAIL ban đầu.

Đề xuất cho một thay đổi riêng: pin `eol=lf` cho generated evaluator bằng
`.gitattributes`, rồi xác minh checkout mới trên Windows và Linux. Không đổi
`implementationHash` sang hash CRLF chỉ để làm local test xanh. Trong khi chưa
pin line endings, cần kiểm tra bytes/hash trước khi deploy evaluator từ Windows.

### RUN-01 — Integration lượt đầu không hoàn tất; cold boot chạy lại đạt

Lượt đầu dừng tiến triển quanh Logic bước 4/6 và có nhiều dòng chẩn đoán hit-test.
Flutter báo `did not complete`, exit 79; cleanup có `PathNotFoundException` với
test listener trong thư mục tạm. Người dùng báo emulator lag và yêu cầu chạy lại.

Đã dừng runner, restart emulator không wipe data, chờ `sys.boot_completed=1`,
rồi chạy lại cùng integration với giới hạn `--timeout 5m`. Lượt mới hoàn tất
toàn bộ scenario và đạt PASS. Chưa đủ bằng chứng kết luận nguyên nhân gốc của
lượt đầu là app, test harness, thao tác ngoài test hay emulator. Không tính lượt
đầu là một lỗi chức năng đã xác nhận, cũng không xóa log của lượt đó.

## 6. Artifact và trạng thái emulator

- Android cloud debug APK:
  `D:\Brilliant Clone\brilliant_mobile\repo-history\build\app\outputs\flutter-apk\app-debug.apk`.
- Kích thước: **208.192.076 bytes**; đây là debug artifact, không phải số đo release.
- SHA-256: `9a6762d61f3c83374e841e97c4460d845e7ae849cc83d63775692c2aa3dcbb1e`.
- ADB `install -r` trả `Success`; lệnh mở `.MainActivity` thành công sau tests.
- Web output: `D:\Brilliant Clone\brilliant_mobile\repo-history\build\web`.
- Người dùng dừng Computer Use bằng Esc ở bước quan sát cuối; không tiếp tục điều
  khiển UI sau tín hiệu đó. Không có bước gửi chat bằng UI được xác nhận trong lần này.

Các JSON `results-flutter.json`, `results-backend.json`, `results-android.json`,
`results-android-retry.json` ghi lệnh, thời điểm UTC, thời gian và exit code.
`parity-diagnosis.json` phân biệt kết quả checkout và bản LF trong commit.

## 7. Chưa chạy / giới hạn

| Hạng mục | Trạng thái và lý do |
|---|---|
| `phone_readiness_test.dart` với Auth/learning/backup HTTP end-to-end | BLOCKED: không có `config/app.e2e.json`/fixture credentials riêng. Không dùng tài khoản cá nhân để thay fixture |
| iOS build/runtime | Chưa chạy: môi trường Windows không có macOS/Xcode |
| Android release/store signing | Chưa chạy: không có `android/key.properties`/keystore production; chỉ build debug |
| Web browser runtime/E2E | Chưa chạy: lần này chỉ kiểm tra compile Web |
| Email đăng ký/recovery thật | Chưa xác minh mailbox, mã email và SMTP thực tế trong lượt này |
| Docker/Judge0/Pyodide thật | Chưa có server/bridge cấu hình cho test live; adapter tests dùng mock |
| TalkBack, native keyboard, thiết bị vật lý | Chưa có QA thủ công trong lần chạy |
| Tải đồng thời/quota/cost Gemini | Không kiểm thử tải; limiter hiện tại chỉ trong từng isolate |
| Migration replay | Không chạy; không có thay đổi schema và lịch sử migration cần đối chiếu riêng |

Không gọi mọi chức năng ở bảng trên là PASS chỉ vì unit tests hoặc build thành công.

## 8. Kiểm tra Git và bàn giao

12 ảnh tracked được widget tests sinh lại đã được lưu vào
`build/full-test-20261031/generated-doc-images` và trả về bytes ban đầu trong Git.
Ba thư mục untracked tồn tại trước (`docs/demo-2026-11-01`, `output`,
`ui-ux-pro-max-skill-main`) được giữ nguyên. Chỉ tạo report này và log/artifact test;
không commit/push, không sửa source để xử lý lỗi tìm thấy trong lượt kiểm thử.

Ưu tiên tiếp theo: sửa pin LF cho evaluator trong một thay đổi riêng; bổ sung
fixture E2E cloud và repository HTTP tests; tiếp tục checklist thủ công của team.
