import 'dart:async';
import 'package:carepass/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:carepass/features/payment/data/models/payment_models.dart';
import 'package:carepass/features/payment/domain/entities/payment_entities.dart';
import 'package:carepass/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const plan = SubscriptionPlanModel(
  id: 'monthly',
  name: 'Monthly',
  description: '',
  price: 100,
  currency: 'GHS',
  period: 'month',
  features: [],
  isPopular: false,
);
const discount = DiscountCode(
  id: 'half',
  code: 'HALF',
  type: 'percent',
  value: 50,
  maxUses: 0,
  currentUses: 0,
  isActive: true,
);

class FakePayments implements PaymentRemoteDataSource {
  PaymentVerification verification = PaymentVerification.success;
  bool verificationUnavailable = false;
  int initializations = 0;
  int verifications = 0;
  Future<PaymentVerification> Function()? verify;
  Future<DiscountCode?> Function(String) validate = (_) async => discount;
  double? charged;
  String? chargedCode;
  @override
  Future<List<SubscriptionPlanModel>> getPlans() async => [plan];
  @override
  Future<DiscountCode?> validateDiscountCode(String code) => validate(code);
  @override
  Future<PaymentCheckout> initializePayment({
    required String email,
    required String planId,
    required double amount,
    required String currency,
    String? discountCode,
  }) async {
    initializations++;
    charged = amount;
    chargedCode = discountCode;
    return const PaymentCheckout(
      url: 'https://sandbox.expresspaygh.com/payment?token=test',
      reference: 'CP-test',
    );
  }

  @override
  Future<PaymentVerification> verifyPayment(String reference) async {
    verifications++;
    if (verify != null) return verify!();
    if (verificationUnavailable) throw Exception('Connection unavailable');
    return verification;
  }

  @override
  Future<bool> activateFreeSubscription({
    required String planId,
    String? discountCode,
  }) async => true;
  @override
  Future<void> saveTransaction(PaymentTransaction tx) async {}
  @override
  Future<void> useDiscountCode(String code) async {}
}

Future<PaymentState> dispatch(
  PaymentBloc bloc,
  PaymentEvent event,
  bool Function(PaymentState) matches,
) {
  final done = bloc.stream
      .firstWhere(matches)
      .timeout(const Duration(seconds: 3));
  bloc.add(event);
  return done;
}

void main() {
  for (final outcome in [
    PaymentVerification.success,
    PaymentVerification.failed,
  ]) {
    testWidgets('pending payment automatically resolves to $outcome', (
      tester,
    ) async {
      final source = FakePayments()..verification = PaymentVerification.pending;
      final bloc = PaymentBloc(dataSource: source);
      bloc.add(PaymentInitRequested(plan: plan, email: 'member@example.com'));
      await tester.pump();
      bloc.add(PaymentVerifyRequested('CP-test'));
      await tester.pump();
      expect((bloc.state as PaymentPending).isMonitoring, isTrue);
      source.verification = outcome;
      await tester.pump(const Duration(seconds: 5));
      expect(
        bloc.state,
        outcome == PaymentVerification.success
            ? isA<PaymentSuccess>()
            : isA<PaymentFailed>(),
      );
      await tester.pump(const Duration(minutes: 1));
      expect(source.verifications, 2);
      expect(source.initializations, 1);
      await tester.runAsync(() => bloc.close());
    });
  }

  testWidgets('automatic retries are bounded and uncertainty stays pending', (
    tester,
  ) async {
    final source = FakePayments()..verificationUnavailable = true;
    final bloc = PaymentBloc(dataSource: source, maxAutomaticChecks: 2);
    bloc.add(PaymentInitRequested(plan: plan, email: 'member@example.com'));
    await tester.pump();
    bloc.add(PaymentVerifyRequested('CP-test'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    expect((bloc.state as PaymentPending).isMonitoring, isFalse);
    await tester.pump(const Duration(minutes: 1));
    expect(source.verifications, 3);
    source.verificationUnavailable = false;
    bloc.add(PaymentVerifyRequested('CP-test'));
    await tester.pump();
    expect(bloc.state, isA<PaymentSuccess>());
    await tester.runAsync(() => bloc.close());
  });

  testWidgets(
    'in-flight polling does not overlap or overwrite resumed checkout',
    (tester) async {
      final source = FakePayments()..verification = PaymentVerification.pending;
      final bloc = PaymentBloc(dataSource: source);
      bloc.add(PaymentInitRequested(plan: plan, email: 'member@example.com'));
      await tester.pump();
      bloc.add(PaymentVerifyRequested('CP-test'));
      await tester.pump();
      final pending = Completer<PaymentVerification>();
      source.verify = () => pending.future;
      await tester.pump(const Duration(seconds: 5));
      bloc.add(PaymentVerifyRequested('CP-test'));
      await tester.pump(const Duration(seconds: 20));
      expect(source.verifications, 2);
      expect(bloc.state, isA<PaymentPending>());
      bloc.add(PaymentCheckoutResumeRequested());
      await tester.pump();
      pending.complete(PaymentVerification.success);
      await tester.pump();
      expect(bloc.state, isA<PaymentUrlReady>());
      await tester.pump(const Duration(seconds: 20));
      expect(source.verifications, 2);
      await tester.runAsync(() => bloc.close());
    },
  );

  testWidgets('closing pending payment cancels automatic checks', (
    tester,
  ) async {
    final source = FakePayments()..verification = PaymentVerification.pending;
    final bloc = PaymentBloc(dataSource: source);
    bloc.add(PaymentInitRequested(plan: plan, email: 'member@example.com'));
    await tester.pump();
    bloc.add(PaymentVerifyRequested('CP-test'));
    await tester.pump();
    await tester.runAsync(() => bloc.close());
    await tester.pump(const Duration(minutes: 1));
    expect(source.verifications, 1);
  });

  test(
    'pending checkout resumes the same order without a second charge',
    () async {
      final source = FakePayments()..verification = PaymentVerification.pending;
      final bloc = PaymentBloc(dataSource: source);
      addTearDown(bloc.close);
      final initial =
          await dispatch(
                bloc,
                PaymentInitRequested(plan: plan, email: 'member@example.com'),
                (s) => s is PaymentUrlReady,
              )
              as PaymentUrlReady;
      await dispatch(bloc, PaymentCancelled(), (s) => s is PaymentPending);
      final resumed =
          await dispatch(
                bloc,
                PaymentCheckoutResumeRequested(),
                (s) => s is PaymentUrlReady,
              )
              as PaymentUrlReady;
      expect(resumed.reference, initial.reference);
      expect(resumed.url, initial.url);
      expect(source.initializations, 1);
    },
  );
  test('pending payment can be checked again and then succeeds', () async {
    final source = FakePayments()..verification = PaymentVerification.pending;
    final bloc = PaymentBloc(dataSource: source);
    addTearDown(bloc.close);
    await dispatch(
      bloc,
      PaymentInitRequested(plan: plan, email: 'member@example.com'),
      (s) => s is PaymentUrlReady,
    );
    await dispatch(
      bloc,
      PaymentVerifyRequested('CP-test'),
      (s) => s is PaymentPending,
    );
    source.verification = PaymentVerification.success;
    await dispatch(
      bloc,
      PaymentVerifyRequested('CP-test'),
      (s) => s is PaymentSuccess,
    );
  });
  test('closing checkout still checks the saved order', () async {
    final source = FakePayments()..verification = PaymentVerification.pending;
    final bloc = PaymentBloc(dataSource: source);
    addTearDown(bloc.close);
    await dispatch(
      bloc,
      PaymentInitRequested(plan: plan, email: 'member@example.com'),
      (s) => s is PaymentUrlReady,
    );
    await dispatch(bloc, PaymentCancelled(), (s) => s is PaymentPending);
  });
  test('network uncertainty keeps the order available for retry', () async {
    final source = FakePayments()..verificationUnavailable = true;
    final bloc = PaymentBloc(dataSource: source);
    addTearDown(bloc.close);
    await dispatch(
      bloc,
      PaymentInitRequested(plan: plan, email: 'member@example.com'),
      (s) => s is PaymentUrlReady,
    );
    final state = await dispatch(
      bloc,
      PaymentVerifyRequested('CP-test'),
      (s) => s is PaymentPending,
    );
    expect((state as PaymentPending).reference, 'CP-test');
    source.verificationUnavailable = false;
    await dispatch(
      bloc,
      PaymentVerifyRequested('CP-test'),
      (s) => s is PaymentSuccess,
    );
  });
  test('declined payment is shown as failed', () async {
    final bloc = PaymentBloc(
      dataSource: FakePayments()..verification = PaymentVerification.failed,
    );
    addTearDown(bloc.close);
    await dispatch(
      bloc,
      PaymentInitRequested(plan: plan, email: 'member@example.com'),
      (s) => s is PaymentUrlReady,
    );
    await dispatch(
      bloc,
      PaymentVerifyRequested('CP-test'),
      (s) => s is PaymentFailed,
    );
  });
  test(
    'invalid replacement code removes the previous discount from checkout',
    () async {
      final source = FakePayments();
      final bloc = PaymentBloc(dataSource: source);
      addTearDown(bloc.close);
      await dispatch(
        bloc,
        PaymentPlansRequested(),
        (s) => s is PaymentPlansLoaded,
      );
      await dispatch(
        bloc,
        PaymentDiscountCodeApplied('HALF'),
        (s) => s is PaymentPlansLoaded && s.appliedDiscount != null,
      );
      source.validate = (_) async => null;
      await dispatch(
        bloc,
        PaymentDiscountCodeApplied('BAD'),
        (s) => s is PaymentPlansLoaded && s.discountError != null,
      );
      await dispatch(
        bloc,
        PaymentInitRequested(plan: plan, email: 'member@example.com'),
        (s) => s is PaymentUrlReady,
      );
      expect(source.charged, 120);
      expect(source.chargedCode, isNull);
    },
  );
  test('removing a code cancels pending validation', () async {
    final source = FakePayments();
    final pending = Completer<DiscountCode?>();
    source.validate = (_) => pending.future;
    final bloc = PaymentBloc(dataSource: source);
    addTearDown(bloc.close);
    await dispatch(
      bloc,
      PaymentPlansRequested(),
      (s) => s is PaymentPlansLoaded,
    );
    await dispatch(
      bloc,
      PaymentDiscountCodeApplied('HALF'),
      (s) => s is PaymentPlansLoaded && s.isValidatingCode,
    );
    await dispatch(
      bloc,
      PaymentDiscountCodeRemoved(),
      (s) => s is PaymentPlansLoaded && !s.isValidatingCode,
    );
    pending.complete(discount);
    await Future<void>.delayed(Duration.zero);
    expect((bloc.state as PaymentPlansLoaded).appliedDiscount, isNull);
  });
  test(
    'verification without checkout reports failure rather than null assertion',
    () async {
      final bloc = PaymentBloc(dataSource: FakePayments());
      addTearDown(bloc.close);
      final state = await dispatch(
        bloc,
        PaymentVerifyRequested('ref'),
        (s) => s is PaymentFailed,
      );
      expect((state as PaymentFailed).message, contains('Select a plan'));
    },
  );
  test('discount amounts cannot be negative or exceed the price', () {
    for (final value in [-50.0, 150.0]) {
      final code = DiscountCode(
        id: 'x',
        code: 'x',
        type: 'percent',
        value: value,
        maxUses: 0,
        currentUses: 0,
        isActive: true,
      );
      expect(code.discountAmount(100), inInclusiveRange(0, 100));
    }
  });
}
