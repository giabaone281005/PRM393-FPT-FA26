import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/models/commerce_models.dart';
import 'package:mathlingo/data/models/purchase_guidance.dart';
import 'package:mathlingo/data/models/subscription_model.dart';

void main() {
  final now = DateTime.now();
  SubscriptionModel plus({
    bool trial = false,
    bool expired = false,
    bool perpetual = false,
  }) => SubscriptionModel(
    id: 'subscription',
    parentId: 'parent',
    tier: SubscriptionTier.plus,
    startDate: now.subtract(const Duration(days: 1)),
    expiresAt: perpetual ? null : now.add(Duration(days: expired ? -1 : 5)),
    notes: trial ? SubscriptionModel.trialMarker : null,
  );
  PurchaseGuidance guide(
    SubscriptionModel sub, {
    LearningOrder? pending,
    bool used = false,
    bool available = true,
  }) => PurchaseGuidance.forAccount(
    subscription: sub,
    pendingOrder: pending,
    trialAvailable: available,
    trialUsed: used,
  );

  test(
    'unresolved payment takes priority over suggesting another purchase',
    () {
      final pending = LearningOrder(
        id: 'real-pending-id',
        parentId: 'parent',
        status: 'pending',
        label: 'Monthly',
        amountVnd: 99000,
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 10)),
      );
      final result = guide(plus(), pending: pending);
      expect(result.title, 'Kiểm tra đơn đang chờ trước');
      expect(result.message, contains(pending.id));
    },
  );
  test('active trial and paid Plus have different guidance', () {
    expect(guide(plus(trial: true)).title, 'Gia đình đang dùng thử');
    expect(guide(plus()).title, 'Quyền Plus vẫn còn hiệu lực');
    expect(
      guide(plus(perpetual: true)).message,
      contains('không cần mua thêm'),
    );
  });
  test('only an eligible Basic account is offered an unused trial', () {
    final basic = SubscriptionModel.defaultBasic('parent');
    expect(guide(basic).title, 'Có thể dùng thử trước');
    expect(guide(basic, used: true).title, 'Basic vẫn dùng được miễn phí');
    expect(
      guide(basic, available: false).title,
      'Basic vẫn dùng được miễn phí',
    );
    expect(
      guide(plus(expired: true), used: true).title,
      'Basic vẫn dùng được miễn phí',
    );
  });
}
