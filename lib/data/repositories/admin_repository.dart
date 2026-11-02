import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_dashboard.dart';
import '../models/app_failure.dart';

class AdminFailure extends AppFailure {
  const AdminFailure(super.message, {this.accessDenied = false});
  final bool accessDenied;
}

abstract class AdminRepository {
  Future<AdminAccess> access(String owner);
  Future<Map<String, dynamic>> read(
    String owner,
    String section, {
    String search = '',
    int offset = 0,
  });
  Future<void> mutate(
    String owner,
    String operationId,
    String type,
    Map<String, dynamic> payload,
  );
  Stream<AdminRealtimeEvent> watch(String owner);
}

class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this.client);
  final SupabaseClient client;

  void _check(String owner) {
    if (client.auth.currentUser?.id != owner ||
        client.auth.currentSession == null) {
      throw const AdminFailure(
        'Phiên đăng nhập đã thay đổi. Hãy đăng nhập lại.',
        accessDenied: true,
      );
    }
  }

  Future<dynamic> _rpc(
    String owner,
    String name,
    Map<String, dynamic> params,
  ) async {
    _check(owner);
    try {
      final data = await client
          .rpc(name, params: params)
          .timeout(const Duration(seconds: 20));
      _check(owner);
      return data;
    } on AdminFailure {
      rethrow;
    } on PostgrestException catch (error) {
      if (['42501', 'PGRST301', 'PGRST303'].contains(error.code)) {
        throw const AdminFailure(
          'Quyền quản trị hoặc phiên đăng nhập không còn hợp lệ.',
          accessDenied: true,
        );
      }
      throw const AdminFailure(
        'Chưa cập nhật được dữ liệu. Kiểm tra nội dung và thử lại.',
      );
    } catch (_) {
      throw const AdminFailure(
        'Chưa kết nối được máy chủ. Kiểm tra mạng rồi thử lại.',
      );
    }
  }

  @override
  Future<AdminAccess> access(String owner) async {
    final rows = await _rpc(owner, 'get_my_access', {}) as List;
    if (rows.length != 1) return const AdminAccess('', '');
    return AdminAccess(
      rows.first['role'] as String,
      rows.first['status'] as String,
    );
  }

  @override
  Future<Map<String, dynamic>> read(
    String owner,
    String section, {
    String search = '',
    int offset = 0,
  }) async => Map<String, dynamic>.from(
    await _rpc(owner, 'admin_dashboard_read', {
      'section': section,
      'search_text': search,
      'page_offset': offset,
      'page_size': 25,
    }) as Map,
  );

  @override
  Future<void> mutate(
    String owner,
    String operationId,
    String type,
    Map<String, dynamic> payload,
  ) async {
    await _rpc(owner, 'admin_learning_mutate', {
      'operation_id': operationId,
      'operation_type': type,
      'payload': payload,
    });
  }

  @override
  Stream<AdminRealtimeEvent> watch(String owner) {
    late StreamController<AdminRealtimeEvent> events;
    RealtimeChannel? channel;
    var cancelled = false;
    events = StreamController<AdminRealtimeEvent>(
      onListen: () async {
        try {
          _check(owner);
          await client.realtime.setAuth(
            client.auth.currentSession!.accessToken,
          );
          if (cancelled) return;
          channel =
              client.channel(
                  'matlingo:admin',
                  opts: const RealtimeChannelConfig(private: true),
                )
                ..onBroadcast(
                  event: 'changed',
                  callback: (_) {
                    if (!cancelled) {
                      events.add(
                        const AdminRealtimeEvent(
                          connected: true,
                          changed: true,
                        ),
                      );
                    }
                  },
                )
                ..subscribe((status, error) {
                  if (!cancelled) {
                    events.add(
                      AdminRealtimeEvent(
                        connected: status == RealtimeSubscribeStatus.subscribed,
                        changed: status == RealtimeSubscribeStatus.subscribed,
                      ),
                    );
                  }
                });
        } catch (_) {
          if (!cancelled) {
            events.add(const AdminRealtimeEvent(connected: false));
          }
        }
      },
      onCancel: () async {
        cancelled = true;
        if (channel != null) await client.removeChannel(channel!);
      },
    );
    return events.stream;
  }
}
