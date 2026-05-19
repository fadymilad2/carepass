import '../../domain/entities/card_entities.dart';

class HealthCardModel extends HealthCard {
  const HealthCardModel({
    required super.id,
    required super.memberId,
    required super.memberName,
    required super.status,
    required super.validThru,
    required super.planName,
    required super.benefits,
  });

  factory HealthCardModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return HealthCardModel(
      id:         id,
      memberId:   data['memberId']   ?? 'CP-0000000',
      memberName: data['fullName']   ?? data['username'] ?? '',
      status:     CardStatusExt.fromString(data['subscriptionStatus']),
      validThru:  data['cardExpiryDate'] != null
          ? DateTime.parse(data['cardExpiryDate'])
          : DateTime.now().add(const Duration(days: 365)),
      planName:   data['planName']   ?? 'Standard',
      benefits:   (data['benefits'] as List? ?? [])
          .map((b) => CardBenefitModel.fromMap(b))
          .toList(),
    );
  }

  // Mock for when Firestore has no card yet
  static HealthCardModel mock(String userId, String username) =>
      HealthCardModel(
        id: userId,
        memberId: 'CP-${userId.substring(0, 8).toUpperCase()}',
        memberName: username,
        status: CardStatus.active,
        validThru: DateTime(DateTime.now().year + 1, 6, 30),
        planName: 'Standard',
        benefits: const [
          CardBenefitModel(
            id: 'b1',
            title: 'Blood Sugar & Blood Pressure Check',
            description: 'Available 1 time per month',
            totalAllowed: 1,
            used: 0,
            period: 'monthly',
          ),
          CardBenefitModel(
            id: 'b2',
            title: 'Free General Consultation',
            description: 'Available 2 times per month',
            totalAllowed: 2,
            used: 1,
            period: 'monthly',
          ),
        ],
      );
}

class CardBenefitModel extends CardBenefit {
  const CardBenefitModel({
    required super.id,
    required super.title,
    required super.description,
    required super.totalAllowed,
    required super.used,
    required super.period,
  });

  factory CardBenefitModel.fromMap(Map<String, dynamic> map) {
    return CardBenefitModel(
      id:           map['id']           ?? '',
      title:        map['title']        ?? '',
      description:  map['description']  ?? '',
      totalAllowed: map['totalAllowed'] ?? 1,
      used:         map['used']         ?? 0,
      period:       map['period']       ?? 'monthly',
    );
  }
}