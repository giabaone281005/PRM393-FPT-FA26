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

abstract class AdminLessonGenerator {
  Future<Map<String, dynamic>> generateLesson(
    String owner,
    String prompt,
    String topic,
  );
}

abstract class AdminSlideGenerator {
  Future<List<Map<String, dynamic>>> generateSlides(
    String owner,
    String prompt,
    String topic,
    Map<String, dynamic> design,
  );
}

class SupabaseAdminRepository
    implements AdminRepository, AdminLessonGenerator, AdminSlideGenerator {
  SupabaseAdminRepository(this.client);
  final SupabaseClient client;

  @override
  Future<List<Map<String, dynamic>>> generateSlides(
    String owner,
    String prompt,
    String topic,
    Map<String, dynamic> design,
  ) async {
    _check(owner);
    try {
      final response = await client.functions
          .invoke(
            'author-lesson',
            body: {'prompt': prompt, 'topic': topic, 'design': design},
          )
          .timeout(const Duration(seconds: 65));
      _check(owner);
      final data = response.data;
      if (data is! Map ||
          data['draft'] is! Map ||
          data['draft']['slides'] is! List) {
        throw const AdminFailure('Gemini chưa trả về cấu trúc slide hợp lệ.');
      }
      return (data['draft']['slides'] as List)
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
    } on AdminFailure {
      rethrow;
    } on FunctionException catch (error) {
      throw AdminFailure(
        error.status == 429
            ? 'Gemini đang giới hạn số lượt tạo. Chờ một phút rồi thử lại.'
            : 'Chưa tạo được nội dung. Kiểm tra thiết kế và thử lại.',
        accessDenied: error.status == 401 || error.status == 403,
      );
    } catch (_) {
      throw const AdminFailure(
        'Chưa kết nối được Gemini. Thiết kế của bạn vẫn được giữ.',
      );
    }
  }

  void _check(String owner) {
    if (client.auth.currentUser?.id != owner ||
        client.auth.currentSession == null) {
      throw const AdminFailure(
        'Phiên đăng nhập đã thay đổi. Hãy đăng nhập lại.',
        accessDenied: true,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> generateLesson(
    String owner,
    String prompt,
    String topic,
  ) async {
    _check(owner);
    try {
      final response = await client.functions
          .invoke('author-lesson', body: {'prompt': prompt, 'topic': topic})
          .timeout(const Duration(seconds: 55));
      _check(owner);
      final data = response.data;
      if (data is! Map || data['draft'] is! Map) {
        throw const AdminFailure(
          'Gemini chưa trả về bản nháp hợp lệ. Hãy thử lại.',
        );
      }
      return Map<String, dynamic>.from(data['draft'] as Map);
    } on AdminFailure {
      rethrow;
    } on FunctionException catch (error) {
      if (error.status == 401 || error.status == 403) {
        throw const AdminFailure(
          'Phiên đăng nhập hoặc quyền quản trị đã thay đổi.',
          accessDenied: true,
        );
      }
      throw const AdminFailure(
        'Chưa tạo được bản nháp. Gemini có thể đang bận; hãy thử lại sau.',
      );
    } catch (_) {
      throw const AdminFailure(
        'Chưa kết nối được Gemini. Nội dung bạn đang soạn được giữ lại.',
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
      if (error.code == 'PT409') {
        throw const AdminFailure(
          'Nội dung đã được sửa ở nơi khác. Quay lại danh sách, tải lại bài học rồi cập nhật.',
        );
      }
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
    await _rpc(
      owner,
      section.startsWith('drafts:')
          ? 'admin_builder_read'
          : section.startsWith('lessons:')
          ? 'admin_content_read'
          : 'admin_dashboard_read',
      section.startsWith('drafts:')
          ? {'topic': section.substring(7)}
          : section.startsWith('lessons:')
          ? {'topic': section.substring(8)}
          : {
              'section': section,
              'search_text': search,
              'page_offset': offset,
              'page_size': 25,
            },
    ) as Map,
  );

  @override
  Future<void> mutate(
    String owner,
    String operationId,
    String type,
    Map<String, dynamic> payload,
  ) async {
    await _rpc(
      owner,
      type == 'lesson.draft'
          ? 'admin_builder_save'
          : type == 'lesson.save'
          ? 'admin_content_mutate'
          : 'admin_learning_mutate',
      {
        'operation_id': operationId,
        if (!['lesson.save', 'lesson.draft'].contains(type))
          'operation_type': type,
        'payload': payload,
      },
    );
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
