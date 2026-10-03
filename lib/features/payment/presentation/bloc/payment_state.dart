part of 'payment_bloc.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentVerifying extends PaymentState {}

class PaymentPlansLoaded extends PaymentState {
  final List<SubscriptionPlan> plans;
  final SubscriptionPlan? selected;
  final DiscountCode? appliedDiscount;
  final String? discountError;
  final bool isValidatingCode;

  const PaymentPlansLoaded({
    required this.plans,
    this.selected,
    this.appliedDiscount,
    this.discountError,
    this.isValidatingCode = false,
  });

  PaymentPlansLoaded copyWith({SubscriptionPlan? selected}) =>
      PaymentPlansLoaded(
        plans: plans,
        selected: selected ?? this.selected,
        appliedDiscount: appliedDiscount,
        discountError: discountError,
        isValidatingCode: isValidatingCode,
      );

  @override
  List<Object?> get props => [
    plans,
    selected,
    appliedDiscount,
    discountError,
    isValidatingCode,
  ];
}

class PaymentUrlReady extends PaymentState {
  final String url;
  final String reference;
  final SubscriptionPlan plan;
  const PaymentUrlReady({
    required this.url,
    required this.reference,
    required this.plan,
  });
  @override
  List<Object?> get props => [url, reference];
}

class PaymentPending extends PaymentState {
  final String reference;
  final String? message;
  final bool isMonitoring;
  const PaymentPending(
    this.reference, {
    this.message,
    this.isMonitoring = false,
  });
  @override
  List<Object?> get props => [reference, message, isMonitoring];
}

class PaymentSuccess extends PaymentState {
  final SubscriptionPlan plan;
  const PaymentSuccess(this.plan);
  @override
  List<Object?> get props => [plan];
}

class PaymentFailed extends PaymentState {
  final String message;
  const PaymentFailed(this.message);
  @override
  List<Object?> get props => [message];
}
