# Chạy test tự động có cửa sổ Android trên Windows

Double-click `run_headed_tests.bat` ở thư mục gốc. Cửa sổ giữ lại kết quả khi chạy xong;
exit code là 0 khi tất cả bước được chọn thành công, 1 khi lỗi. Chạy từ thư mục nào
cũng được, kể cả đường dẫn chứa dấu cách. Không cần sửa đường dẫn máy trong script.

## Chuẩn bị mỗi máy

- Windows PowerShell 5.1 trở lên, Git, Flutter/Dart trong PATH. CI hiện dùng Flutter
  3.47.4 / Dart 3.13.3; dùng cùng phiên bản để kết quả nhất quán.
- Node.js và Deno trong PATH (CI dùng Deno 2.9.6).
- Android Studio, Android SDK/platform-tools/Emulator, Java phù hợp với Flutter;
  chạy `flutter doctor -v`, chấp nhận Android licenses trước lần đầu.
- Tạo ít nhất một AVD trong Android Studio Device Manager, tải system image phù hợp
  CPU và bật virtualization. Script không tự tải SDK/image hoặc tạo AVD.
- SDK được tìm từ `ANDROID_SDK_ROOT`, `ANDROID_HOME`, thư mục mặc định của Android
  Studio hoặc `android/local.properties`. Không cố định Pixel, API hay serial.

Nếu chỉ có một thiết bị Android đã kết nối thì script dùng thiết bị đó. Nếu chưa có,
script mở AVD có sẵn với cửa sổ hiển thị và chờ `sys.boot_completed=1`. Có nhiều lựa
chọn thì hiển thị danh sách. Muốn luôn mở một AVD cụ thể, truyền `-Avd`.

## Cấu hình backend cho hai role

Copy `config/app.e2e.example.json` thành `config/app.e2e.json` rồi điền cấu hình
**project test/staging**. File đích đã được Git ignore. Không dùng project/tài khoản
cá nhân có dữ liệu cần giữ. Không đưa service-role key vào JSON hoặc APK.

Cần ba tài khoản Auth đã xác nhận email và có application account tương ứng:

| Cấu hình | Yêu cầu |
|---|---|
| `E2E_EMAIL/PASSWORD/ID` | Người học active, mới, chưa có backup/tiến độ |
| `E2E_ADMIN_EMAIL/PASSWORD/ID` | Admin active với quyền Admin thật trong database |
| `E2E_PHONE_EMAIL/PASSWORD/ID` | Người học active thứ hai, mới, chưa có backup/tiến độ |

`ID` là UUID của Auth user, ba ID phải khác nhau. `E2E_DISPOSABLE: true` xác nhận
các tài khoản này dành riêng cho test. Không dùng chung learner giữa các thành viên
hoặc các lượt chạy song song. Quyền Admin phải được quản trị viên project test cấp;
launcher không tự nâng quyền hay thay đổi policy.

Backend phải đã triển khai schema/RPC, learning-api, catalog 20 chủ đề/139 hoạt động,
tutor-chat với provider hoạt động và Realtime mà integration test hiện có yêu cầu.
Launcher không chạy migration/reset database hoặc tự cấu hình dịch vụ.

**Trước mỗi lần chạy full, cung cấp hai learner mới.** Full-stack kiểm tra onboarding
trống, backup, 600 verified XP; phone-readiness kiểm tra riêng 30 XP. Chạy lại trên
learner cũ sẽ không còn đúng điều kiện ban đầu. Admin có thể tái sử dụng. Người quản
trị project test chịu trách nhiệm dọn fixture sau lượt chạy; script không xóa user
hoặc dữ liệu server. Một topic mang ID `headed-<run>` được tạo rồi archive. Nếu test
dừng giữa bước suspend/reactivate, tài khoản learner thử có thể còn bị khóa.

## Các lệnh

```bat
run_headed_tests.bat
run_headed_tests.bat -Avd YOUR_AVD_NAME
run_headed_tests.bat -DeviceId emulator-5554
run_headed_tests.bat -DeviceId YOUR_ANDROID_SERIAL
run_headed_tests.bat -Config "D:\local-config\app.e2e.json"
run_headed_tests.bat -Offline
run_headed_tests.bat -PreflightOnly
```

`-Offline` không cần credential; chạy các kiểm tra local, headed user journey và
build. Đây không phải kết quả full backend/Admin. `-PreflightOnly` chỉ kiểm tra tool,
SDK và cấu hình, không bật emulator hay chạy test. `-BootTimeoutSeconds 600` tăng
thời gian chờ boot. Để dùng trong terminal/CI mà không pause:

```bat
set MATHLINGO_NO_PAUSE=1
run_headed_tests.bat -Avd YOUR_AVD_NAME
```

## Trình tự và kết quả

1. Kiểm tra điều kiện, mở/chọn Android và chờ boot.
2. Pub get, Flutter analyze, toàn bộ unit/widget test trong `test/`.
3. Parity evaluator, ba Dart standalone checks, Deno check/lint/Edge tests như CI.
4. Headed `user_journey_test.dart`: onboarding, sai/đúng, đủ 8 hoạt động Logic qua
   controls, mở lại, review không cộng XP lần hai và cô lập profile.
5. Headed `full_stack_journey_test.dart`: learner + Admin thật, duyệt 139 hoạt động,
   tutor, settings, sync/backup/conflict/offline retry/restore, isolation, verified
   XP, phân quyền, suspend/reactivate, Realtime, tạo/sửa/archive topic.
6. Headed `phone_readiness_test.dart` trên learner riêng.
7. Build APK debug thường không có define E2E, build Admin web, `git diff --check`.

Dừng ngay tại bước lỗi; không in thông báo pass cho các bước chưa chạy. Kết quả và
log từng bước ở `build/headed-tests/<run>/result.json` và `*.log`, được Git ignore.
Mật khẩu được lọc khỏi output của các bước. JSON define tạm được xóa trong finally;
nếu terminal bị kill/mất điện, kiểm tra và xóa `*.private.json` còn lại trong thư mục
log. Không chia sẻ toàn bộ `build/`: APK test và cache compile có thể chứa credential.
APK integration còn cài trên thiết bị sau test; gỡ app test thủ công trên thiết bị
test khi hoàn tất. Việc gỡ app sẽ xóa dữ liệu app, nên launcher không tự làm.

Kiểm tra riêng logic launcher bằng toolchain giả lập (không truy cập backend):
`powershell -NoProfile -ExecutionPolicy Bypass -File tools/test_headed_runner.ps1`.

## Giới hạn coverage và tương thích

Launcher hỗ trợ máy Windows có toolchain Android hợp lệ và cho phép chọn Android
emulator/thiết bị thật; không bảo đảm pass mọi kích thước màn hình/API/CPU. Cần chạy
trên từng cấu hình cần hỗ trợ. `.bat` không chạy trên macOS/Linux hay iOS.

AdminApp được integration test dựng trên Android; build web được kiểm tra riêng.
Chưa có browser E2E cho Admin web. Traversal hiện dùng controls cho 92 hoạt động và
public answer fixture cho 47 hoạt động; không phải toàn bộ 139 đều qua gesture.
OTP/email thật, chất lượng TTS/micro, trình biên dịch remote và đổi giữa hai thiết
bị vật lý chưa được bao phủ đầy đủ. `integration_test` cũng có [giới hạn tương tác
với native platform UI](https://docs.flutter.dev/cookbook/testing/integration/introduction).
Kết quả full ở đây chỉ xác nhận các test đã liệt kê, không khẳng định mọi chức năng
và mọi trường hợp của hai role đều có E2E coverage.
