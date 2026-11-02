// Curated product facts. Never accept app instructions or permissions from the client.
const answers = {
  account:
    "Trong bản có cloud, bạn đăng nhập hoặc đăng ký bằng email tại màn hình mở app. Nếu đăng ký cần xác nhận, nhập mã trong email; có thể dùng ‘Đã có mã xác nhận? Nhập mã’ khi mở lại app. Menu → Tài khoản & sao lưu cho biết tài khoản đang dùng. Không gửi mật khẩu hoặc mã xác nhận cho trợ lý.",
  recovery:
    "Nếu màn hình đăng nhập có ‘Quên mật khẩu’, chọn mục đó và làm theo mã email để đặt lại mật khẩu. Tính năng này chỉ hiện khi bản app đã bật hỗ trợ recovery. Nếu chưa có, liên hệ người quản lý ứng dụng; trợ lý không thể tự đổi mật khẩu cho bạn.",
  otp:
    "Hãy kiểm tra đúng email đăng ký, thư rác và mã mới nhất. App nhận mã 6–10 chữ số; ‘Gửi lại mã’ có thời gian chờ. Nếu đã đóng app, chọn ‘Đã có mã xác nhận? Nhập mã’. Email chưa đến cần kiểm tra dịch vụ gửi mail; trợ lý không thể đọc hộp thư hoặc bỏ qua xác nhận.",
  xp:
    "Matlingo ghi 30 XP local cho lần đầu hoàn thành đầy đủ một chủ đề. Ôn lại không nhận lại thưởng lần đầu. XP được máy chủ xác nhận hiển thị riêng và chỉ có khi bài hợp lệ được đồng bộ; backup hoặc câu trả lời của trợ lý không tự cấp XP.",
  backup:
    "Mỗi tài khoản có một tiến độ học. App tự lưu tiến độ lên server khi có mạng và tự tải tiến độ cũ khi bạn đăng nhập lại hoặc vào máy khác. Bạn không cần chọn hồ sơ, bấm sao lưu hay đồng bộ thủ công. Khi offline, dữ liệu được giữ trên máy và tự gửi lại sau; hãy chờ lưu xong trước khi đổi máy.",
  profile:
    "Tab Hồ sơ cho xem lịch sử, thời gian và XP theo ngày của tài khoản đang đăng nhập. Mỗi tài khoản chỉ dùng một hồ sơ học; không có bước chọn hay đổi nhiều hồ sơ. Đăng nhập lại cùng tài khoản để tiếp tục tiến độ cũ. Đăng xuất không phải là xóa tiến độ.",
  lessons:
    "Chọn tab Chủ đề, tìm hoặc lọc chủ đề rồi vào phòng thí nghiệm. Tự kéo, thả, xoay hoặc bật/tắt mô hình, bấm ‘Kiểm tra’, sửa nếu cần và chọn ‘Khám phá tiếp’. Hoàn thành đủ hoạt động rồi ‘Hoàn thành hành trình’. Trang chủ có ‘Học tiếp’ để trở lại bài đang dở.",
  topics:
    "Matlingo có 20 chủ đề và 139 hoạt động local, từ nền tảng đến thử thách: toán, logic, khoa học, dữ liệu, hình học, lập trình, mạch điện, xác suất, đại số, địa lý, tối ưu, triết học, hội họa, tiếng Anh, tiếng Việt, sinh học, hóa học, thiên văn, tài chính cá nhân và công dân số. Tab Chủ đề có tìm kiếm và gợi ý độ tuổi; độ tuổi không phải điều kiện khóa bài. Nội dung local và nội dung máy chủ đã phát hành có thể khác nhau; không phải mọi hoạt động đều đã có XP xác nhận từ server.",
  language:
    "Mở Chủ đề → Tiếng Anh trong cuộc sống để nghe mẫu, nghe chậm, ghép câu và luyện nói. Micro chỉ bật khi bạn bấm luyện nói; nhận dạng của thiết bị có thể cần mạng. Matlingo không lưu bản ghi âm; câu chữ được lưu cùng tiến độ. Có thể mở bản chữ hoặc nhập câu nếu không dùng âm thanh. Kết quả chỉ đối chiếu từ và thứ tự câu, không phải điểm chất lượng phát âm.",
  offline:
    "Sau khi đăng nhập và mở hồ sơ trên bản cloud, bạn có thể học các bài local khi mất mạng. Tiến độ được giữ trên máy và chờ gửi khi có mạng, app hoạt động lại. Đăng nhập lần đầu, sao lưu cloud và hỏi Gemini cần Internet. Không đảm bảo upload khi Android đã dừng app.",
  settings:
    "Mở Menu → Cài đặt để đổi giao diện, cỡ chữ và giảm chuyển động. Lựa chọn được lưu trên thiết bị. Gemini đã được cấu hình sẵn cho tài khoản đăng nhập trong bản cloud; bạn không cần nhập API key hay mở Engine học tập.",
  assistant:
    "Mình là Koji, trợ lý học tập trong Matlingo. Bạn có thể hỏi bài, xin gợi ý từng bước hoặc hỏi cách dùng app. Gemini được nối sẵn trong bản cloud sau khi đăng nhập. Mình không xem được dữ liệu riêng của tài khoản, không cấp XP và không thực hiện thao tác quản trị thay bạn.",
};

export const appGuide = Object.values(answers).join("\n");

export function answerAppQuestion(question: string): string | null {
  const text = question.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d").replace(/Đ/g, "D").toLowerCase()
    .replace(/[^a-z0-9 ]/g, " ").replace(/\s+/g, " ").trim();
  const has = (pattern: string) =>
    new RegExp(`\\b(?:${pattern})\\b`).test(text);
  // Match support intents, not arbitrary mentions in programming/math exercises.
  const support = has(
    "cach|lam sao|o dau|tai sao|vi sao|huong dan|la gi|bao nhieu|khong|loi|duoc tinh|matlingo|mathlingo|ung dung|app|toi muon|minh muon",
  );
  if (!support) return null;
  if (
    has("luyen noi|nghe noi|micro|phat am") &&
    has("app|matlingo|mathlingo|ung dung|tieng anh")
  ) {
    return answers.language;
  }
  if (has("quen mat khau|doi mat khau|reset password")) return answers.recovery;
  if (has("otp|ma xac nhan|email khong den|khong nhan duoc ma|gui lai ma")) {
    return answers.otp;
  }
  if (has("xp|diem thuong|tang diem|cong diem")) return answers.xp;
  if (has("sao luu|khoi phuc|backup|restore|dong bo|chuyen may")) {
    return answers.backup;
  }
  if (has("dang nhap|dang ky|tai khoan")) return answers.account;
  if (has("doi ho so|ho so|lich su|thoi gian hoc")) return answers.profile;
  if (has("bao nhieu chu de|danh sach chu de|co nhung chu de|cac chu de")) {
    return answers.topics;
  }
  if (has("offline|mat mang|khong co mang|khong co internet")) {
    return answers.offline;
  }
  if (has("cai dat|co chu|giam chuyen dong|api key|engine")) {
    return answers.settings;
  }
  if (has("cach hoc|hoc tiep|bat dau hoc|kiem tra dap an|hoan thanh bai")) {
    return answers.lessons;
  }
  if (has("koji|tro ly|gemini|ban la ai|app la gi|ung dung la gi")) {
    return answers.assistant;
  }
  return null;
}
