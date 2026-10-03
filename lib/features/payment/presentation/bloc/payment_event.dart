part of 'payment_bloc.dart';

abstract class PaymentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PaymentPlansRequested extends PaymentEvent {}

class PaymentPlanSelected extends PaymentEvent {
  final SubscriptionPlan plan;
  PaymentPlanSelected(this.plan);

  @override
  List<Object?> get props => [plan.id];
}

class PaymentDiscountCodeApplied extends PaymentEvent {
  final String code;
  PaymentDiscountCodeApplied(this.code);
}

class PaymentDiscountCodeRemoved extends PaymentEvent {}

class PaymentInitRequested extends PaymentEvent {
  final SubscriptionPlan plan;
  final String email;
  final double? overrideBaseAmount;

  PaymentInitRequested({
    required this.plan,
    required this.email,
    this.overrideBaseAmount,
  });

  @override
  List<Object?> get props => [plan.id, overrideBaseAmount];
}

class PaymentVerifyRequested extends PaymentEvent {
  final String reference;
  final bool automatic;
  PaymentVerifyRequested(this.reference, {this.automatic = false});
  @override
  List<Object?> get props => [reference, automatic];
}

class PaymentCancelled extends PaymentEvent {}

class PaymentCheckoutResumeRequested extends PaymentEvent {}
