import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/core/services/voice/speech_answer_normalizer.dart';

void main() {
  group('SpeechAnswerNormalizer - Number Parsing', () {
    test('parses direct digits', () {
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('5'), 5);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('12'), 12);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('100'), 100);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber(' 42 '), 42);
    });

    test('parses single word Vietnamese numbers', () {
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('không'), 0);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('một'), 1);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('hai'), 2);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('ba'), 3);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('bốn'), 4);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('tư'), 4);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('năm'), 5);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('sáu'), 6);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('bảy'), 7);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('bẩy'), 7);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('tám'), 8);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('chín'), 9);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('mười'), 10);
    });

    test('parses compound numbers (teens and tens)', () {
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('mười một'), 11);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('mười hai'), 12);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('mười lăm'), 15);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('hai mươi'), 20);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('hai mươi lăm'), 25);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('ba mươi tư'), 34);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('bốn mươi lăm'), 45);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('một trăm'), 100);
    });

    test('strips conversational prefixes used by kids', () {
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('bằng năm'), 5);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('kết quả là 12'), 12);
      expect(
        SpeechAnswerNormalizer.parseVietnameseNumber('kết quả bằng ba'),
        3,
      );
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('bé chọn 8'), 8);
      expect(
        SpeechAnswerNormalizer.parseVietnameseNumber('con chọn mười lăm'),
        15,
      );
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('đáp án là sáu'), 6);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('có 4 quả'), 4);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('tổng là mười'), 10);
    });

    test('returns null on invalid or non-numeric speech', () {
      expect(SpeechAnswerNormalizer.parseVietnameseNumber(''), isNull);
      expect(SpeechAnswerNormalizer.parseVietnameseNumber('   '), isNull);
      expect(
        SpeechAnswerNormalizer.parseVietnameseNumber('con không biết'),
        isNull,
      );
      expect(
        SpeechAnswerNormalizer.parseVietnameseNumber('xin chào bạn cú'),
        isNull,
      );
    });
  });

  group('SpeechAnswerNormalizer - Option Letter Matching', () {
    test('matches A, B, C, D directly or with prefixes', () {
      expect(SpeechAnswerNormalizer.matchOptionLetter('A'), 0);
      expect(SpeechAnswerNormalizer.matchOptionLetter('b'), 1);
      expect(SpeechAnswerNormalizer.matchOptionLetter('đáp án C'), 2);
      expect(SpeechAnswerNormalizer.matchOptionLetter('chọn D'), 3);
      expect(SpeechAnswerNormalizer.matchOptionLetter('câu a'), 0);
      expect(SpeechAnswerNormalizer.matchOptionLetter('cháu chọn câu B'), 1);
    });

    test('returns null when no option letter is mentioned', () {
      expect(SpeechAnswerNormalizer.matchOptionLetter('năm quả táo'), isNull);
      expect(SpeechAnswerNormalizer.matchOptionLetter('bằng 15'), isNull);
    });
  });

  group('SpeechAnswerNormalizer - Options Matching', () {
    test('matches option letter with options list', () {
      final options = ['3 quả', '5 quả', '6 quả', '8 quả'];
      expect(
        SpeechAnswerNormalizer.matchAgainstOptions('đáp án A', options),
        '3 quả',
      );
      expect(
        SpeechAnswerNormalizer.matchAgainstOptions('câu B', options),
        '5 quả',
      );
      expect(SpeechAnswerNormalizer.matchAgainstOptions('C', options), '6 quả');
      expect(
        SpeechAnswerNormalizer.matchAgainstOptions('chọn D', options),
        '8 quả',
      );
    });

    test('matches exact option text ignoring case and punctuation', () {
      final options = ['3 quả', '5 quả', '6 quả', '8 quả'];
      expect(
        SpeechAnswerNormalizer.matchAgainstOptions('5 quả', options),
        '5 quả',
      );
      expect(
        SpeechAnswerNormalizer.matchAgainstOptions('bé chọn 5 quả!', options),
        '5 quả',
      );
    });

    test('matches numeric speech with formatted option values', () {
      final options = ['3 quả', '5 quả', '6 quả', '8 quả'];
      // Bé nói "năm" -> khớp "5 quả"
      expect(
        SpeechAnswerNormalizer.matchAgainstOptions('năm', options),
        '5 quả',
      );
      expect(
        SpeechAnswerNormalizer.matchAgainstOptions('bằng 8', options),
        '8 quả',
      );
      expect(
        SpeechAnswerNormalizer.matchAgainstOptions('ba', options),
        '3 quả',
      );
    });

    test('matches numeric string list', () {
      final options = ['12', '15', '18', '20'];
      expect(
        SpeechAnswerNormalizer.matchAgainstOptions('mười lăm', options),
        '15',
      );
      expect(SpeechAnswerNormalizer.matchAgainstOptions('18', options), '18');
      expect(
        SpeechAnswerNormalizer.matchAgainstOptions('đáp án là 20', options),
        '20',
      );
    });

    test('matches numeric integer list', () {
      final options = [3, 4, 5, 6];
      expect(SpeechAnswerNormalizer.matchAgainstOptions('bốn', options), 4);
      expect(SpeechAnswerNormalizer.matchAgainstOptions('5', options), 5);
      expect(
        SpeechAnswerNormalizer.matchAgainstOptions('kết quả là sáu', options),
        6,
      );
    });

    test('returns null when no option matches unambiguously', () {
      final options = ['12 cm²', '15 cm²', '18 cm²', '20 cm²'];
      expect(
        SpeechAnswerNormalizer.matchAgainstOptions('chín quả chuối', options),
        isNull,
      );
      expect(
        SpeechAnswerNormalizer.matchAgainstOptions('không biết nữa', options),
        isNull,
      );
    });
  });

  group('SpeechAnswerNormalizer - resolveSpokenAnswer', () {
    test('resolves dragCounters integer count', () {
      expect(
        SpeechAnswerNormalizer.resolveSpokenAnswer(
          speech: 'ba quả táo',
          expectsInteger: true,
        ),
        3,
      );
      expect(
        SpeechAnswerNormalizer.resolveSpokenAnswer(
          speech: 'bằng 5',
          expectsInteger: true,
        ),
        5,
      );
    });

    test('resolves word problem options with fallback', () {
      final options = ['10 học sinh', '12 học sinh', '15 học sinh'];
      expect(
        SpeechAnswerNormalizer.resolveSpokenAnswer(
          speech: 'mười hai học sinh',
          options: options,
        ),
        '12 học sinh',
      );
    });
  });
}
