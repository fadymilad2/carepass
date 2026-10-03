import '../../domain/entities/card_entities.dart';

class HealthCardModel extends HealthCard {
  const HealthCardModel({
    required super.id,
    required super.memberId,
    required super.memberName,
    required super.status,
    required super.validThru,
    required super.planName,
    super.subscriptionType, // ✅
    required super.benefits,
  });

  factory HealthCardModel.fromFirestore(Map<String, dynamic> data, String uid) {
    DateTime validThru;
    try {
      validThru = DateTime.parse(data['cardExpiryDate'] ?? '');
    } catch (_) {
      validThru = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return HealthCardModel(
      id: uid,
      memberId:
          data['memberId'] ??
          'CP-${uid.substring(0, uid.length.clamp(0, 8)).toUpperCase()}',
      memberName: data['username'] ?? data['fullName'] ?? 'Member',
      status:
          data['subscriptionStatus'] == 'active' &&
              !validThru.isAfter(DateTime.now())
          ? CardStatus.expired
          : CardStatusExt.fromString(data['subscriptionStatus']),
      validThru: validThru,
      planName: data['planName'] ?? 'Standard',
      subscriptionType: data['subscriptionType'] ?? 'individual', // ✅
      benefits: [],
    );
  }

  factory HealthCardModel.mock(String uid, String name) {
    return HealthCardModel(
      id: uid,
      memberId: '——',
      memberName: name,
      status: CardStatus.pending,
      validThru: DateTime.now(),
      planName: 'No Plan',
      subscriptionType: 'individual',
      benefits: [],
    );
  }
}
