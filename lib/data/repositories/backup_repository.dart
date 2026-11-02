import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cloud_backup.dart';

abstract class BackupRepository {
  Future<List<CloudBackup>> list(String owner);
  Future<CloudBackup> save(
    String owner,
    String key,
    int revision,
    Map<String, dynamic> payload,
  );
}

class SupabaseBackupRepository implements BackupRepository {
  SupabaseBackupRepository(this.client);
  final SupabaseClient client;
  @override
  Future<List<CloudBackup>> list(String owner) async {
    final rows = await client
        .from('mobile_profile_backups')
        .select()
        .eq('owner_user_id', owner)
        .order('updated_at', ascending: false)
        .timeout(const Duration(seconds: 20));
    return rows.map(CloudBackup.fromJson).toList();
  }

  @override
  Future<CloudBackup> save(
    String owner,
    String key,
    int revision,
    Map<String, dynamic> payload,
  ) async {
    try {
      final row = await client
          .rpc(
            'save_mobile_backup',
            params: {
              'expected_owner': owner,
              'profile_key': key,
              'expected_revision': revision,
              'backup_payload': payload,
            },
          )
          .timeout(const Duration(seconds: 20));
      return CloudBackup.fromJson(Map<String, dynamic>.from(row as Map));
    } on PostgrestException catch (error) {
      if (error.code == 'PT409' || error.code == '40001') {
        throw const BackupConflict();
      }
      rethrow;
    }
  }
}

/// New clients use one server-pinned progress record; legacy backups remain readable.
class SupabaseAccountProgressRepository implements BackupRepository {
  SupabaseAccountProgressRepository(this.client);
  final SupabaseClient client;
  void _check(String owner) {
    if (client.auth.currentUser?.id != owner) {
      throw const AuthException('Account changed');
    }
  }

  @override
  Future<List<CloudBackup>> list(String owner) async {
    _check(owner);
    final row = await client
        .rpc('load_account_progress', params: {'expected_owner': owner})
        .timeout(const Duration(seconds: 20));
    _check(owner);
    return row == null
        ? []
        : [CloudBackup.fromJson(Map<String, dynamic>.from(row as Map))];
  }

  @override
  Future<CloudBackup> save(
    String owner,
    String key,
    int revision,
    Map<String, dynamic> payload,
  ) async {
    _check(owner);
    try {
      final row = await client
          .rpc(
            'save_account_progress',
            params: {
              'expected_owner': owner,
              'expected_revision': revision,
              'backup_payload': payload,
            },
          )
          .timeout(const Duration(seconds: 20));
      _check(owner);
      return CloudBackup.fromJson(Map<String, dynamic>.from(row as Map));
    } on PostgrestException catch (error) {
      if (['PT409', '40001'].contains(error.code)) throw const BackupConflict();
      rethrow;
    }
  }
}
