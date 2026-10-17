# MathLingo — Flutter + Supabase

Ứng dụng học toán lớp 1–5 với tài khoản phụ huynh, hồ sơ bé, lộ trình tương tác, luyện tập hồi tim, đấu trường, tủ đồ và bán gói học theo gia đình qua VNPay.

Đọc [hướng dẫn triển khai](DEPLOYMENT_GUIDE.md), [kế hoạch theo role](ROLE_COMMERCE_DEVELOPMENT_PLAN.md) và [đối chiếu triển khai](ROLE_COMMERCE_IMPLEMENTATION_STATUS.md).

## Chạy ứng dụng

Flutter 3.47.4/Dart 3.13.3 đã được dùng để kiểm thử. Sao chép `config/app.example.json` thành `config/app.json`, điền Supabase URL và public key; không đưa service key vào Flutter.

```powershell
flutter pub get
flutter run --dart-define-from-file=config/app.json
```

`config/app.json` không nằm trong Git. Sau khi clone/pull, từng thành viên cần điền URL và public key thật của cùng dự án; sao chép file mẫu nhưng giữ `YOUR_...` chưa đủ để kết nối. Không đưa service/secret key vào ứng dụng.

Nếu chạy bằng nút Run của IDE, cấu hình thêm đối số `--dart-define-from-file=config/app.json`, hoặc dùng lệnh trên trong thư mục dự án. Chỉ tạo file JSON rồi chạy `flutter run` sẽ không truyền cấu hình vào ứng dụng. Sau khi đổi cấu hình, dừng ứng dụng và chạy lại bằng lệnh đầy đủ.

## Kiểm tra mã

```powershell
flutter analyze --no-pub
flutter test --no-pub
node --test test_backend/*.test.mjs
node scripts/check-sql.mjs
```

Node 24 chạy các handler TypeScript trong môi trường giả lập Deno/fetch. Kiểm thử đó không thay thế triển khai Edge Functions thật. Các script SQL trong `supabase/tests/` chỉ thực thi khi bạn tự chạy trên staging; có transaction và ROLLBACK.

## Những luồng chính

- Phụ huynh: Auth thật/PIN server, quản lý bé, báo cáo, giới hạn học, gói và lịch sử đơn, thông báo và hỗ trợ.
- Học sinh: server chấm đáp án/ghi tiến độ và thưởng, tiếp tục bài dở, luyện 5 câu hồi tim, đấu trường nhóm 30, sở hữu/trang bị đồ.
- Admin: catalog/giá phiên bản, đơn/đối soát/refund, hỗ trợ gia đình, phân trang, cấp bù, roles/audit và cấu hình AI.
- Moderator: CMS nháp/xem trước/xuất bản; không được vận hành tài chính hoặc role.
- AI: chọn/chụp ảnh → OCR → sửa đề → gợi ý; backend giữ secret và quota. Mặc định tắt cho đến khi cấu hình/kiểm thử.
- Cache/outbox giúp khôi phục mất mạng ngắn; kết quả và phần thưởng vẫn cần xác nhận server.

## Database và phát hành

Bốn migrations cũ được giữ nguyên. Bốn migrations mới `20261018 → 20261021` **chưa được chạy**; người triển khai áp dụng theo thứ tự trong hướng dẫn. Không chạy lại seed hoặc reset Cloud.

Commerce mới dùng `learning_orders`/`learning_payments` để tương thích với hai bảng `orders`/`payments` legacy đã có trên Cloud. Khi copy SQL từ bản trước, cần lấy lại nội dung migrations mới nhất.

`scripts/build-android.ps1` hỗ trợ debug/release. Release yêu cầu upload keystore riêng qua `android/key.properties`; không dùng khóa debug. Giá gói và quota AI do admin cấu hình, không có giá/trial/demo success tự động.
