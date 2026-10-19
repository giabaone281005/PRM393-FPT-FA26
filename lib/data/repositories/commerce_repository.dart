import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/commerce_models.dart';

class PaymentSession {
  final String orderId;
  final String provider; // 'momo', 'vnpay', 'demo-momo' hoặc 'demo-vnpay'
  final Uri payUrl;
  final String? deeplink; // chỉ MoMo
  final String? qrData; // MoMo hoặc demo
  final int? amountVnd;
  final String? gatewayOrderId; // mã đơn kiểu MoMo/VNPay (chỉ demo)
  const PaymentSession({
    required this.orderId,
    required this.provider,
    required this.payUrl,
    this.deeplink,
    this.qrData,
    this.amountVnd,
    this.gatewayOrderId,
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
    final rows = await query.order('duration_months', ascending: true);
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
    required String provider, // 'momo', 'vnpay', 'demo-momo' hoặc 'demo-vnpay'
    required String parentToken,
    String? priceId,
    String? requestId,
    String? orderId,
    bool qr = false, // chỉ VNPay: true = mở thẳng trang quét QR (VNPAYQR)
  }) async {
    final response = await _client.functions.invoke(
      provider == 'momo'
          ? 'momo-checkout'
          : provider.startsWith('demo')
          ? 'demo-pay'
          : 'vnpay-checkout',
      body: {
        'parentToken': parentToken,
        'orderId': ?orderId,
        'priceId': ?priceId,
        'requestId': ?requestId,
        if (provider == 'vnpay' && qr) 'method': 'qr',
        if (provider.startsWith('demo')) 'style': provider.substring(5),
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final id = (data['order'] as Map?)?['id']?.toString();
    final url = (provider == 'momo' || provider.startsWith('demo')
        ? data['payUrl']
        : data['checkoutUrl']) as String?;
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
    // Thanh toán demo: link nằm trên chính Supabase của bạn
    final hostOk = allowedHosts.contains(uri.host) ||
        (provider.startsWith('demo') && uri.host.endsWith('.supabase.co'));
    if (uri.scheme != 'https' || !hostOk) {
      throw StateError('Địa chỉ thanh toán không hợp lệ.');
    }
    return PaymentSession(
      orderId: id,
      provider: provider,
      payUrl: uri,
      deeplink: data['deeplink'] as String?,
      qrData: (data['qrCodeUrl'] ?? data['qrCode']) as String?,
      amountVnd: ((data['order'] as Map?)?['amount_vnd'] as num?)?.toInt(),
      gatewayOrderId: data['gatewayOrderId'] as String?,
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

  /// Chỉ cho thanh toán demo: mô phỏng việc đã quét QR xong
  /// Trả về mã giao dịch (transId) kiểu MoMo/VNPay do server sinh ra.
  static Future<String?> simulateScan({
    required String orderId,
    required String parentToken,
    String style = 'momo', // 'momo' hoặc 'vnpay'
  }) async {
    final response = await _client.functions.invoke(
      'demo-pay',
      body: {
        'action': 'simulate',
        'orderId': orderId,
        'parentToken': parentToken,
        'style': style,
      },
    );
    if (response.status != 200) {
      throw StateError('Chưa mô phỏng được thanh toán.');
    }
    final data = response.data;
    return data is Map ? data['transId']?.toString() : null;
  }

  /// Xóa đơn chưa thanh toán của chính mình (đơn đã trả tiền thì giữ lại).
  static Future<bool> discardOrder(String orderId) async {
    final res = await _client.rpc(
      'discard_unpaid_order',
      params: {'p_order': orderId},
    );
    return res == true;
  }

  /// Dọn các đơn chưa thanh toán đã quá cũ của chính mình.
  static Future<void> purgeUnpaid() async {
    await _client.rpc('purge_my_unpaid_orders');
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