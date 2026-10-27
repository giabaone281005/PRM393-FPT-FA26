/// Domain types shared by UI, pathway planning and engine adapters.
enum CourseDomain {
  math,
  computerScienceAndAi,
  generalScience,
  dataAnalysis,
  artsAndHumanities,
}

class CourseRoadmap {
  CourseRoadmap({
    required this.id,
    required this.domain,
    required List<CourseNode> nodes,
  }) : nodes = List.unmodifiable(nodes) {
    final ids = this.nodes.map((node) => node.topicId).toSet();
    if (ids.length != this.nodes.length ||
        this.nodes.any(
          (node) => node.prerequisites.any((id) => !ids.contains(id)),
        )) {
      throw ArgumentError('Roadmap cần ID duy nhất và prerequisite tồn tại.');
    }
    final visiting = <String>{}, visited = <String>{};
    void visit(String id) {
      if (visited.contains(id)) return;
      if (!visiting.add(id)) throw ArgumentError('Roadmap có chu trình.');
      for (final prerequisite
          in this.nodes
              .firstWhere((node) => node.topicId == id)
              .prerequisites) {
        visit(prerequisite);
      }
      visiting.remove(id);
      visited.add(id);
    }

    for (final id in ids) {
      visit(id);
    }
  }
  final String id;
  final CourseDomain domain;
  final List<CourseNode> nodes;
}

class CourseNode {
  CourseNode(this.topicId, {List<String> prerequisites = const []})
    : prerequisites = List.unmodifiable(prerequisites);

  /// Reuses LearningTopic.id / ExperimentSpec.skillIds from the current catalog.
  final String topicId;
  final List<String> prerequisites;
}

class MasteryMetric {
  MasteryMetric({
    required this.topicId,
    required this.correct,
    required this.total,
  }) {
    if (correct < 0 || total < correct) {
      throw ArgumentError('Số lượt đánh giá không hợp lệ.');
    }
  }
  final String topicId;
  final int correct, total;
  double? get score => total == 0 ? null : correct / total;
  bool get mastered => total >= 5 && score! >= .8;
  bool get struggling => total >= 3 && score! < .5;
}

class PathwayDecision {
  const PathwayDecision(this.topicId, this.minutes, this.review);
  final String topicId;
  final int minutes;
  final bool review;
}

abstract interface class PathwayController {
  PathwayDecision? next(CourseRoadmap roadmap, List<MasteryMetric> metrics);
}

/// A local practice suggestion, never server-verified mastery or an XP award.
class MasteryPathwayController implements PathwayController {
  @override
  PathwayDecision? next(CourseRoadmap roadmap, List<MasteryMetric> metrics) {
    final byId = {for (final metric in metrics) metric.topicId: metric};
    for (final node in roadmap.nodes) {
      final metric = byId[node.topicId];
      if (metric?.mastered == true ||
          node.prerequisites.any((id) => byId[id]?.mastered != true)) {
        continue;
      }
      return PathwayDecision(
        node.topicId,
        metric?.struggling == true ? 5 : 10,
        metric?.struggling == true,
      );
    }
    return null;
  }
}

class CanvasPoint {
  CanvasPoint(this.x, this.y) {
    if (!x.isFinite || !y.isFinite || x < 0 || x > 1 || y < 0 || y > 1) {
      throw ArgumentError('Canvas dùng tọa độ chuẩn hóa từ 0 đến 1.');
    }
  }
  final double x, y;
  Map<String, double> toJson() => {'x': x, 'y': y};
}

class CanvasStroke {
  CanvasStroke(List<CanvasPoint> points) : points = List.unmodifiable(points);
  final List<CanvasPoint> points;
}

class CanvasOverlay {
  CanvasOverlay(this.label, this.topLeft, this.bottomRight) {
    if (topLeft.x > bottomRight.x || topLeft.y > bottomRight.y) {
      throw ArgumentError('Bounding box không hợp lệ.');
    }
  }
  final String label;
  final CanvasPoint topLeft, bottomRight;
}

class SharedCanvasDocument {
  SharedCanvasDocument({
    List<CanvasStroke> strokes = const [],
    List<CanvasOverlay> overlays = const [],
  }) : strokes = List.unmodifiable(strokes),
       overlays = List.unmodifiable(overlays);
  final List<CanvasStroke> strokes;
  final List<CanvasOverlay> overlays;
  Map<String, Object> toJson() => {
    'strokes': strokes
        .map((stroke) => stroke.points.map((point) => point.toJson()).toList())
        .toList(),
    'overlays': overlays
        .map(
          (box) => {
            'label': box.label,
            'topLeft': box.topLeft.toJson(),
            'bottomRight': box.bottomRight.toJson(),
          },
        )
        .toList(),
  };
}

enum TutorRole { user, assistant }

class TutorMessage {
  const TutorMessage(this.role, this.text);
  final TutorRole role;
  final String text;
  Map<String, String> toJson() => {'role': role.name, 'content': text};
}

class TutorRequest {
  TutorRequest({required List<TutorMessage> messages, this.canvas})
    : messages = List.unmodifiable(messages);
  final List<TutorMessage> messages;
  final SharedCanvasDocument? canvas;
}

class TutorReply {
  const TutorReply(this.text);
  final String text;
}

/// Native voice implementations must request permission only after user action.
abstract interface class VoiceAssistant {
  Stream<String> listen();
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> dispose();
}

class CodeRequest {
  CodeRequest({
    required this.source,
    required this.language,
    this.stdin = '',
    this.judge0LanguageId,
  }) {
    if (source.trim().isEmpty ||
        source.length > 50000 ||
        stdin.length > 10000 ||
        !['python', 'javascript'].contains(language) ||
        (judge0LanguageId != null && judge0LanguageId! <= 0)) {
      throw ArgumentError('Chương trình hoặc ngôn ngữ không hợp lệ.');
    }
  }
  final String source, language, stdin;

  /// Resolve using the configured Judge0 server's /languages, not a global ID.
  final int? judge0LanguageId;
}

class ExecutionResult {
  const ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.error,
    this.exitCode,
  });
  final String stdout, stderr;
  final String? error;
  final int? exitCode;
}

class ProjectTemplate {
  const ProjectTemplate(this.id, this.title, this.language, this.source);
  final String id, title, language, source;
}

const projectTemplates = [
  ProjectTemplate(
    'image-matrix',
    'Ma trận bộ lọc ảnh',
    'python',
    'pixels = [[20, 80], [160, 240]]\nfiltered = [[255 - p for p in row] for row in pixels]\nprint(filtered)\n',
  ),
  ProjectTemplate(
    'security-simulator',
    'Mô phỏng kiểm tra đường dẫn',
    'python',
    'from urllib.parse import urlparse\nurls = ["https://example.test", "javascript:demo"]\nfor url in urls:\n    print(url, urlparse(url).scheme == "https")\n',
  ),
];

class QuizQuestion {
  QuizQuestion({
    required this.id,
    required this.topicId,
    required this.prompt,
    required List<String> choices,
    required this.answerIndex,
  }) : choices = List.unmodifiable(choices) {
    if (choices.length < 2 ||
        answerIndex < 0 ||
        answerIndex >= choices.length) {
      throw ArgumentError('Câu hỏi không hợp lệ.');
    }
  }
  final String id, topicId, prompt;
  final List<String> choices;
  final int answerIndex;
}

abstract interface class AssessmentRepository {
  Future<List<QuizQuestion>> questions(String topicId);
  Future<void> recordAnswer(
    String profileId,
    String questionId,
    int answerIndex,
  );
  Future<List<MasteryMetric>> metrics(String profileId);
}

class ProgressReport {
  ProgressReport(this.profileId, List<MasteryMetric> topics)
    : topics = List.unmodifiable(topics);
  final String profileId;
  final List<MasteryMetric> topics;
}

abstract interface class ProgressNotificationService {
  Future<bool> requestPermission();
  Future<void> schedule(ProgressReport report, DateTime at);
  Future<void> cancel(String profileId);
}
