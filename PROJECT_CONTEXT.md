# Matlingo — Context phát triển và bàn giao

> Cập nhật: **27/10/2026**, múi giờ Asia/Bangkok.
> Đây là snapshot bàn giao, không phải trạng thái live được bảo đảm mãi mãi.
> Đọc `AGENTS.md` trước khi sửa dự án; sau đó đối chiếu tài liệu này với code,
> `git status` và các kiểm tra hiện tại. Không ghi secrets hay OTP thật vào đây.

## 1. Mục tiêu và yêu cầu của người dùng

- Tiếp tục phát triển **trên codebase Flutter hiện tại**, tích hợp thêm từng phần.
  Giữ luồng học, dữ liệu và các thay đổi có sẵn; không dựng lại app hoặc chuyển
  sang React Native chỉ vì specification có nhắc đến nhiều framework.
- Giữ giao diện theo bằng chứng **REA** đã thu thập: font, màu, header, spacing,
  CTA, tương tác và hỗ trợ chữ lớn. Tái sử dụng theme/component hiện có.
- Bản mobile có cấu hình cloud phải đăng nhập trước khi học; hồ sơ đang mở tự
  lưu lên Supabase, không cần thao tác liên kết/lưu cloud lần đầu.
- Xây nền tảng học cá nhân hóa: Koji AI tutor, canvas, coding, assessment,
  progress và bốn domain Math / CS & AI / General Science / Data Analysis.
- Engine Registry là yêu cầu quan trọng: nhớ nhiều kết nối AI/code, lưu khóa
  bảo mật, đổi engine ngay khi app đang chạy và tách theo tài khoản.
- Thông báo phải thân thiện và đúng bằng chứng: phân biệt thành công, lỗi và
  đang xử lý; không gán mọi lỗi cho mạng hoặc mật khẩu, không lộ diagnostic.

## 2. Workspace, Git và stack

| Mục | Snapshot hiện tại |
|---|---|
| Workspace | `D:\Brilliant Clone\brilliant_mobile\repo-history` |
| Branch | `refactor/matlingo-mobile-supabase` |
| HEAD lúc bàn giao | `253668e` — Scroll lazy lesson controls into view before widget test taps |
| Trạng thái Git | Nhiều thay đổi tracked và file mới **chưa commit**; không coi HEAD là toàn bộ bản mới |
| App | Matlingo; package Dart `brilliant_mobile` |
| Phiên bản pubspec | `1.3.1+5` |
| SDK đã dùng để kiểm tra | Flutter `3.47.4`, Dart `3.13.3` |
| Dependency chính | `shared_preferences`, `supabase_flutter: 2.18.3`, `flutter_secure_storage: 11.2.0`, `http: 1.6.0` |
| Android package | `com.learningstudio.brilliant_mobile` |
| Emulator đã dùng | `Pixel_9`, thường là `emulator-5554`, Android 15 / API 35 |

Không tự `git reset`, `git clean`, checkout đè file, xóa file untracked hoặc
hoàn tác thay đổi hiện có để “làm sạch” dự án. Không commit/push/deploy nếu chưa
có yêu cầu phù hợp. Kiểm tra Git lại ở đầu phiên phát triển tiếp theo.

## 3. Trạng thái sản phẩm đang hoạt động

### Luồng học

- Tạo/chọn hồ sơ, onboarding sở thích và số phút học mỗi ngày.
- Home / Chủ đề / Hồ sơ; tiếp tục bài đang làm, hoàn thành và xem lịch sử.
- Catalog hiện tại: **11 chủ đề, 53 hoạt động, 30 cơ chế tương tác**.
- Bài học là thao tác trực tiếp với mô hình: phân số, logic, lập trình robot,
  mạch điện, xác suất, đại số, dữ liệu, hình học/khối 3D, địa cầu và lớp trầm tích.
- Canvas/gesture/animation và engine 3D nhỏ viết bằng Flutter/Dart; không cần
  WebView cho các thí nghiệm đang có. Chưa đo FPS trên điện thoại thật.
- Tiến độ, bản nháp, hoàn thành và hoạt động theo ngày được lưu riêng theo hồ sơ.
  Bản configured 1.3.1 thêm journal ghi cùng snapshot để gửi profile/session/draft/
  attempt/completion lên API canonical. UI phân biệt XP học cá nhân và XP server đã xác nhận.
  Request ID và pending draft payload được giữ nguyên qua retry, kể cả mất response.

### Đăng nhập và xác nhận email

1. Build có `SUPABASE_URL` và `SUPABASE_PUBLISHABLE_KEY` mở luồng Auth bắt buộc.
2. Đăng nhập bằng email/mật khẩu hoặc tạo tài khoản.
3. Khi chưa có session sau đăng ký, app chuyển sang ô **Mã xác nhận**.
4. Nhập mã nhận trong email → **Xác nhận & tiếp tục**. Có session hợp lệ mới
   được đăng nhập và bắt đầu tự lưu hồ sơ đang mở.
5. Có **Gửi lại mã**, cooldown cục bộ 60 giây; rate limit và expiry của server
   vẫn quyết định. API chấp nhận resend không bảo đảm thư đã đến hộp thư.
6. Nếu đã đóng app: nhập email trên màn đăng nhập, chọn
   **Đã có mã xác nhận? Nhập mã** để tiếp tục mà không phải đăng ký lại.

Field hỗ trợ mã **6–10 chữ số**, dán/autofill và giữ số 0 ở đầu.
Verify dùng `OtpType.email`; resend dùng `OtpType.signup`.
Mã sai/hết hạn cho phép thử lại; mã đang nhập không bị xóa nếu resend thất bại.
OTP và mật khẩu không được thêm vào LearningStore hoặc bản sao lưu cloud.

Đăng ký lặp một email đã xác nhận có thể trả response bị che giấu từ Supabase.
Không được suy ra “đã tạo tài khoản mới” hay “đã gửi email” chỉ từ HTTP 200 hoặc
session null. Đăng ký lại cũng không đổi mật khẩu của tài khoản cũ.

Khi đăng xuất cloud, app đóng hồ sơ đang mở và bỏ các route cũ. Hồ sơ đã gắn
tài khoản khác không được hiển thị/chuyển sang upload cho tài khoản mới.
Build thiếu dart defines vẫn có chế độ offline phục vụ phát triển/CI;
không nhầm build đó với bản mobile cloud bắt buộc đăng nhập.

### Sao lưu cloud

- Chỉ hồ sơ đang mở được gắn tài khoản và tự lưu; không upload toàn bộ hồ sơ
  của một thiết bị dùng chung.
- Gửi thay đổi sau khoảng **2 giây**; lỗi giữ dữ liệu local và thử lại khoảng
  **30 giây** khi app còn chạy. Không có background sync khi process đã dừng.
- Bảng `public.mobile_profile_backups`, RPC `save_mobile_backup`.
- Payload snapshot **version 3**: `profile` và `learning`, kèm revision phía server.
- Revision cũ bị từ chối; không tự ghi đè bản mới từ máy khác.
- Khôi phục tạo hồ sơ riêng trên máy, giữ hồ sơ/bài chưa gửi trước đó.
- Đây là **personal snapshot backup**, chưa phải incremental sync, merge nhiều
  máy hoặc canonical learning session mutation.
- Canonical writes nay chạy riêng qua LearningSyncController; không lấy backup để
  cấp XP. Restore fork các session/draft/attempt chưa xác nhận thành nhánh mới.
  Profile UUID ổn định theo account/source backup key, không theo tên hồ sơ.
- Binding revision 0 chỉ là đang chờ lưu; có receipt revision >0 mới được nói
  đã có bản cloud. Lưu trên thiết bị và lưu cloud được thông báo riêng.
- Nếu ghi local thất bại, thay đổi mới có thể chỉ còn trong bộ nhớ. Hướng dẫn
  giữ app mở và thử lưu lại; không hứa mọi thay đổi đã được ghi bền vững.

## 4. Bản đồ code cần đọc

Các đường dẫn trong bảng tính từ workspace ở mục 2.

| File / thư mục | Trách nhiệm |
|---|---|
| `lib/main.dart` | Bootstrap SharedPreferences, Supabase khi có defines, CloudScope và EngineHost |
| `lib/journey_app.dart` | LearnApp, auth gate, HomeShell, lesson runner, hoàn thành, profile |
| `lib/entry_flow.dart` | Chọn/tạo hồ sơ và onboarding hiện có |
| `lib/learning_store.dart` | Local-first state, snapshot, draft, hoàn thành, export/restore hồ sơ |
| `lib/learning_catalog.dart`, `lib/experiments/` | Catalog, mô hình, evaluator/validator và workspace tương tác |
| `lib/learning_guidance.dart` | Recommendation hiện có dựa trên lịch sử học local |
| `lib/app_theme.dart`, `lib/app_layout.dart`, `lib/app_motion.dart` | Theme, khung chung và chuyển động đang được frontend sử dụng |
| `lib/app_preferences.dart` | Tùy chỉnh giao diện và lưu lựa chọn trên thiết bị |
| `lib/settings_menu.dart`, `lib/home_chat_box.dart` | Menu và chat hiện có đã được tích hợp thêm |
| `lib/data/repositories/auth_repository.dart` | Sign-in/up/out, verify code, resend; không gọi Auth trực tiếp từ widget |
| `lib/data/repositories/backup_repository.dart` | Query/RPC sao lưu Supabase |
| `lib/data/providers/cloud_backup_controller.dart` | Auth state, OTP pending, cooldown, ownership, auto-save/retry và restore |
| `lib/data/models/learning_journal.dart` | Outbox trong snapshot local, UUID, fork nhánh restore |
| `lib/data/providers/learning_sync_controller.dart` | Gửi request bền vững, kiểm tra owner, profile conflict, cache XP verified |
| `lib/data/repositories/learning_repository.dart` | HTTP có timeout/response cap, JWT gắn owner, refresh một lần, lỗi an toàn |
| `lib/features/account/learning_sync_scope.dart` | Trạng thái đồng bộ, XP đã xác nhận và lựa chọn metadata khi conflict |
| `lib/features/account/cloud_account_page.dart` | Login/register, ô OTP, quản lý backup |
| `lib/data/models/app_failure.dart` | Lỗi an toàn cho UI, phân loại lý do, NoticeKind |
| `lib/features/shared/app_notice.dart` | Thông báo có icon, live region, màu/theme chung |
| `lib/data/models/engine_config.dart` | Metadata engine không chứa credential |
| `lib/data/repositories/engine_registry.dart` | CRUD cấu hình, persistence và chọn AI/code độc lập |
| `lib/data/repositories/engine_storage.dart` | Secure storage theo tài khoản |
| `lib/data/repositories/engine_runtime.dart` | Resolve engine lúc request, factories, timeout/dispose và hot-swap |
| `lib/data/engines/` | Interface engine, HTTP transport và adapter AI/code |
| `lib/features/engines/` | Scope/lifecycle theo tài khoản và UI cấu hình engine |
| `lib/features/tutor/shared_canvas.dart` | Nét vẽ chuẩn hóa, overlay/bounding box, hoàn tác và xóa |
| `lib/features/coding/` | Editor Python/JS có highlight cơ bản và playground chạy mã |
| `lib/data/models/learning_modules.dart` | Interface/model tutor, voice, coding, roadmap, mastery, quiz, notification |
| `lib/data/repositories/catalog_roadmaps.dart` | Tái dùng topic ID hiện có cho bốn domain |
| `lib/features/assessment/mastery_widgets.dart` | Quiz/dashboard tái sử dụng, chưa nối repository đánh giá thật |

`lib/features/` mới giữ UI/bắt sự kiện; truy vấn và persistence nằm ở data layer.
Một số UI cũ vẫn ở root `lib/`; không di chuyển/refactor hàng loạt chỉ để đồng
nhất thư mục. Không xóa các file cầu nối/re-export.

`AGENTS.md` có nhắc hệ theme/role/commerce của lịch sử dự án. Đối với frontend
đang chạy, kiểm tra thực tế các import ở `app_theme.dart`, `app_layout.dart` và
tài liệu role hiện hành; không tự tạo một theme hoặc app song song.

## 5. Engine Registry: quyết định thiết kế cần giữ

- Menu **Engine học tập** cho thêm/sửa/xóa và chọn kết nối; chat cũ sử dụng
  `ChatResponder` qua EngineScope. Responder được truyền riêng vẫn được ưu tiên.
- Chọn AI và code engine độc lập. Metadata công khai không chứa khóa.
- Config, credential và active selection cùng một snapshot trong secure storage;
  mutation được xếp hàng và chỉ báo state mới sau khi ghi thành công.
- Namespace `matlingo.engines.v1.<accountId>`; bản offline dùng namespace
  `device`. Không tự chuyển khóa offline sang tài khoản cloud.
- Đổi engine áp dụng cho request kế tiếp. Request đang chạy giữ selection cũ;
  đổi tài khoản/dispose thì đóng client và không dùng kết quả muộn ở phiên mới.
- Endpoint là URL đầy đủ. Chấp nhận HTTPS, chặn credentials trong URL/query/
  fragment và không theo redirect mang khóa. Ollama cho loopback HTTP nhưng
  Android cleartext/ATS vẫn áp dụng; không mở cleartext toàn app.
- Đổi endpoint/provider có credential cần nhập lại hoặc chủ động xóa khóa cũ.
- HTTP response tối đa 1 MiB; canvas gửi AI có giới hạn kích thước; timeout mặc
  định 60 giây, cấu hình trong khoảng 1–180 giây.
- Không hardcode provider key dùng chung. Bản phân phối nên dùng gateway và giữ
  provider secret phía server; API adapter có thể dùng token/khóa do người dùng nhập.

| Engine | Mức tích hợp |
|---|---|
| OpenAI | Adapter Responses-compatible, `store:false`; model do người dùng cấu hình |
| Anthropic Claude | Adapter Messages |
| Ollama | Adapter `/api/chat`, không stream |
| Koji tùy chỉnh | Gateway theo contract trong ENGINE_ARCHITECTURE |
| Remote Docker | Client gateway chạy mã; chưa triển khai server sandbox |
| Judge0 | Base64 submission, polling, stdout/stderr/errors; language ID theo server |
| Pyodide | Có interface/điểm gắn bridge; chưa có WebView/worker thực thi tích hợp |

Client chỉ yêu cầu giới hạn CPU/RAM/network. Server sandbox phải thi hành giới
hạn và cô lập thật; không coi payload `limits` là bằng chứng sandbox an toàn.
Timeout client không bảo đảm remote job đã bị hủy.

## 6. Dữ liệu local, secrets và Supabase

| Nơi lưu | Nội dung |
|---|---|
| SharedPreferences `nary:journey:v3` | Hồ sơ và learning state local; giữ key lịch sử để tương thích |
| SharedPreferences `matlingo:cloud-links:v1` | Owner, remote profile key, revision, timestamp liên kết |
| SharedPreferences qua AppPreferences | Appearance, text size, reduce motion |
| FlutterSecureStorage | Cấu hình engine, credential và active selections theo tài khoản |
| Supabase Auth | Tài khoản, xác nhận email, session |
| `mobile_profile_backups` | Snapshot hồ sơ/learning thuộc owner đã xác thực |
| Bộ nhớ màn hình | Chat/canvas và draft coding playground; chưa được lưu/sync tự động |

Project Supabase hiện được cấu hình: **`seoswmcldwwytdrfrrrb`**, Singapore.
Theo kiểm tra rollout server 26/10/2026: 22 application tables trên public/private,
cộng `mobile_profile_backups`; 11 topics, 53 activities/versions đã published,
30 evaluator active và hai bucket private learning-assets/user-avatars.
Phải kiểm tra live lại nếu công việc cần số liệu hiện tại.

Role hiện hành là **user cho mobile** và **admin cho web dashboard**. Kế hoạch
parent/kid/commerce cũ được lưu trong legacy; không tự phục hồi vào frontend mới.
Đăng ký mới được provision role `user`; không tự cấp admin cho tài khoản đầu tiên.

### Lịch sử xóa tài khoản — không tự lặp lại

Ngày 26/10/2026, người dùng **đã yêu cầu riêng** xóa toàn bộ tài khoản để đăng ký
lại. Đã xóa 12 Auth users, gồm admin, và 35 Auth sessions; accounts/identities/
roles/sync heads/refresh tokens liên quan đã sạch. Query độc lập khi đó xác nhận
0 users/accounts/sessions/roles, catalog 11 topics/53 activities vẫn giữ nguyên.

Đây là lịch sử thao tác, **không phải số lượng tài khoản live ở lần đọc sau**.
Người dùng có thể đã đăng ký lại. Không xóa người dùng, tắt Confirm email hoặc
sửa `auth.users` để chữa một lỗi đăng nhập/SMTP khi chưa có yêu cầu mới phù hợp.

### Backend học đã triển khai và phần tích hợp còn chờ

- `learning-api` đã deploy: canonical profile/session/draft, server attempt evaluator,
  completion/XP nguyên tử, incremental sync, progress, admin content/account và ảnh private.
- Catalog baseline đã published; JS evaluator biên dịch từ Dart đã được đối chiếu
  729 ca trên đủ 53 hoạt động. Chi tiết contract: `docs/LEARNING_SERVER_API.md`.
- Mobile 1.3.1 đã nối canonical writes/outbox. Vẫn dùng catalog đóng gói và backup;
  chưa có automatic incremental pull/merge giữa hai thiết bị.
- Backup không ghi `xp_ledger`, verified completion hoặc tự cấp thưởng server.
- Admin dashboard UI, native/compiler infrastructure và automatic incremental merge còn chờ.
- Các endpoint AI/commerce/VNPay legacy đã được retire; không dùng chúng làm
  backend Koji/commerce đang hoạt động hoặc tự triển khai lại.
- CLI đã đăng nhập bằng luồng xác thực chính thức ngày 26/10/2026. Đã xóa đủ
  12 Edge deployments legacy theo yêu cầu người dùng; kiểm tra list chỉ còn
  `learning-api` ACTIVE v4 sau sửa lỗi HTTP conflict. Giữ source `_retired` làm lịch sử, không redeploy.
- Không dùng SQLSTATE 40001 cho business conflict public RPC: PostgREST đang retry
  vòng lặp. Migration `20261104000000_friendly_revision_conflicts.sql` chuyển các
  conflict profile/draft/backup sang PT409 ở entrypoint; RLS/CAS giữ nguyên.
  Đã xác nhận HTTP 409 thực tế cho canonical/backup, không còn request mắc vòng lặp.

Không chạy lại `supabase/schema_reset.sql`. Không blanket `supabase db push/reset`:
lịch sử migration local và remote chưa được reconcile đầy đủ. Migration cũ giữ
nguyên; thay đổi schema/RPC/RLS mới phải forward-only, idempotent, có kiểm tra quyền.
Không commit service-role key, SMTP password, Management token, JWT hoặc OTP thật.

## 7. SMTP và email template

- App đã có ô nhập code; không yêu cầu người dùng gửi OTP/mật khẩu vào chat.
- Mẫu email REA: `supabase/templates/confirmation.html`, dùng `{{ .Token }}` và
  `{{ .Email }}`, không chứa OTP cố định hay link tự tiêu thụ token.
- Subject dự kiến: **Mã xác nhận tài khoản Matlingo**.
- **Đã áp dụng và đọc lại xác minh mẫu HTML, subject và sender name Matlingo**
  bằng Management API của phiên CLI do user đăng nhập. Chỉ sửa ba field này;
  SMTP credentials, Confirm email và độ dài OTP 8 chữ số giữ nguyên.
- Đường áp dụng: Authentication → Emails / Email Templates → Confirm signup.
  Hướng dẫn cụ thể ở `supabase/templates/README.md`. Giữ nguyên SMTP credentials.
- Người dùng đã báo nhận được code, nhưng việc nhận thư thật và verify code thật
  chưa được agent xác nhận end-to-end bằng mailbox/thiết bị của người dùng.
- Template chỉ đổi nội dung/giao diện email, không tự sửa SMTP delivery/rate limits.

## 8. Thông báo người dùng

- `friendlyError` phân loại theo type/code; raw server message không được đưa vào UI.
- OTP sai/hết hạn, OTP bị tắt, timeout và rate limit là các lý do riêng.
- Thiếu quyền không được tự gọi là tài khoản bị khóa; 5xx không được gọi là sai mật khẩu.
- Lỗi không xác định dùng thông báo trung tính, không đoán nguyên nhân.
- Lưu local không được nói đã lưu cloud; binding chưa có receipt không được nói
  đã có bản sao lưu. Resend thành công chỉ xác nhận yêu cầu được xử lý.
- Chat giữ draft khi lỗi; code runner hiển thị trạng thái theo kết quả thật,
  exit code và tên engine đã chạy. Không có exit code thì không tự nói đã chạy thành công.
- `AppNotice` có icon, chữ, semantics/live region và hỗ trợ text scale lớn.

Xem bảng kiểm đầy đủ trong `docs/USER_MESSAGES_AUDIT.md` trước khi thêm thông báo mới.

## 9. Kiểm thử và build đã xác minh

Kiểm tra tiếp nối ngày 27/10/2026 trên workspace hiện tại: analyze không có issues,
toàn bộ **175 Flutter tests** qua; các kiểm tra standalone đạt 50 / 2.491 / 17.552,
và evaluator parity đạt 729 ca trên 53 hoạt động. Log: `build/continuation-tests.log`.
Build `flutter build apk --debug` thành công, không truyền cloud dart defines;
output `build/app/outputs/flutter-apk/app-debug.apk` là bản kiểm tra offline.
Lượt này chưa kiểm tra lại backend live, hộp thư thật, điện thoại vật lý hay APK
release đã phân phối; các kết quả bên dưới là bằng chứng lịch sử ngày 26/10.

Kết quả gần nhất sau rollout API server ngày 26/10/2026:

| Kiểm tra | Kết quả |
|---|---|
| `flutter analyze --no-pub` | Không có issues |
| `flutter test --no-pub --reporter expanded` | **147 tests passed**; xem VALIDATION.md cho lượt mới nhất |
| Deno check / lint / handler tests | Đạt, 12 tests |
| Android integration với Supabase thật | Auth UI, học, XP, retry, metadata conflict, local reopen, backup restore, logout đạt |
| Server/mobile evaluator parity | 729 ca trên đủ 53 hoạt động |
| SQL API smoke + replay idempotency | Đạt trên live DB, fixture rollback |
| HTTP thiếu/sai JWT / OPTIONS | 401 / 401 / 204 trên Edge đã deploy |
| `dart tools/check_diverse.dart` | 50 checks |
| `dart tools/check_depth.dart` | 2.491 checks |
| `dart tools/check_space.dart` | 17.552 checks |
| APK debug có cloud defines | Build mới thành công; phiên bản UI trước đã chạy trên Pixel 9 Android 15 |
| APK release 1.3.1+5 | Build, ký, cài cập nhật và cold launch thành công trên emulator; không fatal/Flutter error |
| UI OTP | Render font thật ở 320px, text scale 1.4, không overflow trong test |
| Email HTML | Đã áp dụng và xác minh hosted config; chưa test mailbox thật |

Các test trọng tâm: `cloud_backup_test.dart`, `auth_repository_test.dart`,
`app_messages_test.dart`, `engine_registry_test.dart`, `engine_widgets_test.dart`,
`chat_layout_test.dart`, các widget/gesture/resume/local-save tests hiện có.
Protocol AI/code/Auth dùng mock HTTP; không suy ra provider/sandbox thật đã hoạt động.

Chưa build iOS trên macOS/Xcode hoặc đo performance trên máy thật. Entitlement
Keychain đã cấu hình; Android tắt OS Auto Backup để không phục hồi ciphertext
engine sang máy thiếu key tương ứng. Sao lưu Supabase là luồng riêng.
Release signing hiện dùng debug identity để test; chưa là cấu hình phát hành store.
APK release cũ không được mặc định coi là chứa mọi thay đổi mới nhất.

### Lệnh phát triển trong workspace này

```powershell
Set-Location -LiteralPath 'D:\Brilliant Clone\brilliant_mobile\repo-history'
git status --short
flutter pub get
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
dart 'D:\Brilliant Clone\brilliant_mobile\repo-history\tools\check_diverse.dart'
dart 'D:\Brilliant Clone\brilliant_mobile\repo-history\tools\check_depth.dart'
dart 'D:\Brilliant Clone\brilliant_mobile\repo-history\tools\check_space.dart'
git diff --check
flutter emulators --launch Pixel_9
flutter devices
flutter run -d emulator-5554 --dart-define-from-file='D:\Brilliant Clone\brilliant_mobile\repo-history\config\app.mobile.json'
```

`emulator-5554` có thể đổi; dùng ID do `flutter devices` trả về. `config/app.mobile.json`
là cấu hình local được ignore; dùng `config/app.example.json` làm mẫu, không chép
secret vào source. Muốn build lại APK:

```powershell
flutter build apk --debug --dart-define-from-file='D:\Brilliant Clone\brilliant_mobile\repo-history\config\app.mobile.json'
flutter build apk --release --dart-define-from-file='D:\Brilliant Clone\brilliant_mobile\repo-history\config\app.mobile.json'
```

Output build: `D:\Brilliant Clone\brilliant_mobile\repo-history\build\app\outputs\flutter-apk\`.
Bản giao đã kiểm tra: `D:\Brilliant Clone\brilliant_mobile\repo-history\build\releases\Matlingo-1.3.1.apk`.
Android 7.0/API 24+, ba ABI; metadata/SHA-256 ở `build/releases/Matlingo-1.3.1.json`.
Build release sau integration test phải để pub/plugin generation hoạt động (không
thêm --no-pub), và chạy tuần tự để loại dev-only native registrant đúng cách.
Chỉ format file đã sửa. Full test có thể tạo lại PNG preview trong `docs/`;
kiểm tra diff và chỉ hoàn tác đúng artifact do chính lần test tạo, không đè ảnh có sẵn của người dùng.

## 10. Thứ tự công việc tiếp theo

1. Kiểm tra gửi/resend và verify mã trên hộp thư/điện thoại thật của người dùng;
   mẫu email đã áp dụng. Không xin mật khẩu/OTP tài khoản app trong chat.
2. Kiểm tra smoke trên mobile thật: đăng nhập → tạo hồ sơ → học → backup → mở lại
   app → restore trên thiết bị khác; không tuyên bố multi-device merge.
3. Hoàn thiện gateway Koji và remote code sandbox bằng adapter hiện có; kiểm tra
   quyền, rate limits và giới hạn sandbox phía server trước khi public.
4. Nối AssessmentRepository vào kết quả thật, sau đó mới đưa mastery/pathway vào
   recommendation đang có. Không suy ra mastery chỉ từ số bài đã hoàn thành.
5. Làm voice STT/TTS, native notifications và Pyodide bridge khi được ưu tiên;
   xin permission theo thao tác của người dùng, không bật microphone mặc định.
6. Canonical writes đã nối; triển khai incremental pull/merge nếu được ưu tiên,
   giữ backup cũ và dữ liệu local. Reconcile migration history trước schema changes;
   admin dashboard và QA iOS là các phạm vi riêng. Legacy Edge deployments đã xóa.

Đây là danh sách bàn giao, không phải ủy quyền tự động deploy, cấp quyền admin,
gửi tin nhắn/email, xóa dữ liệu hoặc thay đổi schema ngoài yêu cầu của phiên mới.

## 11. Tài liệu đọc tiếp

- `AGENTS.md`: quy tắc bắt buộc; ưu tiên yêu cầu trực tiếp của người dùng trong phạm vi an toàn.
- `VALIDATION.md`, `.github/workflows/verify.yml`: kiểm tra phù hợp trước khi kết thúc.
- `SUPABASE_INTEGRATION_STATUS.md`, `supabase/README.md`: nguồn backend và trạng thái tích hợp.
- `docs/LEARNING_SERVER_API.md`: API server đã deploy, contract, bảo mật và giới hạn tích hợp.
- `docs/PHONE_READINESS.md`: bản cài 1.3.1, kiểm thử Android, cách cài và giới hạn còn lại.
- `ROLE_COMMERCE_DEVELOPMENT_PLAN.md`, `docs/SUPABASE_SCHEMA_MIGRATION.md`: role/schema hiện hành.
- `docs/ENGINE_ARCHITECTURE.md`: interfaces, protocol, folder structure và phần chưa triển khai.
- `docs/MOBILE_CLOUD_BACKUP.md`: Auth/OTP, cấu hình APK, backup/restore và giới hạn.
- `docs/USER_MESSAGES_AUDIT.md`: nguyên tắc và bảng kiểm thông báo người dùng.
- `supabase/templates/README.md`: bước áp dụng email template còn chờ.
- `docs/STYLE_RECONSTRUCTION.md`, `docs/UNIFIED_LAYOUT.md`, `ui_ux_pro_max/SKILL.md`: UI/REA.
- `docs/MOBILE_3D.md`, `docs/LESSON_DEPTH_ITERATIONS.md`: bài học và kiểm tra nội dung.

README/tài liệu cũ có các số 8/10 chủ đề, 24/46 thí nghiệm, app chỉ offline hoặc
chat chưa kết nối. Đó là các đợt trước; không lấy làm mô tả bản hiện tại. Bằng chứng
REA là khảo sát website công khai, chưa phải chứng nhận khớp pixel toàn bộ app native.
`docs/legacy/` là lịch sử, không phải validation cho frontend đang chạy.

## 12. Cách cập nhật context sau này

Sau mỗi mốc phát triển, cập nhật ngày, thay đổi đã chạy thật, file/luồng liên quan,
kiểm tra đã thực hiện, blocker và phần còn chờ. Phân biệt rõ **đã làm**, **mock/test**,
**chưa triển khai**, **chưa kiểm tra thực tế**. Không đổi số test theo suy đoán.
Trạng thái live, branch, HEAD, emulator, account count và quyền công cụ phải được
kiểm tra lại; không dựa vào snapshot này để lặp lại thao tác có tác động dữ liệu.
