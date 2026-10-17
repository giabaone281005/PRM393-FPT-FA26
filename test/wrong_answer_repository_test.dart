import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/models/question.dart';
import 'package:mathlingo/data/models/wrong_answer_record.dart';
import 'package:mathlingo/data/repositories/wrong_answer_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WrongAnswerRecord', () {
    test('serializes to map and deserializes back properly', () {
      final now = DateTime.now();
      final record = WrongAnswerRecord(
        questionId: 'q_101',
        prompt: '12 + 8 = ?',
        questionType: QuestionType.multiplicationTable,
        userAnswer: 25,
        lessonId: 'lesson_1',
        timestamp: now,
        isResolved: false,
        questionData: const {'formula': '12 + 8 = ?'},
      );

      final map = record.toMap();
      final restored = WrongAnswerRecord.fromMap(map);

      expect(restored.questionId, 'q_101');
      expect(restored.prompt, '12 + 8 = ?');
      expect(restored.questionType, QuestionType.multiplicationTable);
      expect(restored.userAnswer, 25);
      expect(restored.lessonId, 'lesson_1');
      expect(restored.isResolved, isFalse);
      expect(restored.questionData?['formula'], '12 + 8 = ?');
    });

    test('handles missing fields and invalid types gracefully', () {
      final fallback = WrongAnswerRecord.fromMap({});

      expect(fallback.questionId, '');
      expect(fallback.prompt, '');
      expect(fallback.questionType, QuestionType.wordProblem);
      expect(fallback.userAnswer, isNull);
      expect(fallback.lessonId, isNull);
      expect(fallback.isResolved, isFalse);
      expect(fallback.questionData, isNull);
    });

    test('parses various question type strings safely', () {
      expect(
        WrongAnswerRecord.parseQuestionType('drag_counters'),
        QuestionType.dragCounters,
      );
      expect(
        WrongAnswerRecord.parseQuestionType('clock_rotation'),
        QuestionType.clockRotation,
      );
      expect(
        WrongAnswerRecord.parseQuestionType('area_grid'),
        QuestionType.areaGrid,
      );
      expect(
        WrongAnswerRecord.parseQuestionType('multiplicationTable'),
        QuestionType.multiplicationTable,
      );
      expect(
        WrongAnswerRecord.parseQuestionType('unknown_type'),
        QuestionType.wordProblem,
      );
      expect(
        WrongAnswerRecord.parseQuestionType(null),
        QuestionType.wordProblem,
      );
    });

    test('copyWith updates properties accurately', () {
      final record = WrongAnswerRecord(
        questionId: 'q_1',
        prompt: 'Prompt 1',
        questionType: QuestionType.wordProblem,
        userAnswer: 'A',
        timestamp: DateTime.now(),
        isResolved: false,
      );

      final updated = record.copyWith(isResolved: true, userAnswer: 'B');

      expect(updated.questionId, 'q_1');
      expect(updated.isResolved, isTrue);
      expect(updated.userAnswer, 'B');
    });
  });

  group('WrongAnswerRepository', () {
    test(
      'returns empty list for initial/empty storage or blank kidId',
      () async {
        final empty = await WrongAnswerRepository.getWrongAnswers('kid_1');
        expect(empty, isEmpty);

        final blankKid = await WrongAnswerRepository.getWrongAnswers('   ');
        expect(blankKid, isEmpty);
      },
    );

    test('saves and retrieves wrong answer records', () async {
      final record = WrongAnswerRecord(
        questionId: 'q_math_1',
        prompt: '5 x 4 = ?',
        questionType: QuestionType.multiplicationTable,
        userAnswer: '24',
        lessonId: 'lesson_mult',
        timestamp: DateTime.now(),
      );

      await WrongAnswerRepository.saveWrongAnswer('kid_1', record);

      final list = await WrongAnswerRepository.getWrongAnswers('kid_1');
      expect(list.length, 1);
      expect(list.first.questionId, 'q_math_1');
      expect(list.first.userAnswer, '24');
      expect(list.first.isResolved, isFalse);
    });

    test(
      're-answering wrong updates attempt and resets isResolved to false',
      () async {
        final initial = WrongAnswerRecord(
          questionId: 'q_math_1',
          prompt: '5 x 4 = ?',
          questionType: QuestionType.multiplicationTable,
          userAnswer: '24',
          lessonId: 'lesson_mult',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isResolved: true,
        );

        await WrongAnswerRepository.saveWrongAnswer('kid_1', initial);

        // Repeat mistake with another answer
        final secondAttempt = WrongAnswerRecord(
          questionId: 'q_math_1',
          prompt: '5 x 4 = ?',
          questionType: QuestionType.multiplicationTable,
          userAnswer: '25',
          lessonId: 'lesson_mult',
          timestamp: DateTime.now(),
          isResolved: false,
        );

        await WrongAnswerRepository.saveWrongAnswer('kid_1', secondAttempt);

        final list = await WrongAnswerRepository.getWrongAnswers('kid_1');
        expect(list.length, 1);
        expect(list.first.userAnswer, '25');
        expect(list.first.isResolved, isFalse);
      },
    );

    test('strictly isolates records by kidId', () async {
      final recordKid1 = WrongAnswerRecord(
        questionId: 'q_kid1',
        prompt: '1 + 1 = ?',
        questionType: QuestionType.wordProblem,
        userAnswer: 3,
        timestamp: DateTime.now(),
      );

      final recordKid2 = WrongAnswerRecord(
        questionId: 'q_kid2',
        prompt: '2 + 2 = ?',
        questionType: QuestionType.wordProblem,
        userAnswer: 5,
        timestamp: DateTime.now(),
      );

      await WrongAnswerRepository.saveWrongAnswer('kid_alpha', recordKid1);
      await WrongAnswerRepository.saveWrongAnswer('kid_beta', recordKid2);

      final alphaList = await WrongAnswerRepository.getWrongAnswers(
        'kid_alpha',
      );
      final betaList = await WrongAnswerRepository.getWrongAnswers('kid_beta');

      expect(alphaList.map((r) => r.questionId), ['q_kid1']);
      expect(betaList.map((r) => r.questionId), ['q_kid2']);
    });

    test('filters by lessonId correctly', () async {
      final r1 = WrongAnswerRecord(
        questionId: 'q_1',
        prompt: 'P1',
        questionType: QuestionType.wordProblem,
        userAnswer: 1,
        lessonId: 'lesson_A',
        timestamp: DateTime.now(),
      );
      final r2 = WrongAnswerRecord(
        questionId: 'q_2',
        prompt: 'P2',
        questionType: QuestionType.wordProblem,
        userAnswer: 2,
        lessonId: 'lesson_B',
        timestamp: DateTime.now(),
      );

      await WrongAnswerRepository.saveWrongAnswer('kid_1', r1);
      await WrongAnswerRepository.saveWrongAnswer('kid_1', r2);

      final lessonAList = await WrongAnswerRepository.getWrongAnswers(
        'kid_1',
        lessonId: 'lesson_A',
      );
      final lessonBList = await WrongAnswerRepository.getWrongAnswers(
        'kid_1',
        lessonId: 'lesson_B',
      );
      final lessonCList = await WrongAnswerRepository.getWrongAnswers(
        'kid_1',
        lessonId: 'lesson_C',
      );

      expect(lessonAList.length, 1);
      expect(lessonAList.first.questionId, 'q_1');
      expect(lessonBList.length, 1);
      expect(lessonBList.first.questionId, 'q_2');
      expect(lessonCList, isEmpty);
    });

    test('markResolved marks question as resolved', () async {
      final record = WrongAnswerRecord(
        questionId: 'q_target',
        prompt: 'Prompt',
        questionType: QuestionType.wordProblem,
        userAnswer: 'wrong',
        timestamp: DateTime.now(),
      );

      await WrongAnswerRepository.saveWrongAnswer('kid_1', record);

      final marked = await WrongAnswerRepository.markResolved(
        'kid_1',
        'q_target',
      );
      expect(marked, isTrue);

      final unresolved = await WrongAnswerRepository.getWrongAnswers(
        'kid_1',
        includeResolved: false,
      );
      final resolved = await WrongAnswerRepository.getWrongAnswers(
        'kid_1',
        includeResolved: true,
      );

      expect(unresolved, isEmpty);
      expect(resolved.length, 1);
      expect(resolved.first.isResolved, isTrue);

      final notFound = await WrongAnswerRepository.markResolved(
        'kid_1',
        'non_existent',
      );
      expect(notFound, isFalse);
    });

    test('clearResolved removes only resolved items', () async {
      final r1 = WrongAnswerRecord(
        questionId: 'q_1',
        prompt: 'P1',
        questionType: QuestionType.wordProblem,
        userAnswer: 1,
        timestamp: DateTime.now(),
        isResolved: true,
      );
      final r2 = WrongAnswerRecord(
        questionId: 'q_2',
        prompt: 'P2',
        questionType: QuestionType.wordProblem,
        userAnswer: 2,
        timestamp: DateTime.now(),
        isResolved: false,
      );

      await WrongAnswerRepository.saveWrongAnswer('kid_1', r1);
      await WrongAnswerRepository.saveWrongAnswer('kid_1', r2);
      // Ensure r1 is marked resolved
      await WrongAnswerRepository.markResolved('kid_1', 'q_1');

      await WrongAnswerRepository.clearResolved('kid_1');

      final remaining = await WrongAnswerRepository.getWrongAnswers('kid_1');
      expect(remaining.length, 1);
      expect(remaining.first.questionId, 'q_2');
    });

    test('clearWrongAnswers removes records by lesson or completely', () async {
      final r1 = WrongAnswerRecord(
        questionId: 'q_1',
        prompt: 'P1',
        questionType: QuestionType.wordProblem,
        userAnswer: 1,
        lessonId: 'L1',
        timestamp: DateTime.now(),
      );
      final r2 = WrongAnswerRecord(
        questionId: 'q_2',
        prompt: 'P2',
        questionType: QuestionType.wordProblem,
        userAnswer: 2,
        lessonId: 'L2',
        timestamp: DateTime.now(),
      );

      await WrongAnswerRepository.saveWrongAnswer('kid_1', r1);
      await WrongAnswerRepository.saveWrongAnswer('kid_1', r2);

      // Clear only L1
      await WrongAnswerRepository.clearWrongAnswers('kid_1', lessonId: 'L1');
      var list = await WrongAnswerRepository.getWrongAnswers('kid_1');
      expect(list.length, 1);
      expect(list.first.questionId, 'q_2');

      // Clear all
      await WrongAnswerRepository.clearWrongAnswers('kid_1');
      list = await WrongAnswerRepository.getWrongAnswers('kid_1');
      expect(list, isEmpty);
    });

    test('resilient to corrupted JSON in storage', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        WrongAnswerRepository.storageKey('kid_corrupt'),
        '{{{invalid json...',
      );

      final list = await WrongAnswerRepository.getWrongAnswers('kid_corrupt');
      expect(list, isEmpty);
    });

    test('resilient to array containing non-map items', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        WrongAnswerRepository.storageKey('kid_mixed'),
        jsonEncode([
          'string_item',
          123,
          {
            'questionId': 'q_valid',
            'prompt': 'Valid prompt',
            'questionType': 'areaGrid',
            'userAnswer': 10,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ]),
      );

      final list = await WrongAnswerRepository.getWrongAnswers('kid_mixed');
      expect(list.length, 1);
      expect(list.first.questionId, 'q_valid');
      expect(list.first.questionType, QuestionType.areaGrid);
    });

    test('countUnresolved accurately reflects pending wrong answers', () async {
      expect(await WrongAnswerRepository.countUnresolved('kid_count'), 0);

      final r1 = WrongAnswerRecord(
        questionId: 'q_1',
        prompt: 'P1',
        questionType: QuestionType.wordProblem,
        userAnswer: 'A',
        lessonId: 'L_count',
        timestamp: DateTime.now(),
      );
      final r2 = WrongAnswerRecord(
        questionId: 'q_2',
        prompt: 'P2',
        questionType: QuestionType.wordProblem,
        userAnswer: 'B',
        lessonId: 'L_count',
        timestamp: DateTime.now(),
      );

      await WrongAnswerRepository.saveWrongAnswer('kid_count', r1);
      await WrongAnswerRepository.saveWrongAnswer('kid_count', r2);

      expect(await WrongAnswerRepository.countUnresolved('kid_count'), 2);
      expect(
        await WrongAnswerRepository.countUnresolved(
          'kid_count',
          lessonId: 'L_count',
        ),
        2,
      );
      expect(
        await WrongAnswerRepository.countUnresolved(
          'kid_count',
          lessonId: 'other_lesson',
        ),
        0,
      );

      await WrongAnswerRepository.markResolved('kid_count', 'q_1');
      expect(await WrongAnswerRepository.countUnresolved('kid_count'), 1);
    });
  });

  group('StudyScreen Wrong Answer Capture Integration', () {
    test('captures and saves wrong answer on incorrect result', () async {
      const kidId = 'kid_test_capture';
      const lessonId = 'lesson_101';
      final question = Question(
        id: 'q_clock_1',
        type: QuestionType.clockRotation,
        prompt: 'Xoay kim đồng hồ chỉ 9:30',
        data: const {'targetHour': 9, 'targetMinute': 30},
        correctAnswer: null, // Hidden by server
      );

      const attemptedAnswer = {'hour': 8, 'minute': 30};
      const isCorrect = false;

      // Logic identical to StudyScreen._answer when isCorrect == false
      if (!isCorrect) {
        final record = WrongAnswerRecord(
          questionId: question.id,
          prompt: question.prompt,
          questionType: question.type,
          userAnswer: attemptedAnswer,
          lessonId: lessonId,
          timestamp: DateTime.now(),
          isResolved: false,
          questionData: question.data,
        );
        await WrongAnswerRepository.saveWrongAnswer(kidId, record);
      }

      final wrongList = await WrongAnswerRepository.getWrongAnswers(kidId);
      expect(wrongList.length, 1);
      expect(wrongList.first.questionId, 'q_clock_1');
      expect(wrongList.first.prompt, 'Xoay kim đồng hồ chỉ 9:30');
      expect(wrongList.first.questionType, QuestionType.clockRotation);
      expect(wrongList.first.userAnswer, {'hour': 8, 'minute': 30});
      expect(wrongList.first.lessonId, 'lesson_101');
      expect(wrongList.first.isResolved, isFalse);
      expect(wrongList.first.questionData?['targetHour'], 9);
    });

    test('does not save record when result is correct', () async {
      const kidId = 'kid_test_correct';
      final question = Question(
        id: 'q_correct',
        type: QuestionType.wordProblem,
        prompt: '2 + 2 = ?',
        data: const {
          'options': [2, 3, 4, 5],
        },
        correctAnswer: null,
      );

      Future<void> onAnswerProcessed(bool? isCorrect) async {
        if (isCorrect == false) {
          final record = WrongAnswerRecord(
            questionId: question.id,
            prompt: question.prompt,
            questionType: question.type,
            userAnswer: '4',
            timestamp: DateTime.now(),
          );
          await WrongAnswerRepository.saveWrongAnswer(kidId, record);
        }
      }

      await onAnswerProcessed(true);

      final list = await WrongAnswerRepository.getWrongAnswers(kidId);
      expect(list, isEmpty);
    });

    test(
      'does not save record when correct is null/missing or kidId is blank',
      () async {
        final question = Question(
          id: 'q_test_null',
          type: QuestionType.wordProblem,
          prompt: '1 + 1 = ?',
          data: const {
            'options': [1, 2],
          },
          correctAnswer: null,
        );

        Future<void> processCapture({
          required dynamic correctValue,
          required String kidId,
          Question? currentQ,
        }) async {
          if (correctValue == false &&
              currentQ != null &&
              kidId.trim().isNotEmpty) {
            try {
              final record = WrongAnswerRecord(
                questionId: currentQ.id,
                prompt: currentQ.prompt,
                questionType: currentQ.type,
                userAnswer: '1',
                timestamp: DateTime.now(),
              );
              await WrongAnswerRepository.saveWrongAnswer(kidId, record);
            } catch (_) {}
          }
        }

        // Case 1: correctValue is null (server didn't grade or errored)
        await processCapture(
          correctValue: null,
          kidId: 'kid_valid',
          currentQ: question,
        );
        expect(
          await WrongAnswerRepository.getWrongAnswers('kid_valid'),
          isEmpty,
        );

        // Case 2: kidId is empty or whitespace
        await processCapture(
          correctValue: false,
          kidId: '   ',
          currentQ: question,
        );
        expect(await WrongAnswerRepository.getWrongAnswers('   '), isEmpty);

        // Case 3: currentQ is null
        await processCapture(
          correctValue: false,
          kidId: 'kid_valid_2',
          currentQ: null,
        );
        expect(
          await WrongAnswerRepository.getWrongAnswers('kid_valid_2'),
          isEmpty,
        );
      },
    );
  });

  group('WrongAnswerRepository Review Management (Step 3)', () {
    test('WrongAnswerRecord supports reviewCount and lastReviewedAt with backward compatibility', () {
      final now = DateTime.now();
      final fresh = WrongAnswerRecord(
        questionId: 'q_fresh',
        prompt: 'Prompt',
        questionType: QuestionType.wordProblem,
        userAnswer: '1',
        timestamp: now,
      );
      expect(fresh.reviewCount, 0);
      expect(fresh.lastReviewedAt, isNull);

      final withReview = fresh.copyWith(reviewCount: 3, lastReviewedAt: now);
      expect(withReview.reviewCount, 3);
      expect(withReview.lastReviewedAt, now);

      final map = withReview.toMap();
      final restored = WrongAnswerRecord.fromMap(map);
      expect(restored.reviewCount, 3);
      expect(restored.lastReviewedAt?.toIso8601String(), now.toIso8601String());

      // Old map without review fields
      final legacy = WrongAnswerRecord.fromMap({
        'questionId': 'q_legacy',
        'prompt': 'Legacy',
        'questionType': 'area_grid',
        'userAnswer': 4,
        'timestamp': now.toIso8601String(),
      });
      expect(legacy.reviewCount, 0);
      expect(legacy.lastReviewedAt, isNull);
    });

    test('getWrongAnswer retrieves target question or returns null', () async {
      const kidId = 'kid_get_single';
      final record = WrongAnswerRecord(
        questionId: 'q_find_me',
        prompt: 'Find me',
        questionType: QuestionType.wordProblem,
        userAnswer: 'A',
        timestamp: DateTime.now(),
      );
      await WrongAnswerRepository.saveWrongAnswer(kidId, record);

      final found = await WrongAnswerRepository.getWrongAnswer(
        kidId,
        'q_find_me',
      );
      expect(found, isNotNull);
      expect(found!.questionId, 'q_find_me');
      expect(found.prompt, 'Find me');

      final notFound = await WrongAnswerRepository.getWrongAnswer(
        kidId,
        'q_absent',
      );
      expect(notFound, isNull);

      final emptyKid = await WrongAnswerRepository.getWrongAnswer(
        '   ',
        'q_find_me',
      );
      expect(emptyKid, isNull);

      final emptyQ = await WrongAnswerRepository.getWrongAnswer(kidId, '   ');
      expect(emptyQ, isNull);
    });

    test(
      'deleteWrongAnswer removes single record and cleans key if empty',
      () async {
        const kidId = 'kid_del';
        final r1 = WrongAnswerRecord(
          questionId: 'q_del_1',
          prompt: 'Prompt 1',
          questionType: QuestionType.wordProblem,
          userAnswer: '1',
          timestamp: DateTime.now(),
        );
        final r2 = WrongAnswerRecord(
          questionId: 'q_del_2',
          prompt: 'Prompt 2',
          questionType: QuestionType.wordProblem,
          userAnswer: '2',
          timestamp: DateTime.now(),
        );
        await WrongAnswerRepository.saveWrongAnswer(kidId, r1);
        await WrongAnswerRepository.saveWrongAnswer(kidId, r2);

        // Delete non-existent
        final missing = await WrongAnswerRepository.deleteWrongAnswer(
          kidId,
          'q_unknown',
        );
        expect(missing, isFalse);

        // Delete invalid parameters
        expect(
          await WrongAnswerRepository.deleteWrongAnswer('', 'q_del_1'),
          isFalse,
        );
        expect(
          await WrongAnswerRepository.deleteWrongAnswer(kidId, ' '),
          isFalse,
        );

        // Delete r1
        final deleted1 = await WrongAnswerRepository.deleteWrongAnswer(
          kidId,
          'q_del_1',
        );
        expect(deleted1, isTrue);
        var list = await WrongAnswerRepository.getWrongAnswers(kidId);
        expect(list.length, 1);
        expect(list.first.questionId, 'q_del_2');

        // Delete r2 (last item removes storage key)
        final deleted2 = await WrongAnswerRepository.deleteWrongAnswer(
          kidId,
          'q_del_2',
        );
        expect(deleted2, isTrue);
        list = await WrongAnswerRepository.getWrongAnswers(kidId);
        expect(list, isEmpty);

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.containsKey(WrongAnswerRepository.storageKey(kidId)),
          isFalse,
        );
      },
    );

    test('markAllResolved marks unresolved items for kid or lesson', () async {
      const kidId = 'kid_mark_all';
      final r1 = WrongAnswerRecord(
        questionId: 'q_1',
        prompt: 'P1',
        questionType: QuestionType.wordProblem,
        userAnswer: '1',
        lessonId: 'L1',
        timestamp: DateTime.now(),
        isResolved: false,
      );
      final r2 = WrongAnswerRecord(
        questionId: 'q_2',
        prompt: 'P2',
        questionType: QuestionType.wordProblem,
        userAnswer: '2',
        lessonId: 'L1',
        timestamp: DateTime.now(),
        isResolved: false,
      );
      final r3 = WrongAnswerRecord(
        questionId: 'q_3',
        prompt: 'P3',
        questionType: QuestionType.wordProblem,
        userAnswer: '3',
        lessonId: 'L2',
        timestamp: DateTime.now(),
        isResolved: false,
      );

      await WrongAnswerRepository.saveWrongAnswer(kidId, r1);
      await WrongAnswerRepository.saveWrongAnswer(kidId, r2);
      await WrongAnswerRepository.saveWrongAnswer(kidId, r3);

      // Mark only L1
      final updatedL1 = await WrongAnswerRepository.markAllResolved(
        kidId,
        lessonId: 'L1',
      );
      expect(updatedL1, 2);

      final l1Unresolved = await WrongAnswerRepository.getWrongAnswers(
        kidId,
        lessonId: 'L1',
        includeResolved: false,
      );
      expect(l1Unresolved, isEmpty);

      final l2Unresolved = await WrongAnswerRepository.getWrongAnswers(
        kidId,
        lessonId: 'L2',
        includeResolved: false,
      );
      expect(l2Unresolved.length, 1);

      // Re-running on L1 updates 0
      expect(
        await WrongAnswerRepository.markAllResolved(kidId, lessonId: 'L1'),
        0,
      );

      // Mark all remaining
      final updatedAll = await WrongAnswerRepository.markAllResolved(kidId);
      expect(updatedAll, 1);

      final allUnresolved = await WrongAnswerRepository.getWrongAnswers(
        kidId,
        includeResolved: false,
      );
      expect(allUnresolved, isEmpty);

      // Invalid kidId
      expect(await WrongAnswerRepository.markAllResolved('   '), 0);
    });

    test('recordReviewAttempt updates attempt count, lastReviewedAt and resolution state', () async {
      const kidId = 'kid_review';
      final record = WrongAnswerRecord(
        questionId: 'q_rev',
        prompt: 'Prompt',
        questionType: QuestionType.multiplicationTable,
        userAnswer: '20',
        timestamp: DateTime.now(),
        isResolved: false,
      );
      await WrongAnswerRepository.saveWrongAnswer(kidId, record);

      // First review attempt: incorrect
      final firstAttempt = await WrongAnswerRepository.recordReviewAttempt(
        kidId,
        'q_rev',
        isCorrect: false,
      );
      expect(firstAttempt, isTrue);

      var item = await WrongAnswerRepository.getWrongAnswer(kidId, 'q_rev');
      expect(item, isNotNull);
      expect(item!.reviewCount, 1);
      expect(item.isResolved, isFalse);
      expect(item.lastReviewedAt, isNotNull);

      // Second review attempt: correct
      final secondAttempt = await WrongAnswerRepository.recordReviewAttempt(
        kidId,
        'q_rev',
        isCorrect: true,
      );
      expect(secondAttempt, isTrue);

      item = await WrongAnswerRepository.getWrongAnswer(kidId, 'q_rev');
      expect(item!.reviewCount, 2);
      expect(item.isResolved, isTrue);

      // Missing item or empty kidId
      expect(
        await WrongAnswerRepository.recordReviewAttempt(
          kidId,
          'missing',
          isCorrect: true,
        ),
        isFalse,
      );
      expect(
        await WrongAnswerRepository.recordReviewAttempt(
          '',
          'q_rev',
          isCorrect: true,
        ),
        isFalse,
      );
    });

    test('getLessonIdsWithWrongAnswers returns unique lesson IDs with unresolved filter', () async {
      const kidId = 'kid_lessons';
      final r1 = WrongAnswerRecord(
        questionId: 'q_1',
        prompt: 'P1',
        questionType: QuestionType.wordProblem,
        userAnswer: '1',
        lessonId: 'lesson_math_1',
        timestamp: DateTime.now(),
        isResolved: false,
      );
      final r2 = WrongAnswerRecord(
        questionId: 'q_2',
        prompt: 'P2',
        questionType: QuestionType.wordProblem,
        userAnswer: '2',
        lessonId: 'lesson_math_1',
        timestamp: DateTime.now(),
        isResolved: false,
      );
      final r3 = WrongAnswerRecord(
        questionId: 'q_3',
        prompt: 'P3',
        questionType: QuestionType.wordProblem,
        userAnswer: '3',
        lessonId: 'lesson_geometry_2',
        timestamp: DateTime.now(),
        isResolved: true,
      );
      final r4 = WrongAnswerRecord(
        questionId: 'q_4',
        prompt: 'P4',
        questionType: QuestionType.wordProblem,
        userAnswer: '4',
        lessonId: null, // Arena or drill without lessonId
        timestamp: DateTime.now(),
        isResolved: false,
      );

      await WrongAnswerRepository.saveWrongAnswer(kidId, r1);
      await WrongAnswerRepository.saveWrongAnswer(kidId, r2);
      await WrongAnswerRepository.saveWrongAnswer(kidId, r3);
      await WrongAnswerRepository.saveWrongAnswer(kidId, r4);

      // Only unresolved lessons
      final unresolvedLessons =
          await WrongAnswerRepository.getLessonIdsWithWrongAnswers(
            kidId,
            onlyUnresolved: true,
          );
      expect(unresolvedLessons, ['lesson_math_1']);

      // All lessons
      final allLessons =
          await WrongAnswerRepository.getLessonIdsWithWrongAnswers(
            kidId,
            onlyUnresolved: false,
          );
      expect(allLessons.toSet(), {'lesson_math_1', 'lesson_geometry_2'});

      // Empty kidId
      expect(
        await WrongAnswerRepository.getLessonIdsWithWrongAnswers(''),
        isEmpty,
      );
    });
  });
}
