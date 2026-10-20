import 'commerce_models.dart';
import 'subscription_model.dart';

/// Uses confirmed account state, without inventing a preferred package.
class PurchaseGuidance {
  final String title, message;
  const PurchaseGuidance(this.title, this.message);

  factory PurchaseGuidance.forAccount({
    required SubscriptionModel subscription,
    required LearningOrder? pendingOrder,
    required bool trialAvailable,
    required bool trialUsed,
  }) {
    if (pendingOrder != null) {
      return PurchaseGuidance(
        'Kiểm tra đơn đang chờ trước',
        'Đơn ${pendingOrder.id} chưa có kết quả cuối. Tiếp tục hoặc kiểm tra đơn này trong lịch sử trước khi mua thêm.',
      );
    }
    if (subscription.isTrialActive) {
      return PurchaseGuidance(
        'Gia đình đang dùng thử',
        'Còn ${subscription.trialDaysLeft} ngày dùng thử. Bạn có thể trải nghiệm trước khi quyết định mua Plus.',
      );
    }
    if (subscription.isPlusActive) {
      return PurchaseGuidance(
        'Quyền Plus vẫn còn hiệu lực',
        subscription.expiresAt == null
            ? 'Gia đình có Plus không thời hạn, không cần mua thêm.'
            : 'Bạn vẫn dùng được quyền Plus hiện tại. Mua thêm chỉ khi muốn kéo dài thời hạn; thời gian được cộng dồn.',
      );
    }
    if (trialAvailable && !trialUsed) {
      return const PurchaseGuidance(
        'Có thể dùng thử trước',
        'Tài khoản chưa sử dụng lượt dùng thử. Bạn có thể trải nghiệm trước khi chọn gói trả phí.',
      );
    }
    return const PurchaseGuidance(
      'Basic vẫn dùng được miễn phí',
      'Chọn Plus khi gia đình cần thêm hồ sơ bé hoặc mở toàn bộ lộ trình. Giá và thời hạn bên dưới được lấy từ danh mục đang mở bán.',
    );
  }
}
