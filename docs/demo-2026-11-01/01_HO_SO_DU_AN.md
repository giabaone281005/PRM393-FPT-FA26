# Hồ sơ dự án Matlingo

Tài liệu giới thiệu và trao đổi kỹ thuật | Demo ngày 01/11/2026

## Tổng quan

Matlingo là ứng dụng học tập bằng tiếng Việt trên Flutter. Người học khám phá kiến thức bằng cách kéo, xoay, ghép và thử nghiệm trên mô hình tương tác; nhận phản hồi rồi điều chỉnh cách làm. Giá trị chính của sản phẩm là kết nối thao tác trực tiếp, giải thích và tiến độ học trong một hành trình thống nhất.

Bản mã nguồn hiện tại có phiên bản 1.3.2+6, gồm 13 chủ đề và 71 hoạt động được đóng gói trong ứng dụng. Android là nền tảng ưu tiên. Các số liệu kiểm thử trong tài liệu này được ghi kèm thời điểm và phạm vi, không thay thế kết quả chạy trên thiết bị trình bày.

## Vấn đề và hướng giải quyết

Việc chỉ đọc lý thuyết hoặc chọn đáp án có thể khiến người học khó quan sát quan hệ giữa các đại lượng. Matlingo đưa người học vào mô hình có thể thao tác, cho phép thử sai, nhận phản hồi và thử lại. Bài cân bằng là ví dụ: thay đổi số khối rồi quan sát điều kiện cân bằng trước khi chuyển sang bài tiếp theo.

Đối tượng sử dụng hướng tới là người học muốn tiếp cận kiến thức qua hoạt động ngắn bằng tiếng Việt. Buổi demo tập trung vào trải nghiệm học; chưa dùng kết quả nghiên cứu người dùng để khẳng định hiệu quả giáo dục.

## Mục tiêu sản phẩm

- Cho phép khám phá kiến thức bằng thao tác thay vì chỉ xem nội dung.
- Giữ bài đang làm và tiến độ theo từng hồ sơ.
- Học nội dung đã đóng gói khi offline trong điều kiện phiên và hồ sơ phù hợp.
- Bổ sung tài khoản, sao lưu và xác nhận kết quả qua backend ở bản có cấu hình cloud.
- Cho phép kết nối trợ lý AI và môi trường chạy code qua engine riêng.

## Luồng sử dụng cốt lõi

Mở ứng dụng → đăng nhập nếu dùng bản cloud → tạo hoặc chọn hồ sơ → chọn chủ đề → thực hành và kiểm tra → hoàn thành → xem tiến độ hoặc học tiếp.

Thông điệp trình bày: “Matlingo giúp người học hiểu qua thao tác trực tiếp và phản hồi, đồng thời giữ lại hành trình để có thể tiếp tục.”

<!-- PAGEBREAK -->

## Phạm vi chức năng hiện tại

### Học tương tác

Danh mục gồm Logic, phân số, chuyển động, dữ liệu, hình học, lập trình bằng hành động, mạch điện, xác suất, đại số, thuật toán, địa lý, triết học và hội họa. Demo chọn Logic vì thể hiện được thao tác, phản hồi và tiến độ trong thời gian ngắn.

Mô hình bài học và workspace tương tác được xây dựng bằng Flutter/Dart. Không đồng nhất hoạt động lập trình robot trong catalog với dịch vụ chạy mã Python hoặc JavaScript từ xa.

### Hồ sơ và tiến độ

Ứng dụng hỗ trợ tạo/chọn hồ sơ, chọn sở thích và mục tiêu số phút học, tiếp tục bài đang dở, lịch sử và XP cá nhân. Theo mã nguồn LearningStore, XP cá nhân được tính theo số chủ đề đã hoàn thành, 30 XP mỗi chủ đề; ôn lại không nhận thêm phần thưởng hoàn thành lần đầu.

### Tài khoản và cloud

Bản có cấu hình Supabase yêu cầu đăng nhập; có luồng đăng ký và xác nhận mã email. Sau khi đã có phiên và hồ sơ trên máy, nội dung bundled có thể được học offline. Đăng nhập lần đầu, sao lưu, xác nhận XP và dịch vụ từ xa cần mạng.

Sao lưu cá nhân và API ghi nhận học tập là hai cơ chế riêng. Sao lưu khôi phục thành hồ sơ riêng, chưa tự hợp nhất tiến độ nhiều máy. XP trên máy và XP server xác nhận phải được trình bày riêng. Không hứa đồng bộ nền khi Android đã dừng tiến trình.

### Trợ lý và tùy chỉnh

Có giao diện chat, canvas, cấu hình engine AI/code và playground. Gọi AI hoặc chạy mã phụ thuộc engine và dịch vụ đã được cấu hình, không có dịch vụ dùng chung được cấp sẵn. Chữ lớn và giảm chuyển động là các tùy chọn phù hợp để giới thiệu nhanh.

### Phần chưa dùng để cam kết trong demo

- Catalog local có 71 hoạt động; kiểm tra parity được ghi nhận trên 53 hoạt động baseline. Còn 18 bài local chờ phát hành nội dung server theo VALIDATION.md.
- iOS, điện thoại vật lý, hộp thư thật và provider ngoài chưa có bằng chứng mới cho buổi demo này.
- Khôi phục mật khẩu bị tắt mặc định cho tới khi cấu hình template và cờ tính năng phù hợp.
- Thanh toán, Parent Portal và Admin trong báo cáo MathLingo lịch sử không chứng minh các chức năng đó có trong frontend Matlingo hiện tại.

<!-- PAGEBREAK -->

## Kiến trúc và dữ liệu

### Các thành phần chính

- Giao diện: LearnApp, onboarding, danh mục, lesson runner, hồ sơ và menu. Một số thành phần hiện nằm ở root lib; các tính năng mới được tách trong lib/features.
- Trạng thái local: LearningStore giữ hồ sơ, bản nháp, lịch sử và hoàn thành; SharedPreferences lưu trạng thái trên thiết bị.
- Tầng dữ liệu: repository quản lý Auth, backup, learning API và engine; controller điều phối đồng bộ và vòng đời phiên.
- Backend cloud: Supabase Auth, PostgreSQL, RPC và Edge Function learning-api; quyền và kết quả xác nhận được kiểm tra phía server.
- Engine: registry chọn AI/code độc lập; adapter gửi yêu cầu tới dịch vụ phù hợp; credential nằm trong secure storage theo tài khoản.

### Luồng xử lý một bài học

1. Người học mở một hoạt động từ catalog đóng gói.
2. Workspace thay đổi mô hình theo thao tác; bộ đánh giá local tạo phản hồi.
3. Tiến độ và sự kiện chờ gửi được lưu trên máy.
4. Ở bản cloud, controller gửi dữ liệu khi đủ điều kiện; backend xác nhận kết quả hỗ trợ trong catalog server.
5. Giao diện thể hiện riêng trạng thái lưu local, đồng bộ và XP đã xác nhận.

Nếu chưa có phản hồi thành công từ server, chỉ kết luận kết quả đã lưu local hoặc đang chờ gửi theo trạng thái thật.

### Bảo vệ dữ liệu và tính nhất quán

Thiết kế có kiểm tra chủ sở hữu tài khoản, cơ chế revision để xử lý xung đột, định danh yêu cầu để retry và tránh thưởng lặp. Khôi phục backup tạo nhánh hồ sơ riêng nhằm giữ bản local. Những cơ chế này cần được kiểm thử theo tình huống, không nên mô tả là bảo đảm tuyệt đối mọi lỗi mạng đều không mất dữ liệu.

Khóa dịch vụ có quyền cao không được đưa vào ứng dụng. Credential của engine tách khỏi snapshot học tập. Trong demo không chiếu mật khẩu, OTP, token hoặc khóa truy cập.

### Công nghệ và nguồn triển khai

Flutter và Dart cho ứng dụng; SharedPreferences cho trạng thái local; Flutter Secure Storage cho credential; Supabase cho tài khoản và dữ liệu cloud; HTTP adapter cho engine. Phiên bản app xác nhận từ pubspec.yaml là 1.3.2+6. SDK ghi trong README là Flutter 3.47.4 và Dart 3.13.3.

<!-- PAGEBREAK -->

## Kiểm thử và giới hạn bằng chứng

### Mốc kiểm thử được ghi nhận

VALIDATION.md ghi nhận ngày 28/10/2026: analyze đạt, 197 Flutter tests đạt, các nhóm kiểm tra tương tác/độ sâu/hình học đạt 50 / 2.491 / 17.552 checks và 729 ca parity baseline đạt. Bản debug có cloud được ghi nhận build, cài và mở trên Pixel 9. Đây là kết quả lịch sử theo phạm vi được ghi, không phải lần chạy mới trên điện thoại ngày demo.

Tài liệu cũng ghi nhận ngày 26/10/2026, bản 1.3.1 có integration test với Supabase thật trên emulator: đăng nhập, hoàn thành Logic, xác nhận 30 XP, retry không thưởng thêm, xử lý xung đột metadata, backup/restore và logout. Không gán kết quả đó cho mọi thiết bị hoặc mọi bản APK.

### Điều kiện chấp nhận cho buổi demo

- Mở đúng APK, vào được hồ sơ demo và danh mục Logic.
- Làm sai rồi sửa đúng một bài; phản hồi khớp với mô hình.
- Thoát khi đang học và Học tiếp trở lại đúng hoạt động.
- Nếu trình bày hoàn thành/XP, dùng hồ sơ hoàn thành lần đầu hoặc nói rõ hồ sơ chuẩn bị trước.
- Nếu trình bày cloud, quan sát trạng thái xác nhận thật và phân biệt với XP local.
- Không lỗi chặn thao tác trong lần tổng duyệt trên đúng thiết bị chiếu.

### Rủi ro và hướng phát triển

Ưu tiên tiếp theo là kiểm tra APK trên điện thoại vật lý và mạng thực tế, phát hành 18 hoạt động còn lại lên server, kiểm tra hộp thư/recovery, kiểm chứng provider AI và môi trường thực thi code, cải thiện trải nghiệm nhiều thiết bị. iOS và các runtime/khả năng native chưa được xác minh cần một đợt kiểm thử riêng.

### Tài liệu bàn giao kèm hồ sơ

Nguồn chính tại D:\Brilliant Clone\brilliant_mobile\repo-history:

- README.md và pubspec.yaml: mục tiêu, chạy dự án, công nghệ và phiên bản.
- VALIDATION.md và .github\workflows\verify.yml: bằng chứng có ngày và quy trình kiểm tra.
- docs\HUONG_DAN_DEMO.md: luồng demo và đáp án Logic.
- docs\ENGINE_ARCHITECTURE.md: kiến trúc engine và ranh giới tích hợp.
- docs\PHONE_READINESS.md: bằng chứng Android 1.3.1 và giới hạn thiết bị.
- lib\learning_catalog.dart, lib\learning_store.dart: catalog hiện tại và quy tắc XP local.
- docs\MOBILE_CLOUD_BACKUP.md và docs\LEARNING_SERVER_API.md: tài liệu kỹ thuật để mở khi có câu hỏi sâu.

Kết luận trình bày: sản phẩm đã có luồng học tương tác và lưu tiến độ; cloud và engine mở rộng trải nghiệm với các điều kiện cấu hình, phát hành nội dung và kiểm thử được nêu rõ.
