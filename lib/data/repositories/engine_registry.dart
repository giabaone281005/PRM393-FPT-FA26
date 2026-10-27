import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/engine_config.dart';
import '../models/app_failure.dart';
import 'engine_storage.dart';

class EngineFailure extends AppFailure {
  const EngineFailure(super.message);
}

/// An immutable request snapshot. Never serialize/log this object or its secret.
class EngineSelection {
  const EngineSelection(this.config, this.credential);
  final EngineConfig config;
  final String? credential;
}

class _Entry {
  const _Entry(this.config, this.credential);
  final EngineConfig config;
  final String? credential;
}

/// All mutations are serialized; listeners see a change only after durable save.
/// Failed writes leave both the running configuration and selection unchanged.
class EngineRegistry extends ChangeNotifier {
  EngineRegistry(EngineStorage storage) : _storage = storage;
  final EngineStorage _storage;
  Map<String, _Entry> _entries = {};
  Map<EngineKind, String> _active = {};
  Future<void> _queue = Future.value();
  bool _disposed = false;
  bool _loaded = false;
  String? _loadError;
  bool get loaded => _loaded;
  String? get loadError => _loadError;
  List<EngineConfig> get engines =>
      List.unmodifiable(_entries.values.map((entry) => entry.config));
  EngineConfig? active(EngineKind kind) => _entries[_active[kind]]?.config;
  bool hasCredential(String id) => _entries[id]?.credential != null;

  Future<T> _serial<T>(Future<T> Function() action) {
    final operation = _queue.then((_) {
      if (_disposed) {
        throw const EngineFailure(
          'Phiên cài đặt đã kết thúc. Mở lại Engine học tập để tiếp tục.',
        );
      }
      return action();
    });
    // An error must not poison the queue for the next retry.
    _queue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace stack) {},
    );
    return operation;
  }

  Future<void> initialize() => _serial(() async {
    try {
      final raw = await _storage.read();
      final entries = <String, _Entry>{};
      final active = <EngineKind, String>{};
      if (raw != null) {
        final snapshot = jsonDecode(raw) as Map<String, dynamic>;
        if (snapshot['version'] != 1) throw const FormatException();
        for (final value in snapshot['engines'] as List) {
          final row = Map<String, dynamic>.from(value as Map);
          final config = EngineConfig.fromJson(
            Map<String, dynamic>.from(row['config'] as Map),
          );
          final credential = row['credential'] as String?;
          if (entries.containsKey(config.id) || credential == '') {
            throw const FormatException();
          }
          entries[config.id] = _Entry(config, credential);
        }
        for (final item in (snapshot['active'] as Map).entries) {
          final kind = EngineKind.values.byName(item.key as String);
          final id = item.value as String;
          if (entries[id]?.config.kind != kind) throw const FormatException();
          active[kind] = id;
        }
      }
      if (_disposed) return;
      _entries = entries;
      _active = active;
      _loaded = true;
      _loadError = null;
    } catch (_) {
      // Preserve the stored bytes: corrupt/locked storage is never overwritten.
      _loadError = 'Chưa đọc được cấu hình đã lưu trên thiết bị. Hãy tải lại; nếu vẫn gặp lỗi, liên hệ hỗ trợ. Cấu hình cũ được giữ nguyên.';
      _loaded = false;
    }
    if (!_disposed) notifyListeners();
  });

  void _requireLoaded() {
    if (!loaded) {
      throw const EngineFailure(
        'Chờ cấu hình tải xong hoặc chọn Tải lại trong Engine học tập.',
      );
    }
  }

  Future<void> _commit(
    Map<String, _Entry> entries,
    Map<EngineKind, String> active,
  ) async {
    try {
      await _storage.write(
        jsonEncode({
          'version': 1,
          'engines': entries.values
              .map(
                (entry) => {
                  'config': entry.config.toJson(),
                  'credential': entry.credential,
                },
              )
              .toList(),
          'active': {
            for (final entry in active.entries) entry.key.name: entry.value,
          },
        }),
      );
    } catch (_) {
      throw const EngineFailure('Chưa lưu được cấu hình vào bộ nhớ bảo mật.');
    }
    if (_disposed) return;
    _entries = entries;
    _active = active;
    notifyListeners();
  }

  Future<void> register(EngineConfig config, {String? credential}) =>
      _serial(() async {
        _requireLoaded();
        if (_entries.containsKey(config.id)) {
          throw const EngineFailure(
            'Kết nối này đã tồn tại. Hãy chỉnh sửa kết nối hiện có.',
          );
        }
        await _commit({
          ..._entries,
          config.id: _Entry(config, _secret(credential)),
        }, _active);
      });

  Future<void> update(
    EngineConfig config, {
    String? credential,
    bool clearCredential = false,
  }) => _serial(() async {
    _requireLoaded();
    final old = _entries[config.id];
    if (old == null) {
      throw const EngineFailure(
        'Kết nối này không còn trong danh sách. Mở lại Engine học tập để chọn kết nối khác.',
      );
    }
    if (config.kind != old.config.kind) {
      throw const EngineFailure(
        'Gia sư AI và chạy mã dùng hai loại kết nối riêng. Hãy tạo kết nối mới nếu muốn đổi loại.',
      );
    }
    if (old.credential != null &&
        credential == null &&
        !clearCredential &&
        (config.endpoint != old.config.endpoint ||
            config.provider != old.config.provider)) {
      throw const EngineFailure(
        'Nhập lại hoặc xóa khóa đã lưu khi đổi địa chỉ hay nhà cung cấp kết nối.',
      );
    }
    final secret = clearCredential
        ? null
        : credential == null
        ? old.credential
        : _secret(credential);
    await _commit({..._entries, config.id: _Entry(config, secret)}, _active);
  });

  Future<void> activate(EngineKind kind, String id) => _serial(() async {
    _requireLoaded();
    if (_entries[id]?.config.kind != kind) {
      throw const EngineFailure(
        'Kết nối đã chọn chưa phù hợp với thao tác này. Chọn lại trong Engine học tập.',
      );
    }
    await _commit(_entries, {..._active, kind: id});
  });

  Future<void> remove(String id) => _serial(() async {
    _requireLoaded();
    final entries = {..._entries}..remove(id);
    final active = {..._active}..removeWhere((_, value) => value == id);
    await _commit(entries, active);
  });

  EngineSelection resolve(EngineKind kind) {
    _requireLoaded();
    final entry = _entries[_active[kind]];
    if (entry == null) {
      throw const EngineFailure(
        'Chọn kết nối trong Engine học tập để bắt đầu nhé.',
      );
    }
    return EngineSelection(entry.config, entry.credential);
  }

  static String? _secret(String? value) {
    if (value == null) return null;
    if (value.trim().isEmpty || value.contains('\n') || value.contains('\r')) {
      throw const EngineFailure(
        'Khóa hoặc token đang trống hay chưa đúng định dạng. Kiểm tra lại rồi lưu nhé.',
      );
    }
    return value.trim();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
