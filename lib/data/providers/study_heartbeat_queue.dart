import '../models/study_session.dart';
import '../repositories/study_repository.dart';

/// Preserves lifecycle transitions when a previous heartbeat is still in flight.
class StudyHeartbeatQueue {
  StudyHeartbeatQueue({
    Future<StudySession> Function(String, bool, Map<String, dynamic>)? submit,
  }) : _submit = submit ?? StudyRepository.heartbeat;

  final Future<StudySession> Function(String, bool, Map<String, dynamic>)
  _submit;
  Future<void> _tail = Future.value();

  Future<StudySession> send(
    String session,
    bool active,
    Map<String, dynamic> state,
  ) {
    final snapshot = Map<String, dynamic>.from(state);
    final result = _tail.then((_) => _submit(session, active, snapshot));
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
