# Matlingo Admin và chức năng Studio — 2026-11-09

Cập nhật mới nhất: mobile 1.3.6+10, tổng 30 engine, sửa chủ đề và chuyển bài đóng gói sang Studio. Xem `docs/MOBILE_ENGINE_EXPANSION.md` để biết migration, thư viện, APK và kiểm thử hiện tại.
Admin Web hiện mở ứng dụng React mới tại `/cms/`. Dashboard, đăng nhập, thư viện chủ đề/bài học và workspace được viết lại; không còn mở Flutter Admin hay composer cũ từ entry production. Các file Flutter Admin cũ được giữ làm nguồn tương thích cho kiểm thử và các import hiện có, không được launcher sử dụng.

## Chức năng

- Dashboard: tổng quan, tìm kiếm/phân trang người dùng, xem tiến độ đã xác minh, tạm khóa/mở lại tài khoản, tạo/sửa/lưu trữ chủ đề, thư viện bài học.
- Workspace bốn cột: kho engine phân nhóm, luồng slide kéo thả và nút sắp xếp bằng bàn phím, Inspector riêng, điện thoại mô phỏng cập nhật tức thì. Nhân bản, xóa, undo/redo, xuất JSON, tự lưu nháp và khôi phục theo tài khoản/bài học.
- 21 engine: `story`, `quiz`, `pairs`, `graph`, `solid3D`, `polygonVertices`, `symmetryMirror`, `tangramRotate`, `causalLab`, `balanceScale`, `robotRoute`, `loopBuilder`, `sequenceTiles`, `causalExperiment`, `strata3D`, `globe3D`, `resourceBudget`, `evidenceBoard`, `categorySort`, `clozeBank`, `matchPairs`.
- Gợi ý theo từ khóa tiếng Việt và lĩnh vực. Tạo bài từ khung bốn bước: trực giác, thử nghiệm, suy luận, thử thách. Nội dung mẫu cần được biên soạn trước khi phát hành.
- Quality Guard: cảnh báo khi hơn 50% tương tác trong chủ đề là quiz; cảnh báo tương đồng trên 70% với bài đã phát hành trong cùng chủ đề. Đo độ giống từ ngữ kết hợp cơ chế; đây là cảnh báo biên tập, không phải mô hình phát hiện trùng lặp ngữ nghĩa. Bản nháp của bài khác không che mất snapshot đã phát hành khi so sánh.
- Media: upload hoặc kéo thả PNG/JPEG/WebP/GIF/SVG, tối đa 5 MB. SVG được loại nội dung chủ động và chuyển thành PNG để mobile đọc được; minh họa có mô tả thay thế. Sandbox chỉ xem trước ảnh nội bộ; phát hành thật yêu cầu URL HTTPS.
- Gemini qua API `tutor-chat` hiện có, có duyệt nội dung trước khi chèn vào slide mới. UI mới không gọi bộ sinh cấu trúc bốn engine cũ.

## Backend và mobile

Migration mới duy nhất: `supabase/migrations/20261114000000_studio_tinkercad_v2.sql`, sau các migration hiện có. Không sửa migration cũ hoặc xóa bảng/dữ liệu.

Migration mở rộng validator, trạng thái ban đầu và bộ chấm khai báo; các quy tắc engine cũ giữ nguyên. Dùng RPC phát hành/revision/idempotency có sẵn, không ghi điểm từ client. Thêm `admin_studio_progress`, có kiểm tra active Admin server-side. Thêm bucket minh họa công khai `lesson-assets`: chỉ active Admin upload vào thư mục UID của mình, không có policy sửa/xóa; giữ URL của phiên bản bài đã xuất bản. Những bucket ảnh riêng tư cũ không bị đổi quyền. Nếu bucket cùng tên đã tồn tại dưới dạng private, migration dừng để tránh vô tình công khai dữ liệu.

Các engine mobile tái sử dụng `SpaceWorkspace`, `DiscoveryExperiment` và `CurriculumWorkspace`; thêm adapter và kiểm tra cấu hình. Kích thước khối 1–5, lưới đa giác 0–4, bản đồ robot 4×4 có đá tại (1,1); mirror, tangram và địa tầng là các mô hình cố định có mô tả rõ trong Inspector. Không tải mã tùy ý, không chạy công thức do Admin/AI nhập. Cấu hình không thể đạt mục tiêu bị từ chối.

Mobile được tăng lên **1.3.5+9** và gửi `app_version=1.3.5`. Release mới yêu cầu tối thiểu 1.3.5; mobile cũ không nhận các engine chưa hỗ trợ. Hợp đồng lưu vẫn là `slideLesson` schema 1/evaluator 4 với phần mở rộng cộng thêm; nội dung và lịch sử cũ được giữ nguyên. Phone simulator là renderer web theo cùng hợp đồng trạng thái/đáp án, không phải Android emulator hay xác nhận giống từng pixel với Flutter. Công thức `$...$` được render bằng KaTeX trên web và flutter_math_fork trên mobile 1.3.6.

## Chạy và đóng gói

Từ thư mục `cms/`: `npm ci`, `npm run dev`; mở `http://127.0.0.1:8090/cms/`. Có thể mở sandbox mà không đăng nhập. Cloud dùng cấu hình public hiện có hoặc `.env.local`; không có service-role/Gemini secret trong bundle.

Từ repository: chạy `tools/build_cms.ps1` để tạo `build/admin-web/cms/` cùng trang chuyển hướng tại `build/admin-web/index.html`. Phục vụ `build/admin-web` bằng static server. Chỉ có một giao diện Admin/CMS đang được launcher production mở.

Backend hosted `seoswmcldwwytdrfrrrb` đã đồng bộ ngày 2026-11-09 bằng ba migration: `studio_tinkercad_v2` (20261109144821), `admin_existing_lesson_editing` (20261109145137), `admin_metadata_compatibility` (20261109145308). Các nguồn local tương ứng có timestamp 20261114, 20261115 và 20261116; lịch sử đã đối chiếu theo tên/nội dung. Không chạy reset/push lại toàn bộ lịch sử.

Ứng dụng có tên **Matlingo Admin**, đăng nhập vào Tổng quan; Studio chỉ là tab soạn thảo. Bài hiện có được mở từ thư viện theo chủ đề. Tất cả bài sửa được tên, yêu cầu, giai đoạn, gợi ý, lời giải, thứ tự/trạng thái; bản nháp cũng lưu/khôi phục được. Bài `reasonedChoice` sửa được kiến thức, mã minh họa, nguồn, lựa chọn, lý do và đáp án. Với 18 bài trắc nghiệm đóng gói cũ, Admin cần chọn rõ đáp án và lý do trước khi phát hành; phiên bản mới dùng bộ chấm khai báo v3, bản gốc và các phiên học cũ được giữ nguyên. Các mô hình đóng gói khác giữ cấu hình/bộ chấm gốc, backend từ chối sửa cấu hình nhạy cảm nhưng vẫn chấp nhận payload metadata của client cũ.

Kiểm tra hosted trong transaction hoàn tác đã qua cho sửa bài trắc nghiệm có sẵn, sửa bài tương tác có sẵn, đồng bộ danh mục mobile, giữ nguyên phiên bản gốc, RLS/ownership, draft/retry/revision, đáp án đúng/sai và XP. Sau kiểm tra: 8 tài khoản, 20 chủ đề, 140 phiên bản, 20 phiên học, 82 lượt trả lời, 2 hoàn thành, tổng XP 60 — không đổi; không còn fixture người dùng. Security advisor không phát sinh lỗi mới; cảnh báo leaked-password protection từ trước vẫn còn (https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).

## Bằng chứng kiểm thử

- `flutter analyze`: không có vấn đề.
- Toàn bộ `flutter test --no-pub`: **289 test qua**, gồm render 21 engine ở 320px/text scale 1.4 và 18 test hợp đồng mới.
- `npm test`: **51 test qua**, gồm UI Studio/Dashboard, undo/redo, media validation/SVG sanitization, khôi phục, publication retry và repository authority.
- PostgreSQL thực trong PGlite, chỉ trong bộ nhớ: replay toàn migration, validator/evaluator/trạng thái ban đầu cho 17 engine mở rộng, publish thật theo revision, idempotency, bảo vệ nội dung đã phát hành, lọc release theo phiên bản app, RPC Admin và RLS Storage. Auth/Storage được mô phỏng ở lớp nền; không xác nhận cấu hình hosted bằng các test này.
- Bộ fixture dùng chung `supabase/tests/fixtures/studio_engines.json` được CMS, Flutter và PostgreSQL đọc để đối chiếu đáp án đúng, sai và dữ liệu giả mạo.
- Parity: **1.577 expanded + 729 legacy** trường hợp trên 139 hoạt động qua. Standalone: **50**, **2.491**, **17.552** kiểm tra qua.
- Build TypeScript/Vite, APK debug và Flutter web launcher qua. Bundle được tách thành ứng dụng, cloud client và math renderer; build cuối không còn cảnh báo font/bundle.
- `git diff --check` qua. Các thay đổi có sẵn ngoài phạm vi được giữ lại.

Công cụ browser/native không kết nối được trong phiên này, nên chưa có kiểm tra giao diện bằng trình duyệt thật, ảnh chụp responsive, lượt đăng nhập/cloud upload/Gemini/publish qua giao diện hoặc thử nghiệm thiết bị vật lý. Không khẳng định những bước đó đã qua.

## Các nhóm file thay đổi trong lượt này

| Nhóm | Đường dẫn |
| --- | --- |
| Admin và CMS UI | `cms/src/App.tsx`, `Studio.tsx`, `styles.css`, `Player.tsx`, `EnginePlayer.tsx`, `engine-icons.ts` |
| Hợp đồng, gợi ý, media | `cms/src/domain.ts`, `engine-contract.ts`, `planner.ts`, `assets.ts`, `repository.ts` |
| Kiểm thử CMS/PostgreSQL | `cms/src/Studio.test.tsx`, `engine-contract.test.ts`, `assets.test.ts`, `postgres.test.ts`; thêm dependency PGlite đã khóa version trong `cms/package.json`, `cms/package-lock.json` và cấu hình chia bundle trong `cms/vite.config.ts` |
| Mobile/launcher | `lib/admin_main.dart`, `lib/data/models/slide_lesson.dart`, `slide_engine_contract.dart`, `lib/experiments/slide_lesson_workspace.dart`, `extended_slide_workspace.dart`, `lib/data/repositories/learning_repository.dart`, `pubspec.yaml` |
| Backend/test liên nền tảng | migration mới, `supabase/tests/fixtures/studio_engines.json`, `test/studio_engine_contract_test.dart`, điều chỉnh fixture bốn engine trong `test/slide_cms_test.dart` |
| Tài liệu | tài liệu này, `cms/README.md`, `VALIDATION.md`, trạng thái checklist trong `CMS_TINKERCAD_MASTER_PLAN.md` |
