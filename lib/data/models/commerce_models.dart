import 'package:intl/intl.dart';

String formatVnd(int amount) => NumberFormat.currency(
  locale: 'vi_VN',
  symbol: 'đ',
  decimalDigits: 0,
).format(amount);

class PlanPrice {
  final String id, planId, label;
  final int amountVnd, durationMonths;
  final bool published;
  const PlanPrice({
    required this.id,
    required this.planId,
    required this.label,
    required this.amountVnd,
    required this.durationMonths,
    required this.published,
  });
  factory PlanPrice.fromMap(Map<String, dynamic> m) => PlanPrice(
    id: m['id'] as String,
    planId: m['plan_id'] as String,
    label: m['label'] as String,
    amountVnd: (m['amount_vnd'] as num).toInt(),
    durationMonths: (m['duration_months'] as num).toInt(),
    published: m['published'] == true,
  );
}

class LearningOrder {
  final String requestId;
  final String id, parentId, status, label;
  final int amountVnd;
  final DateTime createdAt, expiresAt;
  const LearningOrder({
    this.requestId = '',
    required this.id,
    required this.parentId,
    required this.status,
    required this.label,
    required this.amountVnd,
    required this.createdAt,
    required this.expiresAt,
  });
  factory LearningOrder.fromMap(Map<String, dynamic> m) => LearningOrder(
    requestId: m['idempotency_key']?.toString() ?? '',
    id: m['id'] as String,
    parentId: m['parent_id'] as String,
    status: m['status'] as String,
    label: (m['snapshot'] as Map?)?['label']?.toString() ?? 'Gói học tập',
    amountVnd: (m['amount_vnd'] as num).toInt(),
    createdAt: DateTime.parse(m['created_at'] as String),
    expiresAt: DateTime.parse(m['expires_at'] as String),
  );
  bool get canResume =>
      status == 'pending' && expiresAt.isAfter(DateTime.now());
  String get displayStatus => switch (status) {
    'paid' => 'Đã thanh toán · Đã cấp quyền',
    'refunded' => 'Đã hoàn tiền · Đã thu hồi kỳ Plus',
    'failed' => 'Thanh toán không thành công',
    'expired' => 'Đơn đã hết hạn',
    _ => canResume ? 'Chờ thanh toán/xác minh' : 'Đã hết thời gian thanh toán',
  };
}
