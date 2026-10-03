import 'package:carepass/features/card/data/models/card_models.dart';
import 'package:carepass/features/card/domain/entities/card_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invalid expiry does not grant a fresh active card', () {
    final card = HealthCardModel.fromFirestore({
      'subscriptionStatus': 'active',
      'cardExpiryDate': 'invalid',
    }, 'abc');
    expect(card.isActive, isFalse);
    expect(card.status, CardStatus.expired);
    expect(card.memberId, 'CP-ABC');
  });
}
