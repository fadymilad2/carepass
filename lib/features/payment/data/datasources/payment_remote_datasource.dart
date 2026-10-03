import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/payment_models.dart';
import '../../domain/entities/payment_entities.dart';

abstract class PaymentRemoteDataSource {
  Future<List<SubscriptionPlanModel>> getPlans();
  Future<DiscountCode?> validateDiscountCode(String code);
  Future<void> useDiscountCode(String code);
  Future<PaymentCheckout> initializePayment({
    required String email,
    required String planId,
    required double amount,
    required String currency,
    String? discountCode,
  });
  Future<PaymentVerification> verifyPayment(String reference);
  Future<bool> activateFreeSubscription({
    required String planId,
    String? discountCode,
  });
  Future<void> saveTransaction(PaymentTransaction tx);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  PaymentRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required FirebaseFunctions functions,
  }) : _firestore = firestore,
       _auth = auth,
       _functions = functions;
  @override
  Future<List<SubscriptionPlanModel>> getPlans() async {
    try {
      final snap = await _firestore
          .collection('subscription_plans')
          .where('isActive', isEqualTo: true)
          .get();

      if (snap.docs.isEmpty) return [];

      final plans = snap.docs.map((doc) {
        final data = doc.data();

        final type = (data['type'] as String? ?? 'individual').toLowerCase();
        final isFamily = type == 'family';

        return SubscriptionPlanModel(
          id: doc.id,
          name: data['name'] ?? '',
          description: _buildDescription(data),
          price: (data['price'] ?? 0).toDouble(),
          currency: data['currency'] ?? 'GHS',
          period: _getPeriodLabel(data['durationDays'] ?? 30),
          features: List<String>.from(data['features'] ?? []),
          isPopular: data['isPopular'] ?? false,
          durationDays: data['durationDays'] ?? 30,
          order: data['order'] ?? 99,
          isFamilyPlan: isFamily,
          maxFamilyMembers: isFamily
              ? (data['maxFamilyMembers'] as int? ?? 4)
              : 0,
        );
      }).toList();

      plans.sort((a, b) => a.order.compareTo(b.order));
      return plans;
    } catch (e) {
      throw ServerException('Unable to load subscription plans: $e');
    }
  }

  @override
  Future<DiscountCode?> validateDiscountCode(String code) async {
    try {
      final snap = await _firestore
          .collection('discount_codes')
          .where('code', isEqualTo: code.toUpperCase().trim())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      final data = snap.docs.first.data();
      final id = snap.docs.first.id;

      double parsedValue = 0.0;
      if (data['discount'] != null) {
        parsedValue = (data['discount'] is int)
            ? (data['discount'] as int).toDouble()
            : data['discount'] as double;
      }

      return DiscountCode(
        id: id,
        code: data['code'] ?? code,
        type: data['type'] ?? 'percent',
        value: parsedValue,
        maxUses: data['maxUses'] ?? 0,
        currentUses: data['currentUses'] ?? 0,
        isActive: data['isActive'] ?? false,
        expiryDate: data['expiryDate'],
      );
    } catch (e) {
      throw ServerException('Failed to validate code: $e');
    }
  }

  @override
  Future<void> useDiscountCode(String code) async {
    try {
      final snap = await _firestore
          .collection('discount_codes')
          .where('code', isEqualTo: code.toUpperCase().trim())
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return;

      await snap.docs.first.reference.update({
        'currentUses': FieldValue.increment(1),
        'lastUsedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  @override
  Future<PaymentCheckout> initializePayment({
    required String email,
    required String planId,
    required double amount,
    required String currency,
    String? discountCode,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'initializeExpressPayPayment',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final result = await callable.call({
        'email': email,
        'planId': planId,
        'amount': amount,
        'currency': currency,
        'discountCode': discountCode,
      });

      final url = result.data['authorizationUrl'] as String?;
      if (url == null || url.isEmpty) {
        throw ServerException(
          'Payment initialization failed: no checkout URL returned',
        );
      }
      final reference = result.data['reference'] as String?;
      if (reference == null || reference.isEmpty) {
        throw ServerException(
          'Payment initialization failed: no order reference',
        );
      }
      return PaymentCheckout(url: url, reference: reference);
    } on FirebaseFunctionsException catch (e) {
      throw ServerException(e.message ?? 'Payment initialization failed');
    } catch (e) {
      throw ServerException('Payment error: $e');
    }
  }

  @override
  Future<PaymentVerification> verifyPayment(String reference) async {
    try {
      final callable = _functions.httpsCallable(
        'verifyExpressPayPayment',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final result = await callable.call({'reference': reference});
      return switch (result.data['status']) {
        'success' => PaymentVerification.success,
        'pending' => PaymentVerification.pending,
        'failed' => PaymentVerification.failed,
        _ => throw ServerException(
          'Payment status is unavailable. Please check again.',
        ),
      };
    } on FirebaseFunctionsException catch (e) {
      throw ServerException(e.message ?? 'Verification failed');
    } catch (e) {
      throw ServerException('Verification failed: $e');
    }
  }

  @override
  Future<bool> activateFreeSubscription({
    required String planId,
    String? discountCode,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'activateFreeSubscription',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final result = await callable.call({
        'planId': planId,
        'discountCode': discountCode,
      });

      return (result.data['success'] as bool?) ?? false;
    } on FirebaseFunctionsException catch (e) {
      throw ServerException(e.message ?? 'Failed to activate free plan');
    } catch (e) {
      throw ServerException('Failed to activate free plan: $e');
    }
  }

  @override
  Future<void> saveTransaction(PaymentTransaction tx) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('payments')
        .doc(tx.id)
        .set({
          'reference': tx.reference,
          'amount': tx.amount,
          'currency': tx.currency,
          'status': tx.status.name,
          'planId': tx.planId,
          'discountCode': tx.discountCode,
          'discountAmount': tx.discountAmount,
          'createdAt': tx.createdAt.toIso8601String(),
        });
  }

  String _buildDescription(Map<String, dynamic> data) {
    final type = data['type'] ?? 'individual';
    final duration = data['durationDays'] ?? 30;
    return '${type == 'family' ? 'Family' : 'Individual'}'
        ' · ${_getPeriodLabel(duration)}';
  }

  String _getPeriodLabel(int days) {
    if (days >= 365) return 'year';
    if (days >= 90) return '3 months';
    return 'month';
  }
}
