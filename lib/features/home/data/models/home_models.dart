import '../../domain/entities/home_entities.dart';

// ─────────────────────────────────────────────
//  User Summary Model
// ─────────────────────────────────────────────
class UserSummaryModel extends UserSummary {
  const UserSummaryModel({
    required super.id,
    required super.fullName,
    super.photoUrl,
    super.memberId,
    required super.subscriptionStatus,
    super.cardExpiryDate,
    super.selectedArea, required String firstName,
  });

  factory UserSummaryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserSummaryModel(
      id: id,
      fullName: data['fullName'] ?? '',
      photoUrl: data['photoUrl'],
      memberId: data['memberId'],
      subscriptionStatus: _parseStatus(data['subscriptionStatus']),
      cardExpiryDate: data['cardExpiryDate'] != null
          ? DateTime.parse(data['cardExpiryDate'])
          : null,
      selectedArea: data['selectedArea'], firstName: data['firstName'] ?? '',
    );
  }

  static SubscriptionStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':    return SubscriptionStatus.active;
      case 'expired':   return SubscriptionStatus.expired;
      case 'pending':   return SubscriptionStatus.pending;
      default:          return SubscriptionStatus.none;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'photoUrl': photoUrl,
      'memberId': memberId,
      'subscriptionStatus': subscriptionStatus.name,
      'cardExpiryDate': cardExpiryDate?.toIso8601String(),
      'selectedArea': selectedArea,
    };
  }
}

// ─────────────────────────────────────────────
//  Home Banner Model
// ─────────────────────────────────────────────
class HomeBannerModel extends HomeBanner {
  const HomeBannerModel({
    required super.id,
    required super.title,
    super.subtitle,
    required super.imageUrl,
    super.actionUrl,
    required super.type,
    super.providerId,
    super.providerName,
    super.discountPercent,
    super.isActive,
  });

  factory HomeBannerModel.fromFirestore(Map<String, dynamic> data, String id) {
    return HomeBannerModel(
      id: id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      imageUrl: data['imageUrl'] ?? '',
      actionUrl: data['actionUrl'],
      type: _parseBannerType(data['type']),
      providerId: data['providerId'],
      providerName: data['providerName'],
      discountPercent: data['discountPercent'],
      isActive: data['isActive'] ?? true,
    );
  }

  /// Static banners shown to non-subscribed users (onboarding)
  static List<HomeBannerModel> get onboardingBanners => [
        const HomeBannerModel(
          id: 'ob1',
          title: 'Discounted Medical Services',
          subtitle: 'Save up to 50% on consultations and lab tests',
          imageUrl: 'https://picsum.photos/400/200',
          type: BannerType.general,
          discountPercent: 50,
        ),
        const HomeBannerModel(
          id: 'ob2',
          title: 'Wide Provider Network',
          subtitle: 'Over 500 clinics and hospitals across all areas',
          imageUrl: 'https://picsum.photos/400/200',
          type: BannerType.general,
        ),
        const HomeBannerModel(
          id: 'ob3',
          title: 'Subscribe & Start Saving',
          subtitle: 'Flexible plans for everyone. Cancel anytime.',
          imageUrl: 'https://picsum.photos/400/200',
          type: BannerType.general,
        ),
      ];

  static BannerType _parseBannerType(String? type) {
    switch (type) {
      case 'promotional': return BannerType.promotional;
      case 'provider':    return BannerType.provider;
      default:            return BannerType.general;
    }
  }
}
