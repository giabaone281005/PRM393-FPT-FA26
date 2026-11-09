import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/admin_dashboard.dart';
import '../models/learning_journal.dart';
import '../repositories/admin_repository.dart';
import '../repositories/auth_repository.dart';

class AdminDashboardController extends ChangeNotifier {
  AdminDashboardController({
    required this.auth,
    required this.repository,
    this.pollInterval = const Duration(seconds: 30),
  }) {
    _authChanges = auth.changes.listen((owner) {
      if (owner != _owner) unawaited(_changeAccount(owner));
    });
    unawaited(_changeAccount(auth.userId));
  }
  final AuthRepository auth;
  final AdminRepository repository;
  final Duration pollInterval;
  StreamSubscription<String?>? _authChanges;
  StreamSubscription<AdminRealtimeEvent>? _events;
  Timer? _poll, _debounce;
  String? _owner;
  int _epoch = 0, _request = 0;
  bool _disposed = false;
  bool loading = false, busy = false, live = false;
  AdminAccess? access;
  String? message;
  String section = 'accounts', search = '';
  int offset = 0, total = 0;
  DateTime? updatedAt;
  Map<String, int> overview = {};
  List<AdminAccount> accounts = [];
  List<AdminTopic> topics = [];
  final _operationIds = <String, String>{};
  bool get signedIn => _owner != null;
  bool get allowed => signedIn && access?.allowed == true;
  String? get email => auth.email;
  String? get userId => _owner;
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void _clearData() {
    accounts = [];
    topics = [];
    overview = {};
    total = 0;
    updatedAt = null;
  }

  Future<void> _changeAccount(String? owner) async {
    final epoch = ++_epoch;
    _owner = owner;
    access = null;
    message = null;
    live = false;
    busy = false;
    section = 'accounts';
    search = '';
    offset = 0;
    _clearData();
    _operationIds.clear();
    _poll?.cancel();
    _poll = null;
    _debounce?.cancel();
    unawaited(_events?.cancel());
    _events = null;
    if (_disposed || epoch != _epoch) return;
    loading = owner != null;
    _emit();
    if (owner != null) await refresh();
  }

  Future<void> refresh() async {
    final owner = _owner;
    if (_disposed || owner == null) return;
    final epoch = _epoch, request = ++_request;
    final requestedSection = section,
        requestedSearch = search,
        requestedOffset = offset;
    bool current() => !_disposed && epoch == _epoch && request == _request;
    loading = true;
    _emit();
    try {
      final permission = await repository.access(owner);
      if (!current()) return;
      access = permission;
      if (!permission.allowed) {
        _clearData();
        live = false;
        unawaited(_events?.cancel());
        _events = null;
        _poll?.cancel();
        _poll = null;
        return;
      }
      final data = await Future.wait([
        repository.read(owner, 'overview'),
        repository.read(
          owner,
          requestedSection == 'builder' ? 'topics' : requestedSection,
          search: requestedSearch,
          offset: requestedOffset,
        ),
      ]);
      if (!current()) return;
      overview = data.first.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
      final rows = (data.last['items'] as List).map(
        (row) => Map<String, dynamic>.from(row as Map),
      );
      if (requestedSection == 'accounts') {
        accounts = rows.map(AdminAccount.fromJson).toList();
      } else {
        topics = rows.map(AdminTopic.fromJson).toList();
      }
      total = (data.last['total'] as num).toInt();
      updatedAt = DateTime.now();
      message = null;
      _events ??= repository
          .watch(owner)
          .listen(
            (event) {
              if (_disposed || epoch != _epoch) return;
              live = event.connected;
              _emit();
              if (event.changed) _scheduleRefresh();
            },
            onError: (_) {
              if (!_disposed && epoch == _epoch) {
                live = false;
                _emit();
              }
            },
          );
      _poll ??= Timer.periodic(pollInterval, (_) => unawaited(refresh()));
    } catch (error) {
      if (current()) _failure(error);
    } finally {
      if (current()) {
        loading = false;
        _emit();
      }
    }
  }

  void _failure(Object error) {
    message = error is AdminFailure
        ? error.message
        : 'Chưa tải được dữ liệu quản trị. Hãy thử lại.';
    if (error is AdminFailure && error.accessDenied) {
      access = const AdminAccess('', '');
      _clearData();
      live = false;
      unawaited(_events?.cancel());
      _events = null;
      _poll?.cancel();
      _poll = null;
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(refresh()),
    );
  }

  void selectSection(String value) {
    if (!allowed ||
        section == value ||
        !['accounts', 'topics', 'builder'].contains(value)) {
      return;
    }
    section = value;
    search = '';
    offset = 0;
    _request++;
    _clearData();
    unawaited(refresh());
  }

  void setSearch(String value) {
    search = value.trim();
    offset = 0;
    _request++;
    accounts = [];
    topics = [];
    total = 0;
    _emit();
    _scheduleRefresh();
  }

  void page(int value) {
    if (loading || value < 0 || value >= total) return;
    offset = value;
    unawaited(refresh());
  }

  Future<bool> _mutate(String type, Map<String, dynamic> payload) async {
    if (!allowed || busy) return false;
    final owner = _owner!, epoch = _epoch;
    final fingerprint = '$type:${jsonEncode(payload)}';
    final operation = _operationIds.putIfAbsent(fingerprint, learningUuid);
    busy = true;
    message = null;
    _emit();
    try {
      await repository.mutate(owner, operation, type, payload);
      if (_disposed || epoch != _epoch) return false;
      _operationIds.remove(fingerprint);
      await refresh();
      return allowed;
    } catch (error) {
      if (!_disposed && epoch == _epoch) _failure(error);
      return false;
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _emit();
      }
    }
  }

  Future<bool> setAccountStatus(AdminAccount account, String status) =>
      _mutate('account.status', {'id': account.id, 'status': status});
  Future<bool> saveTopic(AdminTopic topic) =>
      _mutate('topic.save', topic.toPayload());

  Future<List<Map<String, dynamic>>> loadLessons(String topicId) async {
    if (!allowed) return [];
    final owner = _owner!, epoch = _epoch;
    try {
      final data = await repository.read(owner, 'lessons:$topicId');
      if (_disposed || epoch != _epoch || !allowed) return [];
      return (data['items'] as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (error) {
      if (!_disposed && epoch == _epoch) {
        _failure(error);
        _emit();
      }
      rethrow;
    }
  }

  Future<bool> saveLesson(Map<String, dynamic> payload) =>
      _mutate('lesson.save', payload);

  Future<bool> saveBuilderDraft(Map<String, dynamic> payload) =>
      _mutate('lesson.draft', payload);
  Future<List<Map<String, dynamic>>> loadBuilderDrafts(String topic) async {
    if (!allowed) return [];
    final owner = _owner!, epoch = _epoch;
    try {
      final response = await repository.read(owner, 'drafts:$topic');
      if (_disposed || epoch != _epoch || !allowed) return [];
      return (response['items'] as List)
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
    } catch (error) {
      if (!_disposed && epoch == _epoch) {
        _failure(error);
        _emit();
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>?> generateSlides(
    String prompt,
    String topic,
    Map<String, dynamic> design,
  ) async {
    final generator = repository;
    if (!allowed || busy || generator is! AdminSlideGenerator) return null;
    final owner = _owner!, epoch = _epoch;
    busy = true;
    message = null;
    _emit();
    try {
      final slides = await (generator as AdminSlideGenerator).generateSlides(
        owner,
        prompt,
        topic,
        design,
      );
      if (_disposed || epoch != _epoch || !allowed) return null;
      return slides;
    } catch (error) {
      if (!_disposed && epoch == _epoch) {
        _failure(error);
        _emit();
      }
      return null;
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _emit();
      }
    }
  }

  Future<Map<String, dynamic>?> generateLesson(
    String prompt,
    String topic,
  ) async {
    final generator = repository;
    if (!allowed || busy || generator is! AdminLessonGenerator) return null;
    final owner = _owner!, epoch = _epoch;
    busy = true;
    message = null;
    _emit();
    try {
      final draft = await (generator as AdminLessonGenerator).generateLesson(
        owner,
        prompt,
        topic,
      );
      if (_disposed || epoch != _epoch || !allowed) return null;
      return draft;
    } catch (error) {
      if (!_disposed && epoch == _epoch) {
        _failure(error);
        _emit();
      }
      return null;
    } finally {
      if (!_disposed && epoch == _epoch) {
        busy = false;
        _emit();
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    if (busy) return;
    busy = true;
    message = null;
    _emit();
    try {
      await auth.signIn(email.trim(), password);
    } catch (_) {
      message = 'Chưa đăng nhập được. Kiểm tra email, mật khẩu và kết nối.';
    } finally {
      if (!_disposed) {
        busy = false;
        _emit();
      }
    }
  }

  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (_) {
      message = 'Chưa đăng xuất được. Hãy thử lại.';
      _emit();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _poll?.cancel();
    _debounce?.cancel();
    unawaited(_events?.cancel());
    unawaited(_authChanges?.cancel());
    super.dispose();
  }
}
