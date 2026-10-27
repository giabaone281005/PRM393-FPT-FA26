import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../learning_store.dart';
import '../models/cloud_backup.dart';
import '../models/app_failure.dart';
import '../repositories/auth_repository.dart';
import '../repositories/backup_repository.dart';

class CloudBackupController extends ChangeNotifier {
  CloudBackupController({
    required this.store,
    required this.auth,
    required this.repository,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now {
    _links = _bindings();
    _owner = auth.userId;
    _subscription = auth.changes.listen(
      _accountChanged,
      onError: (Object error) {
        noticeKind = NoticeKind.error;
        message = friendlyError(
          error,
          fallback:
              'Chưa cập nhật được phiên tài khoản. Hãy thử đăng nhập lại.',
        );
        _emit();
      },
    );
    store.addListener(_localChanged);
    _retry = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _localChanged(),
    );
    if (_owner != null) unawaited(refresh());
  }
  final LearningStore store;
  final AuthRepository auth;
  final BackupRepository repository;
  final DateTime Function() _now;
  StreamSubscription<String?>? _subscription;
  Timer? _debounce, _retry;
  String? _owner;
  String? _verificationEmail;
  DateTime? _resendAfter;
  String? get verificationEmail => _verificationEmail;
  int get resendSecondsRemaining {
    final milliseconds = _resendAfter?.difference(_now()).inMilliseconds ?? 0;
    return milliseconds <= 0 ? 0 : (milliseconds + 999) ~/ 1000;
  }

  late final Map<String, dynamic> _links;
  bool _disposed = false;
  bool busy = false;
  bool conflict = false;
  String? message;
  NoticeKind noticeKind = NoticeKind.info;
  List<CloudBackup> backups = [];
  final Map<String, String> _lastSaved = {};
  String? get email => auth.email;
  bool get signedIn => _owner != null;
  String? get userId => _owner;
  bool canUseProfile(String id) {
    final link = _links[id];
    return signedIn &&
        (link == null || (link is Map && link['owner'] == _owner));
  }

  List<LearnerProfile> get profiles =>
      store.profiles.where((profile) => canUseProfile(profile.id)).toList();
  String get _bindingKey => 'matlingo:cloud-links:v1';

  Map<String, dynamic> _bindings() {
    try {
      return Map<String, dynamic>.from(
        jsonDecode(store.preferences.getString(_bindingKey) ?? '{}') as Map,
      );
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic>? get currentBinding {
    final binding = _links[store.profile?.id];
    return binding is Map && binding['owner'] == _owner && _owner != null
        ? Map<String, dynamic>.from(binding)
        : null;
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void _accountChanged(String? owner) {
    if (owner == _owner) return;
    final previousOwner = _owner;
    _owner = owner;
    if (owner != null) {
      _verificationEmail = null;
      _resendAfter = null;
    }
    _debounce?.cancel();
    backups = [];
    conflict = false;
    message = null;
    noticeKind = NoticeKind.info;
    if (previousOwner != null ||
        (store.profile != null && !canUseProfile(store.profile!.id))) {
      unawaited(store.signOut());
    }
    _emit();
    _localChanged();
  }

  void _localChanged() {
    _debounce?.cancel();
    if (_disposed ||
        store.profile == null ||
        !canUseProfile(store.profile!.id)) {
      return;
    }
    final id = store.profile!.id;
    if (currentBinding == null) {
      _links[id] = {'owner': _owner, 'key': id, 'revision': 0};
      // Claim ownership before uploading, including when the network is offline.
      unawaited(
        _persistLinks().catchError((Object _) {
          noticeKind = NoticeKind.error;
          message = 'Chưa lưu được liên kết tài khoản. Hãy thử lưu lại.';
          _emit();
        }),
      );
    }
    if (busy || conflict) return;
    if (_lastSaved['$_owner/$id'] == jsonEncode(store.exportProfile(id))) {
      return;
    }
    message = 'Có thay đổi đang chờ sao lưu cloud.';
    noticeKind = NoticeKind.info;
    _emit();
    _debounce = Timer(
      const Duration(seconds: 2),
      () => unawaited(saveCurrent(automatic: true)),
    );
  }

  Future<bool> _run(
    Future<void> Function() action, {
    String failureMessage = 'Chưa hoàn tất thao tác. Vui lòng thử lại; nếu vẫn gặp lỗi, liên hệ hỗ trợ.',
  }) async {
    if (busy || _disposed) return false;
    busy = true;
    message = null;
    noticeKind = NoticeKind.info;
    _emit();
    var completed = false;
    try {
      await action();
      completed = true;
      return true;
    } on BackupConflict {
      noticeKind = NoticeKind.error;
      conflict = true;
      message = 'Bản cloud đã thay đổi trên máy khác. Tải lại danh sách và khôi phục thành hồ sơ riêng để giữ cả hai bản.';
    } catch (error) {
      noticeKind = NoticeKind.error;
      message = friendlyError(error, fallback: failureMessage);
    } finally {
      busy = false;
      _emit();
      if (completed) {
        _localChanged();
      }
    }
    return false;
  }

  Future<void> signIn(
    String email,
    String password, {
    bool register = false,
  }) async {
    final address = email.trim();
    final success = await _run(() async {
      if (register) {
        final immediate = await auth.signUp(address, password);
        if (!immediate) {
          _verificationEmail = address;
          _resendAfter = _now().add(const Duration(seconds: 60));
          message = 'Nhập mã trong email để hoàn tất đăng ký. Nếu email đã có tài khoản, hãy quay lại đăng nhập bằng mật khẩu cũ.';
          return;
        }
      } else {
        try {
          await auth.signIn(address, password);
        } on AuthException catch (error) {
          if (error.code == 'email_not_confirmed') {
            _verificationEmail = address;
          }
          rethrow;
        }
      }
      _accountChanged(auth.userId);
      if (_owner != null) {
        final owner = _owner!;
        final rows = await repository.list(owner);
        if (_owner == owner) backups = rows;
      }
    });
    if (success && signedIn && store.profile != null) {
      await saveCurrent(automatic: true);
    }
  }

  /// Allows returning to an already received code after closing/reopening app.
  void beginEmailVerification(String email) {
    if (busy || signedIn) return;
    final address = email.trim();
    if (address.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(address)) {
      message = 'Nhập email hợp lệ trước khi nhập mã.';
      noticeKind = NoticeKind.error;
    } else {
      if (_verificationEmail != address) _resendAfter = null;
      _verificationEmail = address;
      message = null;
      noticeKind = NoticeKind.info;
    }
    _emit();
  }

  void cancelEmailVerification() {
    if (busy) return;
    _verificationEmail = null;
    message = null;
    noticeKind = NoticeKind.info;
    _emit();
  }

  Future<void> verifyEmailCode(String code) async {
    final address = _verificationEmail;
    if (address == null || busy || signedIn) return;
    final token = code.trim();
    if (!RegExp(r'^\d{6,10}$').hasMatch(token)) {
      message = 'Nhập đầy đủ mã số trong email (6–10 chữ số).';
      noticeKind = NoticeKind.error;
      _emit();
      return;
    }
    final success = await _run(() async {
      await auth.verifyEmailCode(address, token);
      _accountChanged(auth.userId);
      if (!signedIn) {
        throw const AuthException('Email verification requires a session.');
      }
    });
    if (success && signedIn) {
      await refresh();
      await saveCurrent(automatic: true);
    }
  }

  /// Success means the server accepted the request, not guaranteed delivery.
  Future<bool> resendConfirmation() async {
    final address = _verificationEmail;
    if (address == null || busy || signedIn || resendSecondsRemaining > 0) {
      return false;
    }
    // Keep a local cooldown even if the server rejects the request. Server-side
    // email/IP rate limits remain authoritative across devices and restarts.
    _resendAfter = _now().add(const Duration(seconds: 60));
    return _run(() async {
      await auth.resendConfirmation(address);
      noticeKind = NoticeKind.success;
      message = 'Yêu cầu gửi lại đã được xử lý. Kiểm tra email và thư Spam; dùng mã mới nhất nếu có.';
    });
  }

  Future<void> signOut() async {
    if (busy) {
      message = 'Đang xử lý yêu cầu trước đó. Chờ một chút rồi chọn Đăng xuất lại nhé.';
      noticeKind = NoticeKind.info;
      _emit();
      return;
    }
    await _run(() async {
      await auth.signOut();
      _accountChanged(null);
    });
  }

  Future<void> refresh() async {
    await _run(() async {
      final owner = _owner;
      if (owner == null) return;
      final rows = await repository.list(owner);
      if (_owner == owner) backups = rows;
    });
  }

  Future<void> _bind(String localId, String owner, CloudBackup backup) async {
    _links[localId] = {
      'owner': owner,
      'key': backup.key,
      'revision': backup.revision,
      'updatedAt': backup.updatedAt.toUtc().toIso8601String(),
    };
    await _persistLinks();
  }

  Future<void> _persistLinks() async {
    if (!await store.preferences.setString(_bindingKey, jsonEncode(_links))) {
      throw const AppFailure(
        'Chưa lưu được liên kết tài khoản trên thiết bị. Tiến độ của bạn vẫn được giữ; hãy thử lại.',
      );
    }
  }

  Future<void> saveCurrent({bool automatic = false}) async {
    if (conflict ||
        store.profile == null ||
        !canUseProfile(store.profile!.id)) {
      return;
    }
    await _run(
      () async {
        final owner = _owner;
        final localId = store.profile?.id;
        if (owner == null || localId == null) return;
        _links[localId] ??= {'owner': owner, 'key': localId, 'revision': 0};
        final binding = Map<String, dynamic>.from(_links[localId] as Map);
        await _persistLinks();
        await store.flush();
        if (store.saveError != null) throw AppFailure(store.saveError!);
        if (_owner != owner) return;
        final remoteKey = binding['key'] as String? ?? localId;
        final payload = store.exportProfile(localId);
        // The restored local ID differs; keep a stable source key in the cloud.
        (payload['profile'] as Map)['id'] = remoteKey;
        final revision = (binding['revision'] as num?)?.toInt() ?? 0;
        final backup = await repository.save(
          owner,
          remoteKey,
          revision,
          payload,
        );
        if (_disposed || _owner != owner) return;
        await _bind(localId, owner, backup);
        if (_disposed || _owner != owner) return;
        final savedLocal =
            jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
        (savedLocal['profile'] as Map)['id'] = localId;
        _lastSaved['$owner/$localId'] = jsonEncode(savedLocal);
        backups = [backup, ...backups.where((row) => row.key != backup.key)];
        conflict = false;
        message = 'Đã lưu hồ sơ và tiến độ lên cloud.';
        noticeKind = NoticeKind.success;
      },
      failureMessage: 'Chưa hoàn tất sao lưu. Tiến độ trên thiết bị vẫn được giữ; hãy thử lưu lại.',
    );
  }

  Future<void> restore(CloudBackup backup) async {
    await _run(
      () async {
        final owner = _owner;
        if (owner == null) return;
        final localId = await store.restoreProfile(backup.payload);
        if (_disposed || owner != _owner) return;
        await _bind(localId, owner, backup);
        conflict = false;
        message = 'Đã tải về thành hồ sơ riêng. Chọn hồ sơ này để học tiếp.';
        noticeKind = NoticeKind.success;
      },
      failureMessage: 'Chưa hoàn tất khôi phục. Các hồ sơ trên thiết bị vẫn được giữ; hãy thử lại.',
    );
  }

  @override
  void dispose() {
    _disposed = true;
    store.removeListener(_localChanged);
    _debounce?.cancel();
    _retry?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
