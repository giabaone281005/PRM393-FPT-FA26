# Matlingo Admin: chỉnh nội dung cũ và phát hành engine mobile

Ngày 2026-11-09. Repository: `D:\Brilliant Clone\brilliant_mobile\repo-history`.

## Cách dùng

1. Mở Matlingo Admin, tải lại bằng Ctrl+F5 và đăng nhập Admin.
2. Để sửa tên/mô tả/lĩnh vực/trạng thái/thứ tự chủ đề: vào **Studio soạn thảo**, chọn chủ đề, bấm **Chỉnh sửa chủ đề đang chọn**. Cũng có thể dùng tab **Quản lý chủ đề**. Lỗi lưu hiện ngay trong hộp thoại, giữ nội dung để thử lại; khi thành công có xác nhận và đọc lại danh sách.
3. Để thay mô hình hoặc thêm engine vào bài đóng gói cũ: mở bài → **Soạn lại bằng Studio và thêm engine** → duyệt thông báo → **Chuyển sang Studio**. Chỉnh tương tác và đáp án, thêm engine rồi phát hành.
4. Cài mobile **1.3.6+10** để nhận các bài Studio mới. Mobile cũ tiếp tục đọc release phù hợp, không nhận engine chưa hỗ trợ.

Backend đã kiểm tra cập nhật/đọc lại cả 21 chủ đề trong transaction hoàn tác. Chưa quan sát được đúng lỗi giao diện của người dùng vì công cụ browser/native chưa kết nối. Các test UI tái hiện được lỗi lưu bị che sau modal và kiểm tra luồng sửa lại/thử lại. Bản nháp của bài cũ giữ content version để nút chuyển Studio vẫn dùng được sau reload.

## 30 engine, gồm 9 engine mới

| Engine mới | Tương tác trên mobile | Thư viện dùng thực tế |
| --- | --- | --- |
| `numberLine` | Đặt điểm trên trục số bằng slider | Flutter + flutter_svg |
| `fractionBoard` | Chọn các phần bằng nhau để tô phân số | Flutter + flutter_svg |
| `numberInput` | Nhập số nguyên, chấm đúng kiểu và giá trị | Flutter |
| `quadraticGraph` | Điều chỉnh a, b, c của parabol | fl_chart + flutter_math_fork |
| `barChart` | Dựng các cột theo số liệu | fl_chart |
| `coordinatePoint` | Đặt điểm theo x, y | fl_chart |
| `vennDiagram` | Phân loại thẻ vào A, B, giao hoặc ngoài | flutter_svg + Flutter |
| `fractionCompare` | So sánh hai phân số bằng hình và phép nhân chéo | flutter_svg + flutter_math_fork |
| `shapeMatch` | Chọn hình giống mẫu SVG | flutter_svg |

Các package đã được cài, khóa phiên bản và tích hợp trong renderer Flutter:

- [fl_chart 1.3.0](https://pub.dev/packages/fl_chart/versions/1.3.0)
- [flutter_svg 2.3.2](https://pub.dev/packages/flutter_svg/versions/2.3.2)
- [flutter_math_fork 0.7.4](https://pub.dev/packages/flutter_math_fork/versions/0.7.4)

Công thức `$...$` trong tiêu đề, yêu cầu, story và lựa chọn slide được render trên mobile, có fallback cho TeX sai/quá dài. Hình SVG của engine sinh từ hình học cho phép, không tải mã thực thi từ CMS. Mỗi engine có Inspector, preview web, validator, trạng thái ban đầu và bộ chấm tương ứng ở Flutter/PostgreSQL. Không chấp nhận công thức JavaScript hay cờ `is_correct` từ client.

## Phát hành và lịch sử

Migration cộng thêm: `supabase/migrations/20261117000000_studio_mobile_engine_expansion.sql`. Đã áp dụng lên project `seoswmcldwwytdrfrrrb` với tên `studio_mobile_engine_expansion`, version remote **20261109160416**. Không chỉnh migration cũ, không xóa dữ liệu/schema.

Chuyển bài đóng gói thành Studio yêu cầu active Admin và `convert_from_version` khớp content version mới nhất. Thay đổi tạo version mới cho cùng activity ID. Cấu hình và đáp án cũ vẫn bất biến; phiên học đã bắt đầu giữ version cũ. Nội dung dẫn dắt được đưa sang story; cấu hình tương tác chỉ giữ nếu tương thích hợp đồng, nếu không dùng mẫu để Admin duyệt lại. Đây là bước soạn lại có xác nhận, không khẳng định mô hình mới tương đương tự động với mô hình cũ.

Release Studio mới có min_app_version 1.3.6. Backend tiếp tục chấm qua canonical attempt/completion và cấp XP phía máy chủ; client không tự ghi XP.

## Bằng chứng

- **313 Flutter tests qua**, gồm render cả 30 engine ở 320px/text scale 1.4, đối chiếu fixture, thao tác thực trên chart/SVG/input, trạng thái locked, khôi phục JSON và math rendering. Lượt chạy song song mặc định có một test cũ kết thúc không hoàn tất; chạy lại file riêng qua, rồi toàn bộ suite với concurrency=2 qua cả 313 test.
- **65 CMS tests qua**, gồm sửa chủ đề hiện có, lỗi trong modal và retry, chuyển bài cũ/undo, engine contracts, SQL thực trong PGlite, replay migration và conversion token stale/missing.
- `flutter analyze --no-pub`: không có vấn đề. Format các file chạm vào, `git diff --check` qua.
- Parity cũ: **1.577 expanded + 729 legacy** trường hợp trên 139 hoạt động qua. Standalone: **50 / 2.491 / 17.552** kiểm tra qua.
- Hosted `supabase/tests/mobile_engine_expansion_smoke.sql` qua: 9 engine trong một bài phát hành, lọc mobile 1.3.5/1.3.6, draft retry, đáp án sai/đúng, canonical XP, chặn user thường và chuyển một bài đóng gói thật sang Studio. Tất cả nằm trong transaction hoàn tác.
- Sau smoke test, baseline giữ nguyên: **21 chủ đề, 140 activity, 141 phiên bản, 20 phiên học, 82 lượt trả lời, tổng XP 60**; không còn fixture user, không có public SECURITY DEFINER.
- TypeScript/Vite và đóng gói Admin Web qua. APK debug cấu hình Supabase thật build qua; kiểm tra archive xác nhận chứa cloud URL và cả ba thư viện. Manifest: versionName **1.3.6**, versionCode **10**, minSdk **24**, targetSdk **36**.
- APK: `build/releases/Matlingo-1.3.6-cloud-debug.apk`; SHA-256 `9a2f20d29a6090f17ec54380732f6843a8b1c6b40a480b848ba36d0ff372bc6c`.

Chưa thử thao tác trên thiết bị thật hoặc trình duyệt thật vì browser/native automation không kết nối. APK là bản debug để cài thử, chưa phải bản ký production cho Play Store. Cảnh báo Kotlin của flutter_tts và [Auth leaked-password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) là hiện trạng có sẵn, không phát sinh từ thay đổi này.

## File thay đổi chính

Trong root tuyệt đối `D:\Brilliant Clone\brilliant_mobile\repo-history`:

- CMS: `cms/src/App.tsx`, `repository.ts`, `domain.ts`, `Studio.tsx`, `planner.ts`, `engine-contract.ts`, `engine-icons.ts`, `EnginePlayer.tsx`, `styles.css`; các file mới `extra-engines.ts`, `ExtraEngineInspector.tsx`, `ExtraEnginePlayer.tsx`, `lesson-conversion.ts` cùng test liên quan.
- Mobile: `lib/data/models/extra_slide_engines.dart`, `slide_engine_contract.dart`; `lib/experiments/extra_slide_workspace.dart`, `extended_slide_workspace.dart`, `lesson_rich_text.dart`, `slide_lesson_workspace.dart`; `lib/data/repositories/learning_repository.dart`, `pubspec.yaml`, `pubspec.lock`.
- Backend/test: migration mới, `supabase/tests/mobile_engine_expansion_smoke.sql`, `supabase/tests/fixtures/studio_engines.json`, `test/mobile_authoring_libraries_test.dart`.
- Tài liệu: tài liệu này, `VALIDATION.md`, `cms/README.md`, `docs/CMS_TINKERCAD_IMPLEMENTATION.md`.

Những thay đổi có sẵn khác trong workspace được giữ nguyên.
