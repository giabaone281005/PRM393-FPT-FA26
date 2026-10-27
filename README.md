# Matlingo

Ứng dụng học tập bằng tiếng Việt, xây dựng với Flutter. Người học khám phá kiến thức bằng cách kéo, xoay, ghép và thử nghiệm trực tiếp trên các mô hình tương tác.

## Tính năng chính

- **Học qua thực hành:** 13 chủ đề, 71 hoạt động, gồm toán học, logic, lập trình, dữ liệu, mạch điện, hình học 3D, triết học và hội họa.
- **Theo dõi tiến độ:** lưu hồ sơ, bài đang học, lịch sử, thời gian học và XP.
- **Tài khoản và cloud:** đăng nhập, xác nhận email, tự sao lưu hồ sơ và gửi kết quả học lên Supabase để xác nhận XP.
- **Trợ lý học tập:** chat AI, bảng vẽ và môi trường thực hành Python/JavaScript qua engine do người dùng cấu hình.
- **Tùy chỉnh giao diện:** hỗ trợ chữ lớn, giảm chuyển động và lưu lựa chọn trên thiết bị.

Luồng sử dụng: **Mở hồ sơ → Chọn chủ đề → Thực hành → Hoàn thành → Xem tiến độ.**

## Công nghệ

Flutter 3.47.4 · Dart 3.13.3 · Supabase · SharedPreferences · Flutter Secure Storage.

Phiên bản hiện tại: **1.3.2+6**. Android là nền tảng đã kiểm thử; iOS cần macOS/Xcode và chưa được xác minh.

## Chạy dự án

Cài Flutter và Android SDK, sau đó chạy tại thư mục gốc repository:

```sh
flutter pub get
flutter run
```

Lệnh trên chạy chế độ offline phục vụ phát triển. Để bật đăng nhập và cloud:

1. Sao chép `config/app.example.json` thành `config/app.mobile.json`.
2. Điền URL và publishable key của project Supabase đã thiết lập backend.
3. Chạy:

```sh
flutter run --dart-define-from-file=config/app.mobile.json
```

File cấu hình local được Git ignore. Không đưa service role key hoặc khóa AI dùng chung vào ứng dụng. Chat AI và chạy code cần cấu hình engine riêng trong menu **Engine học tập**.

Luồng quên mật khẩu cần áp dụng [email recovery](supabase/templates/README.md) trên backend rồi bật `PASSWORD_RECOVERY_ENABLED` trong file cấu hình mobile.

## Kiểm tra và build Android

```sh
flutter analyze
flutter test
flutter build apk --debug
```

APK debug nằm tại `build/app/outputs/flutter-apk/app-debug.apk`. Để build bản có cloud, thêm `--dart-define-from-file=config/app.mobile.json` vào lệnh build.

Bản release yêu cầu keystore riêng: sao chép `android/key.properties.example` thành `android/key.properties`, điền thông tin signing và giữ keystore ngoài repo. Sau đó chạy `flutter build appbundle --release --dart-define-from-file=config/app.mobile.json`. File chứa mật khẩu signing không được commit.

## Cấu trúc chính

| Thư mục | Nội dung |
|---|---|
| `lib/` | Ứng dụng Flutter, giao diện và mô hình bài học |
| `lib/data/` | Repository, quản lý state, đồng bộ và kết nối engine |
| `lib/features/` | Các màn hình và thành phần tính năng |
| `supabase/` | Migration, API học tập và kiểm thử backend |
| `test/`, `integration_test/` | Kiểm thử ứng dụng |
| `docs/` | Tài liệu chi tiết |

## Tài liệu tham khảo

- [Hướng dẫn đóng góp và quy tắc dự án](AGENTS.md)
- [Kết quả và quy trình kiểm thử](VALIDATION.md)
- [Hướng dẫn bản Android](docs/PHONE_READINESS.md)
- [Đăng nhập và sao lưu cloud](docs/MOBILE_CLOUD_BACKUP.md)
- [Thiết lập backend](supabase/README.md)

Sao lưu cloud hiện khôi phục thành hồ sơ riêng, chưa tự hợp nhất tiến độ giữa nhiều thiết bị. Hộp thư thật, điện thoại vật lý và dịch vụ AI/code bên ngoài vẫn cần kiểm tra thực tế.
