import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/study_session.dart';
import '../../data/models/question.dart';
import '../../data/models/wrong_answer_record.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/providers/study_heartbeat_queue.dart';
import '../../core/services/app_route_observer.dart';
import '../../data/repositories/learning_statistics_repository.dart';
import '../../data/repositories/study_repository.dart';
import '../../data/repositories/wrong_answer_repository.dart';
import 'widgets/drag_counters_widget.dart';
import 'widgets/clock_rotation_widget.dart';
import 'widgets/multiplication_widget.dart';
import 'widgets/area_grid_widget.dart';
import 'widgets/word_problem_widget.dart';
import 'widgets/voice_answer_widget.dart';
import '../../core/services/voice/speech_service.dart';
import 'screens/review_wrong_answers_screen.dart';
import '../parent_portal/popups/parent_gate_dialog.dart';

class StudyScreen extends StatefulWidget {
  final String? lessonId;
  final String kind;
  final SpeechService? speechService;
  const StudyScreen({
    super.key,
    this.lessonId,
    this.kind = 'lesson',
    this.speechService,
  });
  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen>
    with WidgetsBindingObserver, RouteAware {
  StudySession? _session;
  bool _busy = true, _foreground = true, _routeVisible = true, _onBreak = false;
  ModalRoute<dynamic>? _route;
  final _heartbeats = StudyHeartbeatQueue();
  bool get _isStudyActive => _foreground && _routeVisible && !_onBreak;
  String? _error, _feedback;
  String _tab = 'theory';
  String _startRequest = StudyRepository.requestId();
  String? _answerRequest;
  dynamic _pendingAnswer;
  int _hints = 0, _remaining = 0, _activeSeconds = 0;
  Timer? _timer;
  final _solution = TextEditingController();
  final _result = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isStudyActive ||
          _session == null ||
          _session!.completed ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      if (_remaining > 0) setState(() => _remaining--);
      _activeSeconds++;
      if (_activeSeconds % 20 == 0) _heartbeat(true);
      if (_activeSeconds == 600) _break();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route != route && route != null) {
      appRouteObserver.unsubscribe(this);
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _heartbeat(false);
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _heartbeat(_isStudyActive);
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final state = context.read<AppStateProvider>();
      final session = await StudyRepository.start(
        state.currentKid.id,
        widget.lessonId,
        widget.kind,
        _startRequest,
      );
      if (!mounted) {
        if (!session.completed) {
          await _heartbeats.send(session.id, false, session.viewState);
        }
        return;
      }
      _apply(session);
      final view = session.viewState;
      _tab =
          view['tab']?.toString() ??
          (session.theory.isNotEmpty ? 'theory' : 'quiz');
      _solution.text = view['essay_solution']?.toString() ?? '';
      _result.text = view['essay_result']?.toString() ?? '';
      if (!_isStudyActive) await _heartbeat(false);
    } catch (e) {
      if (mounted) _error = _message(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object e) => e is PostgrestException
      ? e.message
      : 'Chưa kết nối được máy chủ. Bài đang dở được giữ lại để tiếp tục.';
  void _apply(StudySession session) {
    if (!mounted) return;
    if (_session?.id == session.id &&
        DateTime.parse(session.data['updated_at'])
            .isBefore(DateTime.parse(_session!.data['updated_at']))) {
      return;
    }
    setState(() {
      _session = session;
      _remaining = session.remainingSeconds;
    });
  }

  Map<String, dynamic> get _view => {
    'tab': _tab,
    'essay_solution': _solution.text,
    'essay_result': _result.text,
  };
  Future<void> _heartbeat(bool active) async {
    if (_session == null || _session!.completed) {
      return;
    }
    try {
      final current = _session!;
      final fresh = await _heartbeats.send(
        current.id,
        active && _isStudyActive,
        _view,
      );
      if (mounted && _session?.id == current.id) _apply(fresh);
    } catch (_) {
      if (mounted) {
        setState(
          () => _feedback = 'Mất kết nối. Chọn thử lại trước khi tiếp tục.',
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _heartbeat(_isStudyActive);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    final current = _session;
    if (current != null && !current.completed) {
      _heartbeats.send(current.id, false, _view).catchError((_) => current);
    }
    _solution.dispose();
    _result.dispose();
    super.dispose();
  }

  Future<void> _break() async {
    _onBreak = true;
    await _heartbeat(false);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Cho mắt nghỉ một chút nhé'),
        content: const Text(
          'Em đã học 10 phút. Hãy nhìn ra xa, đứng lên và uống nước trước khi tiếp tục.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Sẵn sàng học tiếp'),
          ),
        ],
      ),
    );
    _activeSeconds = 0;
    _onBreak = false;
    await _heartbeat(_isStudyActive);
  }

  Future<void> _answer(dynamic value) async {
    if (_busy || _session == null) return;
    _answerRequest ??= StudyRepository.requestId();
    _pendingAnswer ??= value;
    final currentQ = _session!.currentQuestion;
    final attemptedAnswer = _pendingAnswer;
    final submittedRequestId = _answerRequest;
    final kidId = _session!.kidId.isNotEmpty
        ? _session!.kidId
        : (context.read<AppStateProvider>().hasKids
              ? context.read<AppStateProvider>().currentKid.id
              : '');
    final lessonId = widget.lessonId ?? _session!.data['lesson_id']?.toString();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await StudyRepository.answer(
        _session!.id,
        _session!.currentQuestion!.id,
        _pendingAnswer,
        _answerRequest!,
        _hints,
      );
      if (!mounted) return;
      if (updated.data['queued_answer'] == true) {
        _apply(updated);
        _feedback = 'Đã giữ câu trả lời trên máy. Cú sẽ kiểm tra khi có mạng; em có thể xem lại lý thuyết và gợi ý.';
        return;
      }
      _answerRequest = null;
      _pendingAnswer = null;
      _hints = 0;
      _apply(updated);
      if (context.read<AppStateProvider>().soundEnabled) {
        SystemSound.play(SystemSoundType.click);
      }
      final isCorrect = updated.data['correct'] == true;
      _feedback = isCorrect
          ? 'Chính xác! Em làm tốt lắm.'
          : 'Chưa đúng. Em thử xem gợi ý rồi tính lại nhé.';

      // Record answer in learning statistics and daily streak
      final eventId =
          '${_session!.id}:${currentQ?.id ?? ""}:$submittedRequestId';
      try {
        final appState = context.read<AppStateProvider>();
        await appState.recordPracticeAnswer(
          isCorrect: isCorrect,
          kidId: kidId.trim().isNotEmpty ? kidId : null,
          eventId: eventId,
        );
      } catch (_) {
        try {
          await LearningStatisticsRepository.recordAnswer(
            isCorrect: isCorrect,
            kidId: kidId.trim().isNotEmpty ? kidId : null,
            eventId: eventId,
          );
        } catch (_) {}
      }
      if (updated.data['correct'] == false &&
          currentQ != null &&
          kidId.trim().isNotEmpty) {
        try {
          final record = WrongAnswerRecord(
            questionId: currentQ.id,
            prompt: currentQ.prompt,
            questionType: currentQ.type,
            userAnswer: attemptedAnswer,
            lessonId: lessonId,
            timestamp: DateTime.now(),
            isResolved: false,
            questionData: currentQ.data,
          );
          await WrongAnswerRepository.saveWrongAnswer(kidId, record);
        } catch (_) {
          // Never disrupt grading, progression, or completion on local storage error
        }
      }
      if (updated.data['out_of_hearts'] == true) {
        _feedback = 'Hết tim rồi. Vào vườn luyện tập miễn phí để hồi tim nhé.';
      }
      if (updated.quizDone) {
        _tab = updated.essayRequired && !updated.essayPassed
            ? 'essay'
            : 'finish';
      }
    } catch (e) {
      if (mounted) _error = _message(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _essay() async {
    if (_session == null) return;
    setState(() => _busy = true);
    try {
      final ok = await StudyRepository.essay(
        _session!.id,
        _result.text.trim(),
        _solution.text.trim(),
      );
      if (!mounted) return;
      if (ok) {
        _apply(await StudyRepository.heartbeat(_session!.id, true, _view));
        _tab = 'finish';
      } else {
        _feedback = 'Kiểm tra lại đáp số và viết cách giải ít nhất 5 ký tự.';
      }
    } catch (e) {
      if (mounted) _error = _message(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    if (_session == null || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await StudyRepository.finish(_session!.id);
      if (!mounted) return;
      _apply(result);
      await context.read<AppStateProvider>().refreshFromCloud();
    } catch (e) {
      if (mounted) _error = _message(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _practice() async {
    await _heartbeat(false);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudyScreen(kind: 'practice')),
    );
    if (!mounted) return;
    _startRequest = StudyRepository.requestId();
    await _start();
  }

  Widget _question(Question q) {
    void legacy(bool _) {}
    return KeyedSubtree(
      key: ValueKey(q.id),
      child: switch (q.type) {
        QuestionType.dragCounters => DragCountersWidget(
          data: q.data,
          onAnswerSubmitted: legacy,
          onAnswerValue: _answer,
        ),
        QuestionType.clockRotation => ClockRotationWidget(
          data: q.data,
          onAnswerSubmitted: legacy,
          onAnswerValue: _answer,
        ),
        QuestionType.multiplicationTable => MultiplicationWidget(
          data: q.data,
          onAnswerSubmitted: legacy,
          onAnswerValue: _answer,
        ),
        QuestionType.areaGrid => AreaGridWidget(
          data: q.data,
          onAnswerSubmitted: legacy,
          onAnswerValue: _answer,
        ),
        QuestionType.wordProblem => WordProblemWidget(
          data: q.data,
          onAnswerSubmitted: legacy,
          onAnswerValue: _answer,
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    return Scaffold(
      appBar: AppBar(
        title: Text(s?.title ?? 'Đang mở bài học'),
        actions: [
          if (s != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '❤️ ${s.hearts}  ⏱ ${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')}',
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (s?.data['offline'] == true)
              const Text(
                'Đang ngoại tuyến · kết quả và phần thưởng chờ máy chủ xác nhận.',
              ),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        if (_answerRequest != null) {
                          _answer(_pendingAnswer);
                        } else {
                          _start();
                        }
                      },
                child: const Text('Thử lại'),
              ),
              TextButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const ParentGateDialog(),
                ),
                child: const Text('Cổng phụ huynh'),
              ),
            ],
            if (_feedback != null)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_feedback!),
                ),
              ),
            if (s != null && s.completed) ...[
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
              const Text('Hoàn thành!'),
              Text(
                'Độ chính xác: ${s.data['accuracy_percent']}% · +${s.data['xp_earned']} XP · +${s.data['stars_awarded']} sao',
              ),
              if (s.kind == 'practice')
                const Text('Tim của bé đã được hồi đầy đủ.'),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tiếp tục hành trình'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  final kId = s.kidId.isNotEmpty
                      ? s.kidId
                      : (context.read<AppStateProvider>().hasKids
                            ? context.read<AppStateProvider>().currentKid.id
                            : '');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewWrongAnswersScreen(
                        kidId: kId,
                        lessonId:
                            widget.lessonId ?? s.data['lesson_id']?.toString(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.history_edu_rounded),
                label: const Text('Xem lại câu trả lời sai'),
              ),
            ] else if (s != null) ...[
              LinearProgressIndicator(
                value: s.questions.isEmpty ? 0 : s.index / s.questions.length,
              ),
              Text('${s.index}/${s.questions.length} câu đã hoàn thành'),
              if (_remaining <= 0 && !s.quizDone) ...[
                const Text(
                  'Đã hết thời gian học hôm nay. Hẹn em vào ngày mai nhé.',
                ),
                TextButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const ParentGateDialog(),
                  ),
                  child: const Text('Nhờ phụ huynh điều chỉnh'),
                ),
              ] else ...[
                Wrap(
                  spacing: 8,
                  children: [
                    if (s.theory.isNotEmpty)
                      ChoiceChip(
                        label: const Text('Lý thuyết'),
                        selected: _tab == 'theory',
                        onSelected: (_) => setState(() => _tab = 'theory'),
                      ),
                    ChoiceChip(
                      label: const Text('Câu hỏi'),
                      selected: _tab == 'quiz',
                      onSelected: (_) => setState(() => _tab = 'quiz'),
                    ),
                    if (s.quizDone && s.essayRequired)
                      ChoiceChip(
                        label: const Text('Tự luận'),
                        selected: _tab == 'essay',
                        onSelected: (_) => setState(() => _tab = 'essay'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_tab == 'theory') ...[
                  SelectableText(s.theory.replaceAll(r'\n', '\n')),
                  FilledButton(
                    onPressed: () => setState(() => _tab = 'quiz'),
                    child: const Text('Bắt đầu luyện tập'),
                  ),
                ] else if (_tab == 'essay') ...[
                  Text(s.essayPrompt),
                  TextField(
                    controller: _solution,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Cách giải của em',
                    ),
                  ),
                  TextField(
                    controller: _result,
                    decoration: const InputDecoration(
                      labelText: 'Đáp số (theo yêu cầu của đề)',
                    ),
                  ),
                  FilledButton(
                    onPressed: _busy ? null : _essay,
                    child: const Text('Kiểm tra bài tự luận'),
                  ),
                ] else if (!s.quizDone && s.currentQuestion != null) ...[
                  if (s.kind == 'lesson' && s.hearts == 0)
                    FilledButton(
                      onPressed: _practice,
                      child: const Text('Luyện 5 câu để hồi tim miễn phí'),
                    )
                  else ...[
                    Text(
                      s.currentQuestion!.prompt,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    VoiceAnswerWidget(
                      key: ValueKey('voice_${s.currentQuestion!.id}'),
                      question: s.currentQuestion!,
                      speechService: widget.speechService,
                      isBusy: _busy,
                      onAnswerConfirmed: _answer,
                    ),
                    const SizedBox(height: 12),
                    AbsorbPointer(
                      absorbing: _busy,
                      child: _question(s.currentQuestion!),
                    ),
                  ],
                  TextButton.icon(
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Gợi ý từng bước'),
                    onPressed: () {
                      final hints = s.currentQuestion!.socraticHints;
                      _hints++;
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cùng suy nghĩ nhé'),
                          content: Text(
                            hints.isEmpty
                                ? 'Em biết những dữ kiện nào? Phép tính nào phù hợp?'
                                : hints[(_hints - 1).clamp(0, hints.length - 1)]
                                      .hintText,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Em hiểu rồi'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                if (s.quizDone && (!s.essayRequired || s.essayPassed))
                  FilledButton(
                    onPressed: _busy ? null : _finish,
                    child: const Text('Lưu kết quả và nhận thưởng'),
                  ),
                if (s.quizDone &&
                    s.essayRequired &&
                    !s.essayPassed &&
                    _tab != 'essay')
                  FilledButton(
                    onPressed: () => setState(() => _tab = 'essay'),
                    child: const Text('Làm bài tự luận'),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
