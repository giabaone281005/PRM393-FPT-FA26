import 'experiment_model.dart';
import 'fraction_evaluation.dart';

final diverseExperiments = <String, List<ExperimentSpec>>{
  'math': [
    ExperimentSpec(
      id: 'math-number-line',
      evaluator: evaluateFractionLine,
      skillIds: ['fractions.part-whole'],
      title: 'Phân số có một vị trí',
      stage: 'Vận dụng',
      mechanism: 'fractionNumberLine',
      prompt: 'Đặt điểm tại 3/4 đoạn đường từ 0 đến 1. Mỗi nấc là 1/8.',
      hint: 'Chia đoạn thành 4 phần bằng nhau rồi đi 3 phần. Hai nấc nhỏ tạo một phần tư.',
      explanation: '3/4 = 6/8. Phân số biểu diễn một vị trí trên trục số, không chỉ là phần tô của chiếc bánh.',
      initial: {'position': 0},
      validator: (d) => d['position'] is int && d['position'] == 6,
    ),
  ],
  'logic': [
    ExperimentSpec(
      id: 'logic-counterexample',
      title: 'Một trường hợp đủ để bác bỏ',
      stage: 'Thử thách',
      mechanism: 'logicalCounterexample',
      prompt: 'Có người nói: “Đèn A sáng thì đèn B luôn sáng”. Bật/tắt hai đèn để tạo một phản ví dụ.',
      hint: 'Muốn bác bỏ quy tắc, điều kiện đầu phải xảy ra nhưng kết luận không xảy ra.',
      explanation: 'A sáng và B tắt là phản ví dụ. Khi A tắt, trường hợp đó không bác bỏ mệnh đề “nếu A thì B”.',
      initial: {'a': false, 'b': false},
      validator: (d) => d['a'] == true && d['b'] == false,
    ),
  ],
  'data': [
    ExperimentSpec(
      id: 'data-median-outlier',
      title: 'Khi một điểm đi xa',
      stage: 'Thử thách',
      mechanism: 'outlierExplorer',
      prompt: 'Bốn điểm cố định là 1, 2, 3, 4. Kéo điểm cuối để trung bình lớn hơn trung vị ít nhất 1 đơn vị.',
      hint: 'Trung vị là điểm thứ ba sau sắp xếp. Quan sát xem điểm cuối ảnh hưởng đến tổng như thế nào.',
      explanation: 'Điểm cuối từ 10 trở lên làm trung bình ít nhất bằng 4, trong khi trung vị vẫn là 3. Một ngoại lệ có thể kéo trung bình đi xa.',
      initial: {'outlier': 5},
      validator: (d) =>
          d['outlier'] is int && d['outlier'] >= 10 && d['outlier'] <= 15,
    ),
  ],
};
