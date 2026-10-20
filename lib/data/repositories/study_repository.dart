import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/study_session.dart';
import 'commerce_repository.dart';
import 'study_cache.dart';

class StudyRepository {
  static final _operations = <String, Future<void>>{};

  // Heartbeats may flush the same answer a tap is retrying. Keep their cache
  // writes ordered so an old acknowledgement cannot remove a newer answer.
  static Future<T> _serial<T>(String id, Future<T> Function() action) async {
    final previous = _operations[id] ?? Future<void>.value();
    final result = previous.then((_) => action());
    final done = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _operations[id] = done;
    try {
      return await result;
    } finally {
      if (identical(_operations[id], done)) _operations.remove(id);
    }
  }

  static bool isTransient(Object error) =>
      error is! AuthException &&
      error is! Error &&
      error is! FormatException &&
      (error is! PostgrestException ||
          error.code == null ||
          ['40001', '40P01', '57014'].contains(error.code) ||
          ((int.tryParse(error.code ?? '') ?? 0) >= 500 &&
              (int.tryParse(error.code ?? '') ?? 0) < 600));
  static Future<dynamic> rpc(
    String name, [
    Map<String, dynamic> params = const {},
  ]) async {
    final client = SupabaseService.client;
    if (client?.auth.currentSession == null) {
      throw StateError('Cần đăng nhập và kết nối mạng.');
    }
    return client!.rpc(name, params: params);
  }

  static Future<StudySession> _save(dynamic data) async {
    final s = StudySession(Map<String, dynamic>.from(data));
    await StudyCache.save(s);
    return s;
  }

  static Future<String?> _flush(String id) async {
    final pending = await StudyCache.pending(id);
    if (pending == null) return null;
    try {
      await _save(await rpc('answer_learning_session', pending));
      await StudyCache.acknowledge(id);
      return pending['p_request'] as String?;
    } on PostgrestException catch (error) {
      if (!isTransient(error)) await StudyCache.acknowledge(id);
      rethrow;
    }
  }

  static Future<StudySession> start(
    String kid,
    String? lesson,
    String kind,
    String request,
  ) async {
    final cached = await StudyCache.last(kid, kind, lesson);
    try {
      if (cached != null) await _flush(cached.id);
      final started = await _save(
        await rpc('start_learning_session', {
          'p_kid': kid,
          'p_lesson': lesson,
          'p_kind': kind,
          'p_request': request,
        }),
      );
      await _flush(started.id);
      return await _save(
        await rpc('heartbeat_learning_session', {
          'p_session': started.id,
          'p_active': true,
          'p_state': started.viewState,
        }),
      );
    } catch (error) {
      if (!isTransient(error)) rethrow;
      if (cached != null && !cached.completed) return cached;
      rethrow;
    }
  }

  static Future<StudySession> resume(String sessionId) async {
    await _flush(sessionId);
    return _save(
      await rpc('resume_learning_session', {'p_session': sessionId}),
    );
  }

  static Future<StudySession> heartbeat(
    String id,
    bool active,
    Map<String, dynamic> state,
  ) => _serial(id, () => _heartbeat(id, active, state));

  static Future<StudySession> _heartbeat(
    String id,
    bool active,
    Map<String, dynamic> state,
  ) async {
    String? acknowledgedRequest;
    try {
      acknowledgedRequest = await _flush(id);
      return await _save({
        ...Map<String, dynamic>.from(
          await rpc('heartbeat_learning_session', {
            'p_session': id,
            'p_active': active,
            'p_state': state,
          }),
        ),
        'acknowledged_answer_request': ?acknowledgedRequest,
      });
    } catch (error) {
      if (!isTransient(error)) rethrow;
      final cached = await StudyCache.read(id);
      if (cached == null) rethrow;
      final saved = StudySession({
        ...cached.data,
        'view_state': state,
        'offline': true,
        'acknowledged_answer_request': ?acknowledgedRequest,
      });
      await StudyCache.save(saved);
      return saved;
    }
  }

  static Future<StudySession> answer(
    String id,
    String question,
    dynamic value,
    String request,
    int hints,
  ) => _serial(id, () => _answer(id, question, value, request, hints));

  static Future<StudySession> _answer(
    String id,
    String question,
    dynamic value,
    String request,
    int hints,
  ) async {
    final pending = await StudyCache.pending(id);
    final params =
        pending ??
        {
          'p_session': id,
          'p_question': question,
          'p_value': value,
          'p_request': request,
          'p_hints': hints,
        };
    await StudyCache.enqueue(id, params);
    try {
      final s = await _save(await rpc('answer_learning_session', params));
      await StudyCache.acknowledge(id);
      return s;
    } catch (error) {
      if (!isTransient(error)) {
        await StudyCache.acknowledge(id);
        rethrow;
      }
      final cached = await StudyCache.read(id);
      if (cached == null) rethrow;
      return StudySession({
        ...cached.data,
        'offline': true,
        'queued_answer': true,
      });
    }
  }

  static Future<bool> essay(String id, String result, String solution) async =>
      await rpc('submit_learning_essay', {
        'p_session': id,
        'p_result': result,
        'p_solution': solution,
      }) ==
      true;
  static Future<StudySession> finish(String id) async {
    await _flush(id);
    return _save(await rpc('finish_learning_session', {'p_session': id}));
  }

  static String requestId() => CommerceRepository.newRequestId();
}
