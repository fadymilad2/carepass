import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────
//  User Summary Entity
// ─────────────────────────────────────────────
class UserSummary extends Equatable {
  final String id;
  final String fullName;
  final String? photoUrl;
  final String? memberId;
  final SubscriptionStatus subscriptionStatus;
  final DateTime? cardExpiryDate;
  final String? selectedArea;

  const UserSummary({
    required this.id,
    required this.fullName,
    this.photoUrl,
    this.memberId,
    required this.subscriptionStatus,
    this.cardExpiryDate,
    this.selectedArea,
  });

  bool get isSubscribed => subscriptionStatus == SubscriptionStatus.active;

  String get firstName => fullName.split(' ').first;

  @override
  List<Object?> get props => [
        id, fullName, photoUrl, memberId,
        subscriptionStatus, cardExpiryDate, selectedArea,
      ];
}

enum SubscriptionStatus { active, expired, pending, none }

// ─────────────────────────────────────────────
//  Home Banner Entity
// ─────────────────────────────────────────────
class HomeBanner extends Equatable {
  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? actionUrl;
  final BannerType type;
  final String? providerId;
  final String? providerName;
  final int? discountPercent;
  final bool isActive;

  const HomeBanner({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.actionUrl,
    required this.type,
    this.providerId,
    this.providerName,
    this.discountPercent,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, title, imageUrl, type, isActive];
}

enum BannerType { promotional, provider, general }

// ─────────────────────────────────────────────
//  Quick Stat Entity
// ─────────────────────────────────────────────
class HomeQuickStat extends Equatable {
  final int nearbyProviders;
  final int availableServices;
  final int checkupsRemaining;

  const HomeQuickStat({
    required this.nearbyProviders,
    required this.availableServices,
    required this.checkupsRemaining,
  });

  @override
  List<Object?> get props => [nearbyProviders, availableServices, checkupsRemaining];
}
