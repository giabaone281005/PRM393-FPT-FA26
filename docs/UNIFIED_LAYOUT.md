# Đồng bộ bố cục — 24/10/2026

## Khung dùng chung

- `AppLayout`: khung nội dung tối đa 720px, lề ngang 24px, nhịp khoảng cách 8/16/24/32px, thẻ lớn bo 24px và ô nhỏ bo 16px.
- `AppPageHeader`: header cao 64px, trục nội dung trùng với body; back/title/menu cùng một hàng và font tiêu đề thống nhất. Thanh điều hướng được giới hạn cùng chiều rộng trên màn lớn.
- `AppPageBody` / `AppContentFrame`: dùng lại ở màn chủ đề, lesson, hoàn thành và trang thông tin; các màn home/profile/settings/onboarding dùng chung token khung và padding.
- Các CTA chính trong luồng app có chiều rộng thống nhất tối đa 320px, tự thu nhỏ theo màn hình. Lớp `PrimaryAction` vẫn hỗ trợ nút ôm nhãn ở nơi khác.
- Title lớn 32px, heading 24px, section title 20/16px. Home và lesson căn nội dung theo trục trái; minh họa và màn chúc mừng giữ căn giữa theo vai trò.
- Nền, màu nhấn, chip chọn, progress, nút phụ, ô nhập, sheet và dialog theo tùy chỉnh đã lưu. Màu dữ liệu của mô hình và icon vẫn giữ ý nghĩa học tập.

## REA

Scenario khai báo trên `https://brilliant.org/courses/`, Chrome headless, viewport 390×844, chờ 1 giây, thu DOM và accessibility. Có các token cấu trúc `panda-px_6`, `md:panda-px_8`, `panda-gap_8`, `panda-max-w_1216px`. Dùng chúng để đối chiếu tư duy khung/lề/nhịp dùng chung; thông số 720/24/64/320 ở trên là lựa chọn thiết kế cho Matlingo, không tuyên bố đo được chúng từ home riêng tư của Brilliant.

Evidence: `ev_25d1ceb4769a1105075ee5d3a14cf2f309c81c46eae93cab40c91ade5fb05ea4`; [tóm tắt](evidence/unified-layout-rea.json).

## Xác minh

69/69 kiểm thử đạt, phân tích mã không có vấn đề. Các kiểm thử bao gồm 24 lesson ở 320px, hoàn thành 8 chủ đề, chat/card không tràn ở 280–1024px, font lớn, các menu và lưu/khôi phục. Đã mở và xem render của home, topic, profile, cài đặt, lesson và hoàn thành.

Khi mở rộng kiểm tra chuyển màn đã phát hiện `saveProgress` phát thông báo trong lúc lesson đang unmount. Lưu cuối phiên được chuyển sang microtask sau khi tree mở khóa; vẫn giữ đồng hồ, snapshot và kiểm tra hồ sơ sở hữu.

Ảnh: [Home](home-resume-minimal.png), [Chủ đề](topics-grouped.png), [Hồ sơ](profile-daily.png), [Topic](aligned-topic.png), [Lesson](aligned-lesson.png), [Hoàn thành](aligned-completion.png), [Cài đặt](appearance-settings.png).
