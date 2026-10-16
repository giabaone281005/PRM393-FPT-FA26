import '../../core/supabase/supabase_service.dart';
import '../models/lesson.dart';
import '../models/question.dart';
import '../datasources/sample_curriculum.dart';

class LessonRepository {
  /// Lấy danh sách 30 bài học của khối lớp từ Supabase DB
  /// Nếu offline hoặc DB chưa có dữ liệu -> Tự động fallback về SampleCurriculum
  static Future<List<Lesson>> fetchLessonsForGrade(int grade) async {
    if (!SupabaseService.isInitialized) {
      return SampleCurriculum.getLessonsForGrade(grade);
    }

    try {
      // 1. Lấy topic theo grade
      final topicRes = await SupabaseService.client!
          .from('topics')
          .select('id')
          .eq('grade', grade)
          .maybeSingle();

      if (topicRes == null) {
        return SampleCurriculum.getLessonsForGrade(grade);
      }

      final topicId = topicRes['id'];

      // 2. Lấy danh sách bài học thuộc topic này
      final lessonsRes = await SupabaseService.client!
          .from('lessons')
          .select('id, lesson_number, title, subtitle, estimated_minutes, xp_reward, star_reward, order_index, theory, essay_prompt, essay_guidance, mini_game_type')
          .eq('topic_id', topicId)
          .order('order_index');

      final lessonList = lessonsRes as List? ?? [];
      if (lessonList.isEmpty) {
        return SampleCurriculum.getLessonsForGrade(grade);
      }

      // 3. Với mỗi bài học, query câu hỏi từ bảng 'questions'
      final List<Lesson> result = [];

      for (var row in lessonList) {
        final lessonId = row['id'].toString();
        final lessonNum = (row['lesson_number'] ?? row['order_index'] ?? 1) as int;

        // Trạng thái theo lộ trình
        LessonStatus status;
        int stars = 0;
        if (lessonNum < 14) {
          status = LessonStatus.completed;
          stars = 3;
        } else if (lessonNum == 14) {
          status = LessonStatus.inProgress;
          stars = 0;
        } else {
          status = LessonStatus.locked;
          stars = 0;
        }

        // Lấy questions từ DB
        final questionsRes = await SupabaseService.client!
            .from('questions')
            .select('id, question_type, prompt, payload, socratic_hints, order_index')
            .eq('lesson_id', lessonId)
            .order('order_index');

        final qList = questionsRes as List? ?? [];
        List<Question> questions = [];

        if (qList.isNotEmpty) {
          questions = qList.map((qRow) {
            final qTypeStr = qRow['question_type']?.toString() ?? 'word_problem';
            QuestionType qType;
            switch (qTypeStr) {
              case 'drag_counters':
                qType = QuestionType.dragCounters;
                break;
              case 'multiplication_table':
                qType = QuestionType.multiplicationTable;
                break;
              case 'clock_rotation':
                qType = QuestionType.clockRotation;
                break;
              case 'area_grid':
                qType = QuestionType.areaGrid;
                break;
              case 'word_problem':
              default:
                qType = QuestionType.wordProblem;
                break;
            }

            final payload = Map<String, dynamic>.from(qRow['payload'] ?? {});
            final rawHints = qRow['socratic_hints'] as List? ?? [];
            final hints = rawHints.map((h) => SocraticHint(
              step: h['step'] ?? 1,
              questionText: h['questionText'] ?? h['question_text'] ?? '',
              hintText: h['hintText'] ?? h['hint_text'] ?? '',
            )).toList();

            return Question(
              id: qRow['id'].toString(),
              type: qType,
              prompt: qRow['prompt'] ?? '',
              subtitle: payload['subtitle']?.toString() ?? '',
              data: payload,
              correctAnswer: payload['correctAnswer'] ?? payload['answer'],
              socraticHints: hints,
            );
          }).toList();
        } else {
          // Nếu bài học chưa nạp đủ câu hỏi trên cloud -> lấy bộ 10 câu matching tiêu đề từ SampleCurriculum
          final fallbackLessons = SampleCurriculum.getLessonsForGrade(grade);
          final match = fallbackLessons.firstWhere(
            (fl) => fl.lessonNumber == lessonNum,
            orElse: () => fallbackLessons.first,
          );
          questions = match.questions;
        }

        result.add(
          Lesson(
            id: lessonId,
            grade: grade,
            lessonNumber: lessonNum,
            title: row['title'] ?? 'Bài $lessonNum',
            subtitle: row['subtitle'] ?? 'Lộ trình chuẩn kiến thức',
            estimatedMinutes: row['estimated_minutes'] ?? 4,
            xpReward: row['xp_reward'] ?? 30,
            starReward: row['star_reward'] ?? 3,
            status: status,
            starsEarned: stars,
            theory: row['theory']?.toString(),
            essayPrompt: row['essay_prompt']?.toString(),
            essayGuidance: row['essay_guidance']?.toString(),
            miniGameType: row['mini_game_type']?.toString(),
            questions: questions,
          ),
        );
      }

      return result;
    } catch (_) {
      return SampleCurriculum.getLessonsForGrade(grade);
    }
  }
}
