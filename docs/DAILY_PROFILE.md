# Hồ sơ tối giản — 24/10/2026

Trang Hồ sơ giữ tên, nhịp học, hai số cho ngày được chọn (thời gian học và số phiên hoàn thành), cùng 7 ngày gần nhất. Chạm một ngày để xem lại số liệu. Lược bỏ đoạn giới thiệu dài; thành tựu và lịch sử chi tiết vẫn ở Chủ đề.

`dailyActivity` được lưu riêng theo hồ sơ trong snapshot học tập hiện có. Mỗi bản nháp chứa `activeMsByDay`; lúc lưu, store chỉ cộng phần tăng so với bản nháp đã giữ. Hoàn thành cộng một phiên và XP lần đầu, không cộng lại phần thời gian đã tự lưu. Khi ghi hoàn thành thất bại, dữ liệu ngày cũng quay về snapshot trước khi hoàn thành.

Đồng hồ chỉ ghi thời gian lesson ở foreground, dừng khi app chuyển nền và chia khoảng đo qua nửa đêm theo lịch thiết bị. Dữ liệu tổng hợp ngày không bị giới hạn bởi 100 bản ghi lịch sử. Bài đang làm cũng có thời gian được ghi, không cần chờ hoàn thành.

Với dữ liệu cũ, chỉ khôi phục được ngày hoàn thành và số phiên từ lịch sử còn giữ. Không suy ra thời gian mỗi ngày từ tổng thời gian phiên nhiều ngày; ô thời gian hiển thị “—” nếu ngày cũ chưa có dữ liệu đo. Các phiên từ bản mới trở đi được ghi đầy đủ.

Kiểm chứng: chia thời gian qua nửa đêm, tự lưu lặp không cộng trùng, hoàn thành/ôn tập, khôi phục store, tách hồ sơ, rollback khi ghi lỗi và chọn ngày ở 280px/cỡ chữ 130%. Đã render và xem [Hồ sơ mẫu](profile-daily.png).
