/// Lớp chuẩn hóa và ánh xạ kết quả nhận diện giọng nói sang giá trị đáp án phù hợp
/// với các dạng câu hỏi trong MathLingo (số, lựa chọn trắc nghiệm, đếm đồ vật).
class SpeechAnswerNormalizer {
  SpeechAnswerNormalizer._();

  static final Map<String, int> _vietnameseUnitNumbers = {
    'không': 0,
    'khong': 0,
    'dzo': 0,
    'zezo': 0,
    'zê rô': 0,
    'một': 1,
    'mot': 1,
    'mốt': 1,
    'hai': 2,
    'ba': 3,
    'bốn': 4,
    'bon': 4,
    'tư': 4,
    'tu': 4,
    'năm': 5,
    'nam': 5,
    'lăm': 5,
    'nhăm': 5,
    'sáu': 6,
    'sau': 6,
    'bảy': 7,
    'bay': 7,
    'bẩy': 7,
    'tám': 8,
    'tam': 8,
    'chín': 9,
    'chin': 9,
    'mười': 10,
    'muoi': 10,
    'mươi': 10,
  };

  /// Chuẩn hóa chuỗi văn bản: chữ thường, xóa dấu câu dư thừa, chuẩn hóa khoảng trắng
  static String cleanText(String input) {
    if (input.trim().isEmpty) return '';
    var text = input.trim().toLowerCase();
    // Bỏ các ký tự dấu câu thường gặp ở cuối hoặc giữa câu nhận diện
    text = text.replaceAll(RegExp(r'[\.,\?!:;_\-"\(\)]'), ' ');
    // Chuẩn hóa nhiều dấu cách thành một
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  /// Loại bỏ các tiền tố nói tự nhiên của trẻ em:
  /// ví dụ: "bằng 5", "kết quả là 5", "cháu chọn đáp án a", "bé nghĩ là 3"
  static String stripCommonPrefixes(String input) {
    var text = cleanText(input);
    final prefixes = [
      'kết quả là',
      'kết quả bằng',
      'kết quả',
      'đáp án là',
      'đáp án của con là',
      'đáp án của bé là',
      'đáp án',
      'cháu chọn đáp án',
      'con chọn đáp án',
      'bé chọn đáp án',
      'cháu chọn câu',
      'con chọn câu',
      'bé chọn câu',
      'cháu chọn',
      'con chọn',
      'bé chọn',
      'chọn đáp án',
      'chọn câu',
      'chọn',
      'câu trả lời là',
      'câu trả lời',
      'câu',
      'là bằng',
      'bằng',
      'là',
      'có tất cả',
      'có',
      'tổng là',
      'hiệu là',
      'tích là',
      'thương là',
    ];

    for (final p in prefixes) {
      if (text.startsWith('$p ')) {
        text = text.substring(p.length).trim();
        break;
      }
    }
    return text;
  }

  /// Chuyển đổi từ số tiếng Việt (0 đến 999) hoặc chuỗi số sang số nguyên int.
  /// Hỗ trợ cả:
  /// - Chữ số: "5", "12", "100"
  /// - Từ đơn: "năm" -> 5, "mười" -> 10, "mười hai" -> 12, "hai mươi" -> 20, "hai mươi lăm" -> 25
  /// - Hàng trăm: "một trăm", "hai trăm ba mươi"
  static int? parseVietnameseNumber(String input) {
    final cleaned = stripCommonPrefixes(input);
    if (cleaned.isEmpty) return null;

    // Loại bỏ các cụm từ thể hiện không biết đáp án
    const unknownPhrases = [
      'không biết',
      'chưa biết',
      'không rõ',
      'chịu thôi',
      'không hiểu',
      'chịu rồi',
    ];
    for (final phrase in unknownPhrases) {
      if (cleaned.contains(phrase)) return null;
    }

    // Nếu toàn bộ là chữ số
    final directInt = int.tryParse(cleaned);
    if (directInt != null) return directInt;

    // Nếu chuỗi bắt đầu bằng chữ số (ví dụ: "5 quả", "12 cm") -> lấy số đầu tiên
    final leadingDigitsMatch = RegExp(r'^(\d+)\b').firstMatch(cleaned);
    if (leadingDigitsMatch != null) {
      return int.tryParse(leadingDigitsMatch.group(1)!);
    }

    final words = cleaned.split(' ');
    int total = 0;
    int current = 0;
    bool foundAnyNumber = false;

    int i = 0;
    while (i < words.length) {
      final w = words[i];

      // Kiểm tra chữ số riêng lẻ trong danh sách từ (ví dụ "số 5")
      final digit = int.tryParse(w);
      if (digit != null) {
        return digit;
      }

      if (w == 'trăm' || w == 'tram') {
        foundAnyNumber = true;
        if (current == 0) current = 1;
        total += current * 100;
        current = 0;
      } else if (w == 'mười' || w == 'muoi') {
        foundAnyNumber = true;
        if (current == 0) {
          current = 10;
        } else {
          current = current * 10;
        }
      } else if (w == 'mươi') {
        foundAnyNumber = true;
        if (current > 0) {
          current = current * 10;
        }
      } else if (w == 'linh' || w == 'lẻ' || w == 'le') {
        // bỏ qua từ đệm linh/lẻ (ví dụ một trăm linh năm)
      } else if (_vietnameseUnitNumbers.containsKey(w)) {
        foundAnyNumber = true;
        final val = _vietnameseUnitNumbers[w]!;
        if (current == 10 && val < 10) {
          // ví dụ "mười lăm" -> 15
          current = 10 + val;
        } else if (current > 0 && current % 10 == 0 && val < 10) {
          // ví dụ "hai mươi lăm" -> 25
          current += val;
        } else {
          current += val;
        }
      } else {
        // Gặp từ không phải số: nếu đã parse được số trước đó thì dừng (ví dụ "năm quả táo")
        if (foundAnyNumber && (total > 0 || current > 0)) {
          break;
        }
      }
      i++;
    }

    total += current;
    return foundAnyNumber ? total : null;
  }

  /// Trích xuất chữ cái lựa chọn (A, B, C, D) từ giọng nói:
  /// ví dụ: "Đáp án A", "chọn A", "b", "câu c" -> 0, 1, 2, 3
  static int? matchOptionLetter(String speech) {
    final cleaned = cleanText(speech);
    if (cleaned.isEmpty) return null;

    final words = cleaned.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return null;

    // 1. Trường hợp bé chỉ nói duy nhất một chữ cái A, B, C, D
    if (words.length == 1) {
      final w = words.first.toLowerCase();
      if (w == 'a' || w == 'b' || w == 'c' || w == 'd') {
        return _letterToIndex(w);
      }
    }

    // 2. Duyệt các từ để tìm chữ cái a, b, c, d đứng riêng lẻ và đi kèm từ chỉ thị
    const indicatorWords = {
      'đáp',
      'án',
      'câu',
      'chọn',
      'mục',
      'phương',
    };

    for (int i = 0; i < words.length; i++) {
      final w = words[i].toLowerCase();
      if (w == 'a' || w == 'b' || w == 'c' || w == 'd') {
        // Kiểm tra xem từ trước đó có phải từ khóa chỉ thị trắc nghiệm không
        if (i > 0 && indicatorWords.contains(words[i - 1].toLowerCase())) {
          return _letterToIndex(w);
        }
      }
    }

    return null;
  }

  static int? _letterToIndex(String letter) {
    switch (letter) {
      case 'a':
        return 0;
      case 'b':
        return 1;
      case 'c':
        return 2;
      case 'd':
        return 3;
      default:
        return null;
    }
  }

  /// Khớp giọng nói của bé với danh sách các options của câu hỏi
  /// Trả về option trong danh sách nếu khớp tin cậy, ngược lại trả về null.
  static dynamic matchAgainstOptions(String speech, List<dynamic> options) {
    if (speech.trim().isEmpty || options.isEmpty) return null;

    // 1. Khớp theo ký tự A, B, C, D
    final letterIndex = matchOptionLetter(speech);
    if (letterIndex != null && letterIndex < options.length) {
      return options[letterIndex];
    }

    final cleanedSpeech = cleanText(speech);
    final strippedSpeech = stripCommonPrefixes(speech);
    final spokenNumber = parseVietnameseNumber(speech);

    // 2. Khớp chuỗi chính xác hoặc gần gũi với nội dung option
    for (final opt in options) {
      final optStr = cleanText(opt.toString());
      if (optStr.isEmpty) continue;

      if (cleanedSpeech == optStr || strippedSpeech == optStr) {
        return opt;
      }

      // Nếu option có tiền tố dạng "A. 15 quả" hoặc "A) 15"
      final strippedOpt = optStr.replaceAll(RegExp(r'^[a-d][\.\)]\s*'), '');
      if (strippedOpt == strippedSpeech || strippedOpt == cleanedSpeech) {
        return opt;
      }
    }

    // 3. Khớp theo giá trị số nếu có số
    if (spokenNumber != null) {
      // Tìm xem có option nào chứa số này không
      final matchedOptions = <dynamic>[];
      for (final opt in options) {
        if (opt is num && opt.toInt() == spokenNumber) {
          matchedOptions.add(opt);
          continue;
        }
        final optStr = opt.toString().trim();
        final optInt = int.tryParse(optStr);
        if (optInt == spokenNumber) {
          matchedOptions.add(opt);
          continue;
        }
        // Trường hợp option dạng "5 quả", "5 cm²"
        final matchLeading = RegExp(r'^(\d+)\b').firstMatch(optStr);
        if (matchLeading != null &&
            int.tryParse(matchLeading.group(1)!) == spokenNumber) {
          matchedOptions.add(opt);
        }
      }

      // Chỉ khớp nếu duy nhất 1 option khớp số này để đảm bảo an toàn, không đoán mơ hồ
      if (matchedOptions.length == 1) {
        return matchedOptions.first;
      }
    }

    return null;
  }

  /// Khớp đáp án giọng nói với yêu cầu của câu hỏi (số lượng, option, hoặc số nguyên).
  /// Trả về giá trị đáp án phù hợp để chuyển vào hàm submit `_answer(value)`.
  static dynamic resolveSpokenAnswer({
    required String speech,
    List<dynamic>? options,
    bool expectsInteger = false,
  }) {
    if (speech.trim().isEmpty) return null;

    // Nếu câu hỏi có danh sách options (WordProblem, Multiplication, AreaGrid)
    if (options != null && options.isNotEmpty) {
      final matched = matchAgainstOptions(speech, options);
      if (matched != null) return matched;
    }

    // Nếu câu hỏi yêu cầu số nguyên (DragCounters, hoặc nhập số)
    if (expectsInteger) {
      return parseVietnameseNumber(speech);
    }

    // Nếu câu hỏi dạng số nói chung
    final numVal = parseVietnameseNumber(speech);
    if (numVal != null) return numVal;

    // Nếu không khớp số và không khớp option, trả về chuỗi đã làm sạch
    final cleaned = stripCommonPrefixes(speech);
    return cleaned.isNotEmpty ? cleaned : null;
  }
}
