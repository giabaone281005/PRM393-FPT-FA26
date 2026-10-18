import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';

class AiTutorRepository {
  static SupabaseClient _client(SupabaseClient? client) =>
      client ??
      SupabaseService.client ??
      (throw StateError('Chưa kết nối máy chủ.'));

  static Future<bool> isEnabled({SupabaseClient? client}) async {
    final row = await _client(client)
        .from('ai_settings')
        .select('enabled')
        .eq('id', true)
        .single();
    return row['enabled'] == true;
  }

  static Future<Map<String, dynamic>> request({
    required String kidId,
    required String requestId,
    required String phase,
    Uint8List? image,
    String? mime,
    String? problem,
    SupabaseClient? client,
  }) async {
    if (phase != 'ocr' && phase != 'hint') {
      throw const FormatException('Yêu cầu AI không hợp lệ.');
    }
    if (phase == 'ocr' && (image == null || image.length > 3 * 1024 * 1024)) {
      throw const FormatException('Chọn ảnh JPEG/PNG dưới 3 MB.');
    }
    final response = await _client(client).functions.invoke(
      'ai-tutor',
      body: {
        'kidId': kidId,
        'requestId': requestId,
        'phase': phase,
        if (phase == 'ocr') ...{
          'image': base64Encode(image!),
          'mime': mime,
        } else
          'problem': problem?.trim(),
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (phase == 'ocr'
        ? data['problem'] is! String
        : data['supported'] is! bool ||
              data['hints'] is! List ||
              !(data['hints'] as List).every((hint) => hint is String)) {
      throw const FormatException(
        'Dịch vụ trả dữ liệu không hợp lệ. Vui lòng thử lại.',
      );
    }
    return data;
  }
}
