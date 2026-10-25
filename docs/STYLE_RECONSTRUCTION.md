# Font, giao diện và bảng màu theo REA

Ngày 23/10/2026. Đối tượng: website công khai https://brilliant.org/ ở viewport
390 × 844. Chưa đối chiếu APK/IPA hoặc giao diện sau đăng nhập của Brilliant.

## Bằng chứng

- Landing DOM và network: `ev_0adb12e44565369d41cfc596f8fe71ad4b2c2eb465cb2764670731bb6cab24d1`.
- Luồng learner → motivation → voice → visual help:
  `ev_d93e6bbf3ad8b336142b4c7bf48800c31fae3186e1688fb5ec954beef683f84a`.
  REA chủ động thực hiện các thao tác khai báo, không đăng nhập/tạo tài khoản.
- App Flutter mới, mở trang chủ → khóa → bài học:
  `ev_6ada3bf2dc52572fc5e35e6962f0bf6df02922e2ff3c386b4f989c6628ebb136`.
  Đã bật accessibility bằng Enter, rồi click các nút bằng role/name. Không có
  page-error được ghi nhận trong cửa sổ này.
- Bundle đầy đủ: `evidence/style-rea-bundle.json`.
- CSS gốc, DOM, font WOFF2 gốc và manifest SHA-256: `evidence/styles/`.

## Font: xác minh từ @font-face, không đoán từ ảnh

| Vai trò | CSS nguồn | App Flutter |
|---|---|---|
| Nội dung và tiêu đề bài | CoFo Brilliant | CofoBrilliant, nhúng 400/500/700 và italic |
| Display/marketing | CoFo Robert | CofoRobert, nhúng 500 |
| Code/monospace | Source Code Pro | SourceCodePro, nhúng 400, sẵn cho nội dung mã |
| Ký tự tiếng Việt còn thiếu | Font Cofo nguồn không bao phủ đủ | NotoSans 400/500/700 cho body; NotoSerif 500 cho display |

FontTools giải nén WOFF2 sang TTF, giữ outline/font metadata. Không vẽ lại glyph.
Kiểm tra cmap cho thấy font nguồn thiếu ơ, ư và một số chữ có dấu. Các ký tự
tiếng Việt xuất hiện trong mã ứng dụng đều được bao phủ sau khi thêm Noto Sans.
Vì vậy chữ tiếng Việt không thể giống tuyệt đối một font nguồn không có glyph đó.
TextPainter của nhãn đồ thị cũng chỉ định cùng family/fallback với giao diện.
NotoSerif được chọn riêng cho Cofo Robert để tránh trộn chữ có chân và không chân
ở tiêu đề tiếng Việt. Đây là điều chỉnh của app, không phải font quan sát từ nguồn.

## Thông số trích từ CSS

| Thành phần | Giá trị nguồn đã dùng |
|---|---|
| Nền / chữ chính | bg.primary = #FFFFFF / text.primary = #000000 |
| Nền phụ | gray.50 = #F8F8F8 |
| Thanh tiến độ / đường viền | green.500 = #29CC57 / gray.200 = #E5E5E5 |
| Viền khối kéo | gray.300 = #CCCCCC |
| Chữ phụ | blackAlpha.700 trên trắng = #666666 |
| Nút chính | bg.inverse.secondary = gray.900 = #383838 |
| Bóng nút | elevation.shadow.cta.default = #000000; offset 4px |
| Thành công | green.100 = #EAFAEE |
| Lỗi | papaya.200 = #FFE1DB |
| Heading bài | heading.lg: Cofo Brilliant 24px / 700 / 1.25 / tracking 0 |
| Nội dung | body.base: 16px / 400 / 1.5 / tracking 0 |
| Chữ nút | ui.actions.base: 16px / 500 / 1.25 / tracking 0 |
| Display | display.2xl: Cofo Robert 36px / 500 / 1.1 / tracking -0.36px |
| Nút onboarding | Cao 48px, bo viên thuốc; margin mobile 20px |

Ảnh nguồn có nút #565656 và bóng #262626: đây là màu sau hover opacity 0.85
trên nền trắng trong kịch bản đã click. CSS/DOM cho thấy nút không disabled;
không lấy màu hover này làm màu nền mặc định của app.

Thanh tiến độ chuyển thành ba segment xanh cách 4px. Khay kéo trung tính,
token trắng viền xám, nền workspace trắng có viền và bóng nhẹ. Các màu khóa
học được đổi sang purple.200, blue.200, orange.200, green.200 của nguồn.
Theme dùng ColorScheme tường minh, không để Material tự sinh tông màu phụ.

## Xác minh và giới hạn

- `flutter analyze`: sạch.
- `flutter test`: 11 kiểm thử đều qua với font nhúng thật và theme mới,
  bao gồm 12 bước ở màn hình 320 × 640 và các thao tác kéo thả.
- Build web và APK debug thành công. APK cuối: 171.044.552 bytes.
- Đã xem ảnh render trang chủ và bài cân ở 390 × 844:
  `style-home.png`, `style-course.png`, `style-lesson.png`.
- Hai lần thử click placeholder accessibility trên web không thành công;
  dùng Enter đã mở đúng semantics và hoàn tất luồng xem trước. Các lần thất bại
  vẫn nằm trong evidence, không được tính là xác nhận luồng thành công.
- Font và token màu xác minh trực tiếp từ tài nguyên nguồn. Bố cục được điều chỉnh
  cho nội dung tiếng Việt và bài tương tác riêng; không tuyên bố khớp pixel toàn app.
- Tên Nảy, nội dung bài, cơ chế tương tác và dữ liệu cục bộ vẫn thuộc ứng dụng này.
  Không thêm lựa chọn trắc nghiệm từ màn diagnostic nguồn.
- Chưa build iOS hoặc kiểm tra trên thiết bị thật; chưa đo FPS.

## Checklist

- [x] Xác định family, weight và nguồn file font.
- [x] Xác định bảng màu light; không nhầm token dark hoặc màu hover.
- [x] Đối chiếu heading, body, CTA, progress, viền và khay tương tác.
- [x] Tích hợp font offline, fallback tiếng Việt, cập nhật custom painter.
- [x] Kiểm thử, xem ảnh render và build lại bản cài.
- [ ] Đối chiếu giao diện app native Brilliant: ngoài phạm vi bằng chứng website.
