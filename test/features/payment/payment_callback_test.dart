import 'package:carepass/features/payment/domain/entities/payment_callback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the exact HTTPS callback endpoint ends checkout', () {
    const host = 'us-central1-carepass-b0220.cloudfunctions.net';
    expect(
      isExpressPayCallback(
        'https://$host/expressPayCallback?order-id=CP-test&token=abc',
        'carepass-b0220',
      ),
      isTrue,
    );
    for (final url in [
      'http://$host/expressPayCallback',
      'https://$host.evil.test/expressPayCallback',
      'https://$host:444/expressPayCallback',
      'https://user@$host/expressPayCallback',
      'https://$host/other',
      'https://sandbox.expresspaygh.com/payment?token=abc',
      'https://us-central1-another.cloudfunctions.net/expressPayCallback',
    ]) {
      expect(isExpressPayCallback(url, 'carepass-b0220'), isFalse, reason: url);
    }
  });
}
