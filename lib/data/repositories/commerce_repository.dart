import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/commerce_models.dart';

class PaymentSession {
  final String orderId;
  final String provider; // 'momo' hoặc 'vnpay'
  final Uri payUrl;
  final String? deeplink; // chỉ MoMo
  final String? qrData; // chỉ MoMo
  const PaymentSession({
    required this.orderId,
    required this.provider,
    required this.payUrl,
    this.deeplink,
    this.qrData,
  });
}

class CommerceRepository {
  static SupabaseClient get _client {
    final client = SupabaseService.client;
    if (client == null || client.auth.currentSession == null) {
      throw StateError('Vui lòng đăng nhập để quản lý gói học tập.');
    }
    return client;
  }

  static String newRequestId() {
    final random = Random.secure();
    final b = List.generate(16, (_) => random.nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  static Future<List<PlanPrice>> fetchPrices({bool admin = false}) async {
    var query = _client
        .from('plan_prices')
        .select('*, learning_plans!inner(published)');
    if (!admin) {
      query = query.eq('published', true).eq('learning_plans.published', true);
    }
    final rows = await query.order('duration_months');
    return rows.map(PlanPrice.fromMap).toList();
  }

  static Future<List<LearningOrder>> fetchOrders({
    bool admin = false,
    int page = 0,
  }) async {
    var query = _client.from('learning_orders').select();
    if (!admin) query = query.eq('parent_id', _client.auth.currentUser!.id);
    final rows = await query
        .order('created_at', ascending: false)
        .range(page * 20, page * 20 + 19);
    return rows.map(LearningOrder.fromMap).toList();
  }

  static Future<Uri> checkout({
    required String parentToken,
    String? priceId,
    String? requestId,
    String? orderId,
  }) async {
    final response = await _client.functions.invoke(
      'vnpay-checkout',
      body: {
        'parentToken': parentToken,
        'orderId': ?orderId,
        'priceId': ?priceId,
        'requestId': ?requestId,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (response.status != 200 || data['checkoutUrl'] == null) {
      throw StateError(
        data['error']?.toString() ?? 'Không thể tạo thanh toán.',
      );
    }
    final uri = Uri.parse(data['checkoutUrl'] as String);
    if (uri.scheme != 'https' ||
        !['sandbox.vnpayment.vn', 'pay.vnpay.vn'].contains(uri.host)) {
      throw StateError('Địa chỉ thanh toán không hợp lệ.');
    }
    return uri;
  }

  static Future<PaymentSession> startPayment({
    required String provider, // 'momo' hoặc 'vnpay'
    required String parentToken,
    String? priceId,
    String? requestId,
    String? orderId,
  }) async {
    final response = await _client.functions.invoke(
      provider == 'momo' ? 'momo-checkout' : 'vnpay-checkout',
      body: {
        'parentToken': parentToken,
        'orderId': ?orderId,
        'priceId': ?priceId,
        'requestId': ?requestId,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final id = (data['order'] as Map?)?['id']?.toString();
    final url =
    (provider == 'momo' ? data['payUrl'] : data['checkoutUrl']) as String?;
    if (response.status != 200 || id == null || url == null) {
      throw StateError(
        data['error']?.toString() ?? 'Không thể tạo thanh toán.',
      );
    }
    final uri = Uri.parse(url);
    const allowedHosts = [
      'sandbox.vnpayment.vn',
      'pay.vnpay.vn',
      'test-payment.momo.vn',
      'payment.momo.vn',
    ];
    if (uri.scheme != 'https' || !allowedHosts.contains(uri.host)) {
      throw StateError('Địa chỉ thanh toán không hợp lệ.');
    }
    return PaymentSession(
      orderId: id,
      provider: provider,
      payUrl: uri,
      deeplink: data['deeplink'] as String?,
      qrData: data['qrCodeUrl'] as String?,
    );
  }

  static Future<String> fetchOrderStatus(String orderId) async {
    final row = await _client
        .from('learning_orders')
        .select('status')
        .eq('id', orderId)
        .single();
    return row['status'] as String;
  }

  static Future<void> reconcile(String orderId) async {
    final res = await _client.functions.invoke(
      'vnpay-query',
      body: {'orderId': orderId},
    );
    if (res.status != 200) throw StateError('Chưa đối soát được với VNPay.');
  }

  static Future<void> savePrice(
      PlanPrice price, {
        required String label,
        required int amount,
        required bool published,
        required bool newVersion,
      }) async {
    final values = {
      'plan_id': price.planId,
      'label': label,
      'amount_vnd': amount,
      'duration_months': price.durationMonths,
      'published': published,
    };
    if (newVersion) {
      await _client.from('plan_prices').insert(values);
    } else {
      await _client
          .from('plan_prices')
          .update(values)
          .eq('id', price.id)
          .select()
          .single();
    }
  }
}