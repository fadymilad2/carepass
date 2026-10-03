import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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

  bool get isSubscribed =>
      subscriptionStatus == SubscriptionStatus.active &&
      cardExpiryDate?.isAfter(DateTime.now()) == true;

  String get firstName {
    if (fullName.trim().isEmpty) return 'there';
    return fullName.trim().split(' ').first;
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    photoUrl,
    memberId,
    subscriptionStatus,
    cardExpiryDate,
    selectedArea,
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
  List<Object?> get props => [
    nearbyProviders,
    availableServices,
    checkupsRemaining,
  ];
}

class HomeServiceItem {
  final String id;
  final String name;
  final String category;
  final int discountPercent;
  final IconData icon;

  const HomeServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.discountPercent,
    required this.icon,
  });

  String get discountLabel => 'Up to $discountPercent% off';

  IconData get categoryIcon {
    switch (category) {
      case 'consultation':
        return Icons.person_outlined;
      case 'radiology':
        return Icons.image_outlined;
      case 'lab':
        return Icons.science_outlined;
      case 'pharmacy':
        return Icons.medication_outlined;
      case 'dental':
        return Icons.masks_outlined;
      case 'physiotherapy':
        return Icons.accessibility_outlined;
      case 'blood_pressure':
        return Icons.favorite_outlined;
      case 'blood_sugar':
        return Icons.water_drop_outlined;
      default:
        return Icons.medical_services_outlined;
    }
  }
}

class HomeProviderItem {
  final String id;
  final String name;
  final String type;
  final List<String> types;
  final String phone;
  final String area;
  final double? distanceKm;

  const HomeProviderItem({
    required this.id,
    required this.name,
    required this.type,
    this.types = const [],
    required this.phone,
    required this.area,
    this.distanceKm,
  });

  String get distanceLabel =>
      distanceKm == null ? '' : '${distanceKm!.toStringAsFixed(1)} km';

  String get typeLabel =>
      (types.isEmpty ? [type] : types).map(_typeLabel).join(' · ');

  static String _typeLabel(String type) {
    switch (type) {
      case 'hospital':
        return 'Hospital';
      case 'pharmacy':
        return 'Pharmacy';
      case 'lab':
        return 'Laboratory';
      case 'dental':
        return 'Dental';
      case 'eye_clinic':
        return 'Eye Clinic';
      case 'diagnostic':
        return 'Diagnostic Center';
      case 'doctor':
        return 'Doctor';
      default:
        return 'Clinic';
    }
  }
}
