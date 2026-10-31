# Matlingo — Hướng dẫn setup và test cho team

Cập nhật: 31/10/2026. Áp dụng cho frontend Matlingo 1.3.2+6 trên nhánh `main`
sau khi merge thay đổi Gemini mặc định. Android là nền tảng chính để team test.

## 1. Chuẩn bị

| Thành phần | Yêu cầu |
|---|---|
| Source | Repository `giabaone281005/PRM393-FPT-FA26`, nhánh `main` |
| Flutter / Dart | Flutter 3.47.4, Dart 3.13.3 theo cấu hình CI của repo |
| Android | Android Studio/SDK, JDK 17, SDK theo yêu cầu `flutter doctor -v`; thiết bị Android API 24 trở lên |
| Emulator | Một Android Virtual Device; workspace tham chiếu dùng Pixel 9 / Android 15 (API 35) |
| Test backend | Node.js và Deno 2.9.6; không cần để chỉ chạy app |
| Tài khoản | Hai tài khoản test A/B do tester sở hữu, có hộp thư nhận mã xác nhận |
| Mạng | Internet cho đăng nhập, cloud và Gemini; học local có thể thử offline sau khi đăng nhập/mở hồ sơ |

Không dùng tài khoản hay hồ sơ cá nhân để thử xung đột/reset. Không xóa dữ liệu app
đang có tiến độ chưa sao lưu. Các thao tác test cloud ghi dữ liệu thật của tài khoản test.

## 2. Lấy source và chạy trên Android

Ví dụ PowerShell trên Windows; `$RepoRoot` là đường dẫn tuyệt đối tới clone của bạn.
Thay đường dẫn mẫu nếu lưu project ở nơi khác. Chỉ pull khi đã xử lý các thay đổi
local của chính mình; không dùng reset/clean để bỏ qua xung đột.

```powershell
git clone https://github.com/giabaone281005/PRM393-FPT-FA26.git 'D:\Projects\Matlingo'
$RepoRoot = 'D:\Projects\Matlingo'
Set-Location -LiteralPath $RepoRoot
git switch main
git pull --ff-only origin main
flutter --version
flutter doctor -v
flutter pub get
```

Nếu đã clone, bỏ lệnh `git clone`, đặt `$RepoRoot` tới clone hiện có rồi tiếp tục.

### Cấu hình bản cloud — dùng để test đầy đủ

```powershell
if (-not (Test-Path -LiteralPath "$RepoRoot\config\app.mobile.json")) {
    Copy-Item -LiteralPath "$RepoRoot\config\app.example.json" -Destination "$RepoRoot\config\app.mobile.json"
}
```

Chỉ sao chép khi chưa có file local; không ghi đè config đã điền. Nội dung mẫu:

```json
{
  "SUPABASE_URL": "https://seoswmcldwwytdrfrrrb.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "DIEN_PUBLISHABLE_KEY_CUA_PROJECT",
  "PASSWORD_RECOVERY_ENABLED": false
}
```

Lấy publishable key từ người quản lý project hoặc trang API Keys của Supabase
project `seoswmcldwwytdrfrrrb`. Đây là khóa frontend, không phải service role/secret.
File `config/app.mobile.json` được Git ignore. Không điền Gemini key vào file này.

```powershell
flutter emulators
# Thay Pixel_9 bằng ID thật từ danh sách trên, hoặc dùng điện thoại đã bật USB debugging.
flutter emulators --launch Pixel_9
flutter devices
# Thay emulator-5554 bằng device ID thật từ flutter devices.
flutter run -d emulator-5554 --dart-define-from-file="$RepoRoot\config\app.mobile.json"
```

Sau khi đổi dart defines phải dừng và chạy lại app. Hot reload không thay cấu hình build.

### Build APK cho người chỉ cài app

```powershell
flutter build apk --debug --dart-define-from-file="$RepoRoot\config\app.mobile.json"
Get-FileHash -LiteralPath "$RepoRoot\build\app\outputs\flutter-apk\app-debug.apk" -Algorithm SHA256
```

Gửi APK tại đường dẫn trên cùng commit/SHA-256 cho tester. Trên điện thoại, mở APK
và thực hiện cài đặt theo Android; nếu cập nhật, cần cùng chữ ký với bản đã cài.
Khi lỗi chữ ký, dùng thiết bị test khác hoặc xác minh sao lưu trước khi cân nhắc gỡ bản cũ.
Bản debug phục vụ test nội bộ. Bản release/store cần signing riêng theo README.

### Bản offline để phát triển

```powershell
flutter run -d emulator-5554
```

Bản không có dart defines cloud cho phép học/hồ sơ local; không dùng bản này để
kết luận đăng nhập, sao lưu, XP server hoặc Gemini mặc định bị lỗi. AI cá nhân vẫn
cần engine do người test cấu hình.

## 3. Gemini mặc định và engine cá nhân

Trên project chung, backend `tutor-chat` đã được triển khai và có secrets Gemini.
Tester chỉ cần chạy bản cloud, đăng nhập, mở hồ sơ và cuộn Trang chủ tới
**Cùng tìm ra lời giải**. Không cần thêm engine hoặc nhập API key để dùng gia sư mặc định.

Nếu đã chọn một AI cá nhân trong **Menu → Engine học tập**, kết nối đó được ưu tiên.
Để kiểm tra mặc định mà vẫn giữ cấu hình cá nhân, dùng tài khoản test mới chưa thêm
engine. Không dùng việc thiếu engine trong danh sách cài đặt làm bằng chứng Gemini
mặc định chưa được kết nối.

Khi dùng một Supabase project khác, người phụ trách backend phải cấu hình Auth,
API/schema hiện hành và `tutor-chat`. Chỉ deploy hàm mới không tạo đủ backend.
Với project đã có backend tương thích, quản trị viên thiết lập secrets từ file riêng
ngoài Git (đường dẫn mẫu dưới đây không phải file có sẵn):

```dotenv
GEMINI_API_KEY=THAY_BANG_KHOA_RIENG_CUA_PROJECT
GEMINI_MODEL=gemini-3.5-flash-lite
```

```powershell
npx supabase secrets set --help
npx supabase secrets set --project-ref YOUR_PROJECT_REF --env-file 'D:\Private\matlingo-tutor.env'
npx supabase functions deploy --help
npx supabase functions deploy tutor-chat --project-ref YOUR_PROJECT_REF --no-verify-jwt --use-api
```

CLI cần phiên đăng nhập quản trị. `--no-verify-jwt` ở đây dùng vì handler tự xác thực
JWT qua Auth và kiểm tra tài khoản active, tương tự `learning-api`; không phải API
chat công khai cho người chưa đăng nhập. Không in/commit file secrets hay đưa key
dùng chung vào APK. Không chạy `supabase db reset`, `db push` hoặc deploy stub retired
trên project chung; migration history cũ cần đối chiếu theo tài liệu backend.

Backend giới hạn nội dung, timeout và output; chặn burst 10 request/phút/tài khoản
trong từng isolate. Đây không phải quota phân tán. Quota/budget chung do Google
project quản lý; người phụ trách cần theo dõi khi nhiều tester dùng cùng lúc.

## 4. Dữ liệu và thứ tự test

1. Tạo tài khoản test A và B; tự giữ mật khẩu, không ghi vào report/repo.
2. Với A, tạo hồ sơ `QA_Moi_<ngay>` chưa học Logic, mục tiêu 10 phút.
3. Tạo thêm hồ sơ `QA_Rieng_<ngay>` để kiểm tra cách ly tiến độ giữa hồ sơ.
4. Test luồng học/khôi phục trước, sau đó đổi tài khoản và thử offline/cloud.
5. Ghi commit, APK hash, thiết bị, Android, loại build và kết quả từng ca.

## 5. Checklist từng chức năng

Mỗi ca mặc định **NOT RUN**. Chỉ ghi **PASS** khi tự thực hiện đúng điều kiện và
quan sát được kết quả. Dùng **FAIL**, **BLOCKED** hoặc **N/A** kèm lý do khi cần.
Test tự động không thay thế kết quả test thủ công trên điện thoại.

### A. Tài khoản và hồ sơ

| ID | Thao tác | Kết quả mong đợi |
|---|---|---|
| A01 | Mở bản cloud trên môi trường test chưa có phiên đăng nhập | Yêu cầu đăng nhập/đăng ký trước khi học |
| A02 | Để trống form; nhập email sai; thử sai mật khẩu một lần rồi đúng | Lỗi dễ hiểu, focus đúng trường; đăng nhập đúng mở chọn/tạo hồ sơ |
| A03 | Đổi Đăng nhập/Đăng ký; hiện/ẩn mật khẩu; bấm khi request đang chạy | Giữ email, xóa mật khẩu khi đổi chế độ; không gửi trùng; có trạng thái đang xử lý |
| A04 | Đăng ký email test mới; nhập mã từ hộp thư; thử gửi lại khi hết cooldown | Xác nhận được với mã hợp lệ; lỗi/cooldown rõ; không giả định email luôn đến ngay |
| A05 | Đóng app ở OTP; mở lại và chọn Đã có mã xác nhận? Nhập mã | Có thể tiếp tục xác nhận bằng email/mã hợp lệ |
| A06 | Tạo hồ sơ: tên rỗng, quá dài, sau đó tên hợp lệ; chọn sở thích/mục tiêu | Chặn tên sai; lưu onboarding hợp lệ; mở lại không bắt làm lại |
| A07 | Tạo hai hồ sơ, học một hồ sơ rồi đổi hồ sơ còn lại | Tiến độ/hồ sơ không bị trộn |
| A08 | Đăng xuất tại menu, chọn hồ sơ và onboarding; đăng nhập B rồi quay lại A | B không thấy hồ sơ đã liên kết của A; A vẫn giữ tiến độ |
| A09 | Nếu recovery đã cấu hình: Quên mật khẩu → mã → mật khẩu mới → đăng nhập | Đổi mật khẩu thật; mã sai/hết hạn không đổi được. Flag tắt thì N/A |

### B. Chủ đề và bài học tương tác

| ID | Thao tác | Kết quả mong đợi |
|---|---|---|
| B01 | Mở Chủ đề, tìm Logic, tìm `zzzz_qa_404`, xóa tìm kiếm và thử bộ lọc | Kết quả đúng; trạng thái rỗng rõ; xóa không mất bộ lọc đang chọn |
| B02 | Vào Logic; ở bài cân thả 3 khối và kiểm tra, sửa thành 4 rồi kiểm tra | Sai chưa hoàn thành; đúng có giải thích và cho đi tiếp |
| B03 | Làm một phần bài tiếp theo, về Trang chủ → Học tiếp; đóng/mở app | Khôi phục đúng bước và trạng thái đã lưu |
| B04 | Hoàn thành đủ 6 hoạt động Logic và kết thúc hành trình | Lần đầu tăng 30 XP local, có lịch sử và trạng thái hoàn thành |
| B05 | Ôn lại toàn bộ Logic đã hoàn thành | Có lịch sử ôn; không nhận lại 30 XP lần đầu |
| B06 | Duyệt tất cả 13 chủ đề; thử kéo/thả, bật/tắt, xoay/zoom và gợi ý ở các bài phù hợp | Tương tác thật, kiểm tra sai/đúng hợp lý; không crash/khóa nút điều hướng |
| B07 | Đang học thì tắt/bật mạng, đưa app nền rồi quay lại | Không mất trạng thái local; không tự báo XP server khi chưa được xác nhận |

Thao tác đúng cho Logic: **4 khối → bỏ 3 cặp → bánh nhỏ 2 vòng → bỏ 5 cặp →
6 khối → A bật/B tắt**. Mỗi bước cần **Kiểm tra → Khám phá tiếp**; bước cuối
**Hoàn thành hành trình**. Danh sách chi tiết và ca UI bổ sung ở
[TEST_UI_UX_VA_LUONG.md](TEST_UI_UX_VA_LUONG.md).

### C. Tiến độ, XP và cloud

| ID | Thao tác | Kết quả mong đợi |
|---|---|---|
| C01 | Xem tab Hồ sơ; đổi hôm nay/hôm qua, kiểm tra thời gian/XP/lịch sử | Hiển thị đúng ngày/hồ sơ; đổi tab không tự tăng điểm |
| C02 | Học Logic khi offline, kết nối lại, chờ app đồng bộ hoặc dùng Đồng bộ tiến độ ngay | Dữ liệu local còn; server xác nhận khi payload hợp lệ; phân biệt XP local/server |
| C03 | Gửi lại đồng bộ bài Logic đã xác nhận hai lần; mở app lại | Không cấp thưởng server trùng |
| C04 | Menu → Tài khoản & sao lưu → Lưu lại ngay → Tải lại danh sách cloud | Có bản sao lưu và thời điểm mới; lỗi mạng không làm mất dữ liệu máy |
| C05 | Khôi phục thành hồ sơ riêng; mở hồ sơ mới | Đúng dữ liệu backup; hồ sơ/bản nháp cũ vẫn còn; không tự gộp hai bản |
| C06 | Hai thiết bị test cùng tài khoản thay đổi metadata từ cùng bản cũ rồi đồng bộ | Có xử lý xung đột/lựa chọn bản giữ; không âm thầm ghi đè |
| C07 | Đổi sang B rồi thử tải danh sách sao lưu | Không đọc/khôi phục backup của A |

Local có 71 hoạt động; backend baseline hiện có 53 hoạt động published với evaluator.
Các hoạt động local chưa publish có thể chờ đồng bộ; không dùng chúng để kết luận
server XP hỏng. Chọn Logic khi cần kiểm tra đường đi có evaluator. Sao lưu là snapshot,
chưa tự hợp nhất tiến độ nhiều thiết bị. Không kỳ vọng upload khi Android đã dừng app.

### D. Gemini, bảng vẽ và engine AI

| ID | Thao tác | Kết quả mong đợi |
|---|---|---|
| D01 | Cloud, đăng nhập, chưa chọn AI cá nhân → Trang chủ → gửi `Gợi ý cách giải x + 3 = 7` | Gemini mặc định trả lời/gợi ý thật, không yêu cầu API key; không kiểm tra văn bản cố định |
| D02 | Hỏi tiếp `Vì sao phải trừ cả hai vế?` | Gửi được lượt tiếp theo và có ngữ cảnh hội thoại |
| D03 | Mở bảng vẽ trong chat, vẽ vài nét, gửi câu hỏi liên quan | Không crash; gửi được canvas cùng câu hỏi. Hiện chưa có annotation tự động/STT/TTS |
| D04 | Tắt mạng, gửi câu hỏi; bật mạng và thử lại | Báo lỗi rõ, giữ bản nháp; không giả lập câu trả lời |
| D05 | Đang chờ trả lời thì đổi/đăng xuất tài khoản | Request cũ không trả lời vào phiên mới; tài khoản mới dùng cấu hình riêng |
| D06 | Menu → Engine học tập → Thêm engine AI bằng thông tin hợp lệ → Lưu kết nối → Sử dụng | AI cá nhân được ưu tiên; chỉ lưu chưa có nghĩa đã kích hoạt |
| D07 | Sửa tên/model; đổi provider/endpoint khi đã có khóa; mở lại cấu hình | Không hiển thị khóa cũ; đổi nơi nhận khóa yêu cầu nhập lại hoặc xóa khóa |
| D08 | Bản offline không cấu hình cloud, chưa có AI cá nhân | Hiện trợ lý chưa kết nối; đây là đúng điều kiện build, không phải lỗi Gemini server |

Engine cá nhân là tùy chọn. Chỉ thử với endpoint/key do tester có quyền sử dụng;
không ghi key vào report. Không spam API để kiểm tra giới hạn trên project chung.

### E. Chạy mã và phần giao diện còn lại

| ID | Điều kiện / thao tác | Kết quả mong đợi |
|---|---|---|
| E01 | Menu → Engine học tập → Thử chạy mã khi chưa chọn code engine | Hiển thị cần kết nối; không giả stdout |
| E02 | Có Docker gateway/Judge0 tương thích: thêm/kích hoạt engine code, chọn Python và chạy `print(2 + 3)` | Stdout có `5`; đang chạy ngăn gửi trùng |
| E03 | Engine hỗ trợ JavaScript: chạy `console.log(2 + 3)`; thử lỗi cú pháp và timeout | Kết quả/lỗi rõ, không treo; chỉ ghi PASS khi đã gọi engine thật |
| E04 | Chọn Pyodide khi chưa có embedded bridge | Báo chưa khả dụng; không coi đây là Python offline đã hoạt động |
| E05 | Trang chủ → cú Mây: chạm, kéo xoay, thử các nút động tác | Mascot phản hồi; không che điều hướng/giật layout |
| E06 | Menu → Cài đặt: đổi nền/màu/cỡ chữ/giảm chuyển động; đóng/mở app | Áp dụng và lưu lựa chọn; không đổi tiến độ |
| E07 | Menu → Giới thiệu, Trợ giúp; mở các câu hỏi trợ giúp rồi Back | Phiên bản đúng APK; trở về tab trước; nội dung đọc được |
| E08 | Test 320/375dp, chữ lớn, xoay ngang, bàn phím mở, TalkBack trên Android | Không tràn/che nút chính; đọc và chạm được; ghi rõ màn hình lỗi |

Docker/Judge0 cần server sandbox thật; app không tích hợp sẵn compiler hoặc Docker
daemon. Judge0 cần language ID đúng deployment. Chưa có engine code của team thì
E02/E03 ghi BLOCKED, không dùng kết quả mock làm PASS. Quiz/mastery là component
mở rộng, chưa là luồng dashboard hoàn chỉnh. Premium/thanh toán, admin dashboard,
voice và multiplayer canvas không thuộc chức năng đã hoàn thiện của frontend này.

## 6. Chạy kiểm tra tự động

Các lệnh dưới chạy tại `$RepoRoot` đã đặt ở mục 2. Thực hiện build sau tests,
không chạy Gradle/integration/release đồng thời.

```powershell
flutter analyze
flutter test --no-pub --reporter expanded
dart "$RepoRoot\tools\check_diverse.dart"
dart "$RepoRoot\tools\check_depth.dart"
dart "$RepoRoot\tools\check_space.dart"
node "$RepoRoot\supabase\tests\evaluator_parity.mjs"
deno check "$RepoRoot\supabase\functions\learning-api\index.ts" "$RepoRoot\supabase\functions\tutor-chat\index.ts"
deno lint "$RepoRoot\supabase\functions\learning-api\index.ts" "$RepoRoot\supabase\functions\learning-api\handler.ts" "$RepoRoot\supabase\functions\_shared\http.ts" "$RepoRoot\supabase\functions\tutor-chat" "$RepoRoot\supabase\tests\learning_handler_test.ts" "$RepoRoot\supabase\tests\tutor_handler_test.ts"
deno test "$RepoRoot\supabase\tests\learning_handler_test.ts" "$RepoRoot\supabase\tests\tutor_handler_test.ts"
git diff --check
flutter build apk --debug --dart-define-from-file="$RepoRoot\config\app.mobile.json"
```

Nếu chưa cài Deno trực tiếp nhưng có Node/npm, có thể thay `deno` bằng `npx deno`.
Unit/widget/handler tests dùng mock, không chứng minh email/provider thật hoạt động.
Một số widget test xuất lại ảnh tại thư mục docs: kiểm tra `git status` sau chạy,
đừng commit ảnh sinh lại nếu không chủ đích cập nhật reference.

Integration local tùy chọn trên emulator test:

```powershell
flutter test "$RepoRoot\integration_test\user_journey_test.dart" -d emulator-5554
```

Test này dùng namespace local riêng và không chứng minh Gemini/cloud thật. Test
`integration_test/phone_readiness_test.dart` cần tài khoản fixture riêng cùng config
ignored `config/app.e2e.json` có URL, publishable key, `E2E_EMAIL`, `E2E_PASSWORD`,
`E2E_ID` đúng Auth user ID. Chỉ người phụ trách fixture chạy test live đó; không dùng
tài khoản cá nhân và không đưa file config E2E vào build APK chia sẻ.

## 7. Lỗi thường gặp

| Hiện tượng | Kiểm tra |
|---|---|
| Không có đăng nhập/cloud/Gemini mặc định | Build lại với đúng `--dart-define-from-file`; xác nhận config local không còn placeholder |
| Chat vẫn báo chưa kết nối | Kiểm tra commit đã có thay đổi mặc định, bản cloud, phiên đăng nhập và lỗi tải secure storage |
| Chat báo lỗi dù đã kết nối | Kiểm tra mạng, tài khoản active, deployment `tutor-chat`, secrets/model và quota; admin xem log, không đưa token vào report |
| Gemini mặc định không được gọi | Kiểm tra có AI cá nhân đang Sử dụng không; thử tài khoản test chưa cấu hình engine |
| Email không đến/mã không dùng được | Kiểm tra spam/SMTP/template, email đúng tài khoản, mã mới nhất/cooldown; không tắt email confirmation để bỏ qua test |
| Quên mật khẩu không có nút | Flag recovery mặc định tắt; chỉ bật khi backend/email recovery đã thiết lập |
| Emulator chưa xuất hiện | Chờ boot xong, chạy lại `flutter devices`; kiểm tra SDK/virtualization qua doctor |
| Release báo thiếu signing | Dùng debug APK cho QA hoặc cấu hình keystore riêng; không commit key/password |
| Tiến độ không giống máy khác | Kiểm tra account/hồ sơ và backup; restore tạo hồ sơ riêng, không tự merge |

## 8. Mẫu báo lỗi và điều kiện bàn giao

```text
ID ca test:
Tester / thời điểm:
Commit / branch:
APK version / SHA-256:
Thiết bị / Android / cỡ chữ:
Build cloud hay offline / trạng thái mạng:
Dữ liệu test (tên hồ sơ, không ghi mật khẩu/token):
Các bước tái hiện:
Kết quả mong đợi:
Kết quả thực tế:
PASS / FAIL / BLOCKED / N/A và lý do:
Ảnh/video/log đã che email/token khi cần:
```

Trước bàn giao: test A01–A08, B01–B05, C01–C05, D01–D04 và E05–E08 trên đúng
APK được chia sẻ; ca phụ thuộc cấu hình ghi lý do nếu chưa chạy. Bản build đạt không
đồng nghĩa tất cả ca thủ công PASS. Kết quả tự động và giới hạn đã biết được ghi tại
[VALIDATION.md](../VALIDATION.md); hợp đồng AI ở
[ENGINE_ARCHITECTURE.md](ENGINE_ARCHITECTURE.md), backend ở
[supabase/README.md](../supabase/README.md).
