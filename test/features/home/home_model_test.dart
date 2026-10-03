import 'package:carepass/features/home/data/models/home_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('malformed subscription dates do not crash the home screen', () {
    final user = UserSummaryModel.fromFirestore({
      'username': 'Member',
      'subscriptionStatus': 'active',
      'cardExpiryDate': 'not-a-date',
    }, 'member');
    expect(user.cardExpiryDate, isNull);
    expect(user.isSubscribed, isFalse);
  });
  test('expired memberships do not expose active home benefits', () {
    final user = UserSummaryModel.fromFirestore({
      'subscriptionStatus': 'active',
      'cardExpiryDate': '2000-01-01T00:00:00Z',
    }, 'member');
    expect(user.isSubscribed, isFalse);
  });
}
