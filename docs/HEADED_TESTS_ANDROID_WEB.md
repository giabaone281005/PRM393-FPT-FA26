# Headed test: learner Android và Admin web

Đây là hướng dẫn hiện hành cho `run_headed_tests.bat`. Double-click file ở thư mục
gốc để chạy. Learner chạy trên Android emulator/điện thoại; Admin chạy trong cửa sổ
Chrome thật, khởi động qua `lib/admin_main.dart`. Admin không được dựng trên Android.

Bấm đúp `.bat` không truyền tham số sẽ chạy DEMO LOCAL (`-Offline`), không cần
credential. Đây không phải kiểm thử backend thật. Muốn chạy backend thật, chuẩn bị
JSON E2E rồi chạy `.bat -Config config/app.e2e.json`. Nếu giải nén thành thư mục con
trong repo, launcher tự tìm thư mục cha có `pubspec.yaml`.

## Chuẩn bị mỗi máy Windows

- Windows PowerShell 5.1+, Git, Flutter/Dart, Node.js/npm trong PATH. Nếu thiếu Deno,
  launcher tự cài Deno 2.9.6 vào `build/headed-tools/` và dùng lại ở các lần sau;
  lần đầu cần internet. Không cần quyền Admin hay sửa PATH hệ thống. CI hiện dùng
  Flutter 3.47.4, Dart 3.13.3 và Deno 2.9.6; dùng cùng phiên bản để kết quả nhất quán.
- Android Studio, Android SDK/platform-tools/Emulator, Java phù hợp với Flutter.
  Chạy `flutter doctor -v`, chấp nhận Android licenses và bật virtualization.
- Tạo ít nhất một AVD trong Android Studio Device Manager, tải system image phù hợp
  CPU. Launcher không tự cài SDK/image hoặc tạo AVD.
- SDK được tìm từ `ANDROID_SDK_ROOT`, `ANDROID_HOME`, thư mục mặc định Android Studio
  hoặc `android/local.properties`. Không cố định tên AVD, API, serial hay máy cá nhân.
- Lần đầu cần internet để tải Chrome for Testing + ChromeDriver cùng phiên bản từ
  Google vào `build/headed-browser/`. Các lần sau dùng cache; không phụ thuộc phiên
  bản Chrome cá nhân. Browser dùng profile tạm riêng, không dùng phiên đăng nhập cá nhân.

Nếu có thiết bị Android đã kết nối, launcher cho chọn thiết bị đó. Nếu chưa có,
launcher mở AVD có sẵn với cửa sổ hiển thị rồi chờ `sys.boot_completed=1`. Có nhiều
lựa chọn thì hiển thị danh sách. Muốn luôn mở một AVD cụ thể, truyền `-Avd`.

## Cấu hình backend cho hai role

Copy `config/app.e2e.example.json` thành `config/app.e2e.json` rồi điền cấu hình
project test/staging. File đích đã được Git ignore. Không đưa service-role key hoặc
secrets của provider vào JSON/APK/bundle web. Không dùng tài khoản cá nhân có dữ liệu.

Cần ba tài khoản Auth đã xác nhận email và có application account tương ứng:

| Cấu hình | Yêu cầu |
|---|---|
| `E2E_EMAIL/PASSWORD/ID` | Learner active, mới, chưa có backup/tiến độ |
| `E2E_ADMIN_EMAIL/PASSWORD/ID` | Admin active, có quyền Admin thật trong database |
| `E2E_PHONE_EMAIL/PASSWORD/ID` | Learner active thứ hai, mới, chưa có backup/tiến độ |

`ID` là UUID của Auth user; ba ID phải khác nhau. `E2E_DISPOSABLE: true` xác nhận
tài khoản chỉ dành cho test. Không dùng chung learner giữa các thành viên/lượt chạy
song song. Quyền Admin do quản trị viên project test cấp; launcher không tự nâng quyền.

Backend phải đã triển khai schema/RPC, learning-api, catalog 20 chủ đề/139 hoạt động,
tutor-chat có provider hoạt động và Realtime mà các integration test yêu cầu.
Launcher không chạy migration/reset database hoặc tự cấu hình dịch vụ.

**Trước mỗi lần full, cung cấp hai learner mới.** Learner journey kiểm tra onboarding
trống, backup và 600 verified XP; phone-readiness kiểm tra riêng 30 XP. Learner cũ
không còn đúng điều kiện ban đầu. Admin có thể tái sử dụng. Người quản trị project
test chịu trách nhiệm dọn fixture; launcher không xóa user/dữ liệu server. Web test
tạo rồi archive topic `headed-<run>`. Nếu suspend lỗi giữa chừng, test cố mở lại đúng
learner thử; nếu cleanup thất bại, log sẽ yêu cầu mở lại thủ công.

Credential Admin chỉ được truyền vào bundle test web; APK learner chỉ nhận credential
learner và UUID Admin để kiểm tra isolation. Hai nền tảng dùng cùng learner thử để
Admin web có thể tìm và quản lý tài khoản vừa học trên Android.

## Chạy

```bat
run_headed_tests.bat
run_headed_tests.bat -Avd YOUR_AVD_NAME
run_headed_tests.bat -DeviceId YOUR_ANDROID_SERIAL
run_headed_tests.bat -Config "D:\local-config\app.e2e.json"
run_headed_tests.bat -Offline
run_headed_tests.bat -PreflightOnly
```

`-Offline` không cần credential: chạy kiểm tra local, headed learner Android, Admin
web với repository giả lập và build. Đây chỉ việc không kết nối Supabase; pub get
và tải browser lần đầu vẫn có thể cần internet. Không coi đó là full backend pass.

`-PreflightOnly` kiểm tra tool, SDK và cấu hình (có thể chuẩn bị Deno khi thiếu);
không tải browser, mở emulator
hoặc chạy test. `-BootTimeoutSeconds 600` tăng thời gian chờ boot. Nếu đã có browser
và driver cùng phiên bản, truyền cả `-ChromeDriverPath` và `-ChromeBinary` bằng đường
dẫn tới hai file exe để bỏ qua việc tải cặp browser được quản lý.

Cửa sổ giữ lại kết quả sau khi chạy. Exit code 0 là tất cả bước được chọn thành công;
1 là lỗi. Để dùng trong terminal/CI không pause:

```bat
set MATHLINGO_NO_PAUSE=1
run_headed_tests.bat -Avd YOUR_AVD_NAME
```

## Trình tự

1. Kiểm tra điều kiện, chuẩn bị browser, mở/chọn Android và chờ boot.
2. Pub get, Flutter analyze, toàn bộ unit/widget test trong `test/`.
3. Parity evaluator, ba Dart standalone checks, Deno check/lint/Edge tests như CI.
4. `user_journey_test.dart` trên Android: onboarding, sai/đúng, đủ 8 bước Logic qua
   controls, mở lại, review không cộng XP lần hai và cô lập profile.
5. `full_stack_journey_test.dart` chỉ learner trên Android: duyệt 139 hoạt động,
   tutor, settings, sync/backup/conflict/offline retry/restore, isolation, verified
   XP và từ chối RPC Admin.
6. `phone_readiness_test.dart` trên learner riêng.
7. `admin_web_journey_test.dart` trên Chrome web: entrypoint thật, form validation,
   sai/đúng mật khẩu, dashboard, tìm learner, suspend/reactivate, từ chối RPC khi
   khóa, Realtime, tạo/sửa/archive topic, đăng xuất, learner bị từ chối giao diện
   Admin và RPC. Với `-Offline`, chạy `test/admin_web_smoke.dart` trên browser, dùng
   suite role/realtime/form/responsive hiện có với repository giả lập.
8. Build APK debug thường không có define E2E, build Admin web, `git diff --check`.

Browser dùng `flutter drive -d web-server --no-headless --browser-name=chrome` theo
[hướng dẫn Flutter web integration testing](https://docs.flutter.dev/testing/integration-tests#test-in-a-web-browser).
ChromeDriver chạy trên cổng loopback tự chọn, được dừng trong `finally` cả khi test
lỗi. Launcher chỉ dừng driver do chính lượt chạy đó khởi động.

## Kết quả và dữ liệu thử

Dừng ngay tại bước lỗi; không báo pass cho bước chưa chạy. Log và `result.json` ở
`build/headed-tests/<run>/`, được Git ignore. `headed-learner-android.log` và
`headed-admin-web.log` tách hai nền tảng. `admin-web-result.json` ghi checkpoint web
hoặc mode mock khi chạy offline. Mật khẩu được lọc khỏi output của các bước.

JSON define tạm được xóa trong finally. Nếu terminal bị kill/mất điện, kiểm tra và
xóa `*.private.json` còn lại trong thư mục log. Không chia sẻ toàn bộ `build/`: APK
test, bundle test web và cache compile có thể chứa credential. Bundle test chỉ phục
vụ cục bộ bởi `flutter drive`, không publish. APK integration còn cài trên thiết bị;
gỡ thủ công trên thiết bị test khi xong nếu cần. Gỡ app sẽ xóa dữ liệu app.

Kiểm tra riêng launcher bằng toolchain giả lập, không truy cập backend:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test_headed_runner.ps1
```

## Phạm vi kiểm chứng

Launcher hỗ trợ Windows có toolchain Android hợp lệ và browser web. Không bảo đảm
pass mọi kích thước màn hình/API/CPU; cần chạy từng cấu hình cần hỗ trợ. `.bat`
không chạy trên macOS/Linux hoặc iOS. Admin có browser E2E qua production entrypoint;
build web được kiểm tra riêng sau test.

Traversal learner dùng controls cho 92 hoạt động và public answer fixture cho 47
hoạt động; không phải toàn bộ đều qua gesture. OTP/email thật, chất lượng TTS/micro,
compiler remote và đổi giữa hai thiết bị vật lý chưa được bao phủ đầy đủ.
`integration_test` có [giới hạn tương tác native platform UI](https://docs.flutter.dev/cookbook/testing/integration/introduction).
Kết quả chỉ xác nhận các test đã liệt kê, không khẳng định mọi chức năng và mọi
trường hợp của hai role đều có E2E coverage.
