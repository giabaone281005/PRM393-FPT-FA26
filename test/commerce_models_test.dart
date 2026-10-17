import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/models/commerce_models.dart';
import 'package:mathlingo/data/models/subscription_model.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';
import 'package:mathlingo/data/repositories/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('expired/canceled Plus returns Basic household limit', () {
    final expired = SubscriptionModel(
      id: 'sub',
      parentId: 'parent',
      tier: SubscriptionTier.plus,
      maxKids: 3,
      startDate: DateTime(2020),
      expiresAt: DateTime(2021),
    );
    expect(expired.isPlusActive, false);
    expect(expired.effectiveMaxKids, 1);
    final canceled = SubscriptionModel(
      id: 'sub',
      parentId: 'parent',
      tier: SubscriptionTier.plus,
      status: SubscriptionStatus.canceled,
      maxKids: 3,
      startDate: DateTime(2020),
    );
    expect(canceled.effectiveMaxKids, 1);
  });
  test('paid or expired order cannot open checkout again', () {
    LearningOrder order(String status, DateTime expires) => LearningOrder(
      id: 'o',
      parentId: 'p',
      status: status,
      label: 'Plus',
      amountVnd: 99000,
      createdAt: DateTime.now(),
      expiresAt: expires,
    );
    expect(
      order('paid', DateTime.now().add(const Duration(minutes: 10))).canResume,
      false,
    );
    expect(order('pending', DateTime(2020)).canResume, false);
    expect(
      order(
        'pending',
        DateTime.now().add(const Duration(minutes: 10)),
      ).canResume,
      true,
    );
  });
  test('signed out state has no demo family or fake progress', () {
    final state = AppStateProvider();
    expect(state.kidProfiles, isEmpty);
    expect(state.currentLessons, isEmpty);
    expect(state.isPlusActive, false);
    state.dispose();
  });
  test(
    'missing backend never produces successful login for demo/admin emails',
    () async {
      for (final email in ['admin@mathlingo.vn', 'phuhuynh@mathlingo.vn']) {
        final result = await AuthRepository.signIn(
          email: email,
          password: 'incorrect',
        );
        expect(result.success, false);
      }
    },
  );
}
