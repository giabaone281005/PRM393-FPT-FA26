import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class EngineStorage {
  Future<String?> read();
  Future<void> write(String snapshot);
}

/// One encrypted snapshot keeps selection, metadata and credentials consistent.
/// This key is account-scoped and is never part of LearningStore/cloud backups.
class SecureEngineStorage implements EngineStorage {
  SecureEngineStorage(String accountId, {FlutterSecureStorage? storage})
    : _key = 'matlingo.engines.v1.$accountId',
      _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
            ),
          );
  final String _key;
  final FlutterSecureStorage _storage;
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String snapshot) =>
      _storage.write(key: _key, value: snapshot);
}
