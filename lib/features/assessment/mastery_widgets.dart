import 'package:flutter/material.dart';

import '../../data/models/learning_modules.dart';

class MasteryQuiz extends StatefulWidget {
  const MasteryQuiz({
    super.key,
    required this.question,
    required this.onAnswer,
  });
  final QuizQuestion question;
  final ValueChanged<int> onAnswer;
  @override
  State<MasteryQuiz> createState() => _MasteryQuizState();
}

class _MasteryQuizState extends State<MasteryQuiz> {
  int? _answer;
  @override
  void didUpdateWidget(MasteryQuiz oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) _answer = null;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        widget.question.prompt,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      for (var index = 0; index < widget.question.choices.length; index++)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: OutlinedButton(
            onPressed: _answer != null
                ? null
                : () {
                    setState(() => _answer = index);
                    widget.onAnswer(index);
                  },
            child: Text(widget.question.choices[index]),
          ),
        ),
      if (_answer != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Semantics(
            liveRegion: true,
            child: Text(
              _answer == widget.question.answerIndex
                  ? 'Bạn đã tìm ra lời giải.'
                  : 'Cùng xem lại ý tưởng này nhé.',
            ),
          ),
        ),
    ],
  );
}

class MasteryDashboard extends StatelessWidget {
  const MasteryDashboard({super.key, required this.metrics});
  final List<MasteryMetric> metrics;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Hiểu thêm từng ngày',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      Text(
        '${metrics.where((metric) => metric.mastered).length} vững kiến thức · '
        '${metrics.where((metric) => metric.struggling).length} cần luyện thêm',
      ),
      if (metrics.isEmpty) const Text('Chưa có kết quả đánh giá.'),
      for (final metric in metrics)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${metric.topicId} · ${metric.total == 0 ? 'Chưa đánh giá' : '${metric.correct}/${metric.total}'}',
              ),
              if (metric.score != null)
                LinearProgressIndicator(
                  value: metric.score,
                  semanticsLabel: metric.topicId,
                  semanticsValue: '${(metric.score! * 100).round()}%',
                ),
            ],
          ),
        ),
      const Text(
        'Kết quả luyện tập cá nhân, chưa phải điểm xác thực trên server.',
      ),
    ],
  );
}
