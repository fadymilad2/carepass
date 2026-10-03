import 'dart:async';

import 'package:carepass/core/errors/exceptions.dart';
import 'package:carepass/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/payment_entities.dart';
part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRemoteDataSource _ds;

  List<SubscriptionPlan> _plans = [];
  SubscriptionPlan? _selected;
  DiscountCode? _discount;
  int _discountVersion = 0;
  SubscriptionPlan? _checkoutPlan;
  String? _checkoutReference;
  String? _checkoutUrl;
  final Duration pollingInterval;
  final int maxAutomaticChecks;
  Timer? _pollTimer;
  int _automaticChecks = 0;
  int _verificationGeneration = 0;
  int? _activeVerification;

  void _stopMonitoring() {
    _pollTimer?.cancel();
    _verificationGeneration++;
    _activeVerification = null;
  }

  @override
  Future<void> close() {
    _stopMonitoring();
    return super.close();
  }

  PaymentBloc({
    required PaymentRemoteDataSource dataSource,
    this.pollingInterval = const Duration(seconds: 5),
    this.maxAutomaticChecks = 24,
  }) : _ds = dataSource,
       super(PaymentInitial()) {
    on<PaymentPlansRequested>(_onPlansRequested);
    on<PaymentPlanSelected>(_onPlanSelected);
    on<PaymentDiscountCodeApplied>(_onDiscountApplied);
    on<PaymentDiscountCodeRemoved>(_onDiscountRemoved);
    on<PaymentInitRequested>(_onInitPayment);
    on<PaymentVerifyRequested>(_onVerify);
    on<PaymentCancelled>(_onCancelled);
    on<PaymentCheckoutResumeRequested>((event, emit) {
      if (state is PaymentPending &&
          _checkoutUrl != null &&
          _checkoutReference != null &&
          _checkoutPlan != null) {
        _stopMonitoring();
        emit(
          PaymentUrlReady(
            url: _checkoutUrl!,
            reference: _checkoutReference!,
            plan: _checkoutPlan!,
          ),
        );
      }
    });
  }

  Future<void> _onPlansRequested(
    PaymentPlansRequested e,
    Emitter<PaymentState> emit,
  ) async {
    _stopMonitoring();
    _checkoutReference = null;
    _checkoutUrl = null;
    _checkoutPlan = null;
    _discountVersion++;
    emit(PaymentLoading());
    try {
      _plans = await _ds.getPlans();
      _selected = _plans.isNotEmpty ? _plans.first : null;
      _discount = null;

      final popular = _plans.where((p) => p.isPopular).firstOrNull;
      if (popular != null) _selected = popular;

      emit(PaymentPlansLoaded(plans: _plans, selected: _selected));
    } catch (e) {
      emit(PaymentFailed('Failed to load plans: $e'));
    }
  }

  void _onPlanSelected(PaymentPlanSelected e, Emitter<PaymentState> emit) {
    _discountVersion++;
    _selected = e.plan;
    emit(
      PaymentPlansLoaded(
        plans: _plans,
        selected: _selected,
        appliedDiscount: _discount,
      ),
    );
  }

  Future<void> _onDiscountApplied(
    PaymentDiscountCodeApplied e,
    Emitter<PaymentState> emit,
  ) async {
    if (e.code.trim().isEmpty) return;
    final version = ++_discountVersion;
    _discount = null;

    emit(
      PaymentPlansLoaded(
        plans: _plans,
        selected: _selected,
        isValidatingCode: true,
      ),
    );

    try {
      final discount = await _ds.validateDiscountCode(e.code.trim());

      if (emit.isDone || version != _discountVersion) return;

      if (discount == null) {
        emit(
          PaymentPlansLoaded(
            plans: _plans,
            selected: _selected,
            discountError: 'Invalid discount code',
          ),
        );
        return;
      }

      if (!discount.isValid) {
        String error = 'Discount code is not valid';
        if (discount.isExpired) error = 'Code has expired';
        if (discount.isExhausted) error = 'Code usage limit reached';

        emit(
          PaymentPlansLoaded(
            plans: _plans,
            selected: _selected,
            discountError: error,
          ),
        );
        return;
      }

      _discount = discount;
      emit(
        PaymentPlansLoaded(
          plans: _plans,
          selected: _selected,
          appliedDiscount: _discount,
        ),
      );
    } catch (e) {
      if (emit.isDone || version != _discountVersion) return;
      emit(
        PaymentPlansLoaded(
          plans: _plans,
          selected: _selected,
          discountError: 'Could not validate code',
        ),
      );
    }
  }

  void _onDiscountRemoved(
    PaymentDiscountCodeRemoved e,
    Emitter<PaymentState> emit,
  ) {
    _discountVersion++;
    _discount = null;
    emit(PaymentPlansLoaded(plans: _plans, selected: _selected));
  }

  Future<void> _onInitPayment(
    PaymentInitRequested e,
    Emitter<PaymentState> emit,
  ) async {
    if (state is PaymentLoading ||
        state is PaymentPending ||
        state is PaymentUrlReady ||
        state is PaymentVerifying ||
        (state is PaymentPlansLoaded &&
            (state as PaymentPlansLoaded).isValidatingCode)) {
      return;
    }
    _checkoutPlan = e.plan;
    emit(PaymentLoading());
    try {
      final baseAmount = e.overrideBaseAmount ?? e.plan.price;

      double amount = baseAmount * 1.20;
      if (_discount != null) {
        final discounted = baseAmount - _discount!.discountAmount(baseAmount);
        amount = discounted * 1.20;
      }
      if ((amount * 100).round() == 0) {
        final success = await _ds.activateFreeSubscription(
          planId: e.plan.id,
          discountCode: _discount?.code,
        );

        if (success) {
          emit(PaymentSuccess(e.plan));
        } else {
          emit(
            const PaymentFailed(
              'Could not activate your free plan. Please try again.',
            ),
          );
        }
        return;
      }

      final checkout = await _ds.initializePayment(
        email: e.email,
        planId: e.plan.id,
        amount: amount,
        currency: e.plan.currency,
        discountCode: _discount?.code,
      );

      _checkoutReference = checkout.reference;
      _checkoutUrl = checkout.url;
      emit(
        PaymentUrlReady(
          url: checkout.url,
          reference: checkout.reference,
          plan: e.plan,
        ),
      );
    } on ServerException catch (e) {
      emit(PaymentFailed(e.message));
    } catch (e) {
      emit(PaymentFailed(e.toString()));
    }
  }

  Future<void> _onVerify(
    PaymentVerifyRequested e,
    Emitter<PaymentState> emit,
  ) async {
    if (_activeVerification != null || state is PaymentSuccess) return;
    if (e.automatic && state is! PaymentPending) return;
    final plan = _checkoutPlan;
    if (plan == null) {
      emit(const PaymentFailed('Select a plan before verifying payment'));
      return;
    }
    if (_checkoutReference != e.reference) return;
    _pollTimer?.cancel();
    if (!e.automatic) _automaticChecks = 0;
    final generation = _verificationGeneration;
    _activeVerification = generation;
    if (state is! PaymentPending) emit(PaymentVerifying());
    try {
      final result = await _ds.verifyPayment(e.reference);
      if (emit.isDone || generation != _verificationGeneration) return;
      if (result == PaymentVerification.success) {
        _stopMonitoring();
        emit(PaymentSuccess(plan));
      } else if (result == PaymentVerification.pending) {
        _awaitConfirmation(e.reference, emit);
      } else {
        _stopMonitoring();
        _checkoutReference = null;
        emit(const PaymentFailed('Payment was declined. Please try again.'));
      }
    } catch (_) {
      if (emit.isDone || generation != _verificationGeneration) return;
      _awaitConfirmation(e.reference, emit);
    } finally {
      if (_activeVerification == generation) _activeVerification = null;
    }
  }

  void _awaitConfirmation(String reference, Emitter<PaymentState> emit) {
    final automatic = _automaticChecks < maxAutomaticChecks;
    emit(PaymentPending(reference, isMonitoring: automatic));
    if (!automatic) return;
    _pollTimer = Timer(pollingInterval, () {
      if (isClosed || state is! PaymentPending) return;
      _automaticChecks++;
      add(PaymentVerifyRequested(reference, automatic: true));
    });
  }

  void _onCancelled(PaymentCancelled e, Emitter<PaymentState> emit) {
    if (_checkoutReference != null) {
      add(PaymentVerifyRequested(_checkoutReference!));
      return;
    }
    _checkoutPlan = null;
    emit(
      PaymentPlansLoaded(
        plans: _plans,
        selected: _selected,
        appliedDiscount: _discount,
      ),
    );
  }
}
