import 'experiment_model.dart';
import 'solid_model.dart';
import 'space_guidance.dart';

final solidExperiments = <String, List<ExperimentSpec>>{
  'geography': [
    ExperimentSpec(
      id: 'geography-globe-grid',
      evaluator: (d) => evaluateSpace('geography-globe-grid', d),
      title: 'Tìm đường trên quả địa cầu',
      stage: 'Khám phá 3D',
      mechanism: 'globeExplorer',
      prompt: 'Đặt điểm tại 15° Bắc, 105° Đông trên quả địa cầu. Xoay để nhìn quanh, rồi chạm bề mặt hoặc điều chỉnh tọa độ.',
      hint: 'Vĩ độ Bắc nằm phía bắc xích đạo. Kinh độ Đông được đo về phía đông từ kinh tuyến gốc 0°.',
      explanation: 'Vĩ độ đo vị trí Bắc–Nam; kinh độ đo vị trí Đông–Tây. Xoay quả địa cầu chỉ đổi góc nhìn, không đổi tọa độ điểm.',
      initial: {'latitude': 0, 'longitude': 0},
      validator: (d) =>
          d['latitude'] is int &&
          d['longitude'] is int &&
          d['latitude'] == 15 &&
          d['longitude'] == 105,
    ),
    ExperimentSpec(
      id: 'geography-rock-layers',
      evaluator: (d) => evaluateSpace('geography-rock-layers', d),
      title: 'Đọc lịch sử trong lớp đất đá',
      stage: 'Vận dụng 3D',
      mechanism: 'strataExplorer',
      prompt: 'Các lớp trầm tích chưa bị đảo lộn. Sắp lớp có tuổi 10, 20 và 30 triệu năm từ trên xuống dưới, theo thứ tự hình thành.',
      hint: 'Trong chuỗi trầm tích không bị đảo lộn, lớp bên dưới hình thành trước lớp phủ lên trên.',
      explanation: 'Từ trên xuống: 10, 20, 30 triệu năm. Mô hình giả định các lớp lắng đọng liên tiếp, chưa bị biến dạng hoặc đảo lộn.',
      initial: {
        'layers': [30, 10, 20],
      },
      validator: (d) => validLayerOrder(d['layers']),
    ),
  ],
  'geometry': [
    ExperimentSpec(
      id: 'geometry-solid-volume',
      evaluator: (d) => evaluateSpace('geometry-solid-volume', d),
      title: 'Xưởng khối không gian',
      stage: 'Khám phá 3D',
      mechanism: 'solidExplorer',
      prompt: 'Tạo khối hộp có thể tích 12 đơn vị khối và diện tích bề mặt 32 đơn vị vuông. Xoay khối để quan sát các mặt.',
      hint: 'Thể tích là dài × cao × sâu. Thử ba kích thước có tích bằng 12 rồi so sánh tổng diện tích sáu mặt.',
      explanation: 'Khối có các cạnh 2, 2, 3 thỏa V = 12 và S = 2 × (4 + 6 + 6) = 32. Đổi hướng khối không đổi hai đại lượng này.',
      initial: {'width': 2, 'height': 2, 'depth': 2},
      validator: (d) =>
          validSolidState(d) && solidVolume(d) == 12 && solidSurface(d) == 32,
    ),
  ],
  'algebra': [
    ExperimentSpec(
      id: 'algebra-solid-relation',
      evaluator: (d) => evaluateSpace('algebra-solid-relation', d),
      title: 'Một khối, ba quan hệ',
      stage: 'Vận dụng 3D',
      mechanism: 'solidExplorer',
      prompt: 'Dựng khối hộp có thể tích 16 đơn vị khối. Chiều dài gấp đôi chiều cao; chiều sâu bằng chiều cao.',
      hint: 'Cho chiều cao và chiều sâu bằng nhau trước. Mỗi khi đổi chiều cao, chiều dài cần thay đổi thế nào?',
      explanation: 'Cao = sâu = 2 và dài = 4: thể tích là 4 × 2 × 2 = 16. Mô hình phải thỏa cả thể tích lẫn quan hệ giữa các cạnh.',
      initial: {'width': 2, 'height': 2, 'depth': 2},
      validator: (d) =>
          validSolidState(d) &&
          solidVolume(d) == 16 &&
          d['width'] == 2 * d['height'] &&
          d['depth'] == d['height'],
    ),
  ],
};
