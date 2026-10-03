import '../../domain/entities/payment_entities.dart';

class SubscriptionPlanModel extends SubscriptionPlan {
  final int order;

  const SubscriptionPlanModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.currency,
    required super.period,
    required super.features,
    required super.isPopular,
    super.durationDays,
    super.isFamilyPlan,
    super.maxFamilyMembers,
    this.order = 99,
  });
}
