import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ServiceEntity extends Equatable {
  final String id;
  final String name;
  final String category;
  final String providerId;
  final String providerName;
  final int discountPercent;
  final bool isAvailable;
  final String? description;
  final String? imageUrl;

  const ServiceEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.providerId,
    required this.providerName,
    required this.discountPercent,
    required this.isAvailable,
    this.description,
    this.imageUrl,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  String get categoryLabel {
    switch (category) {
      case 'consultation':
        return 'Consultation';
      case 'radiology':
        return 'Diagnostics';
      case 'lab':
        return 'Lab Tests';
      case 'pharmacy':
        return 'Pharmacy';
      case 'dental':
        return 'Dental';
      case 'physiotherapy':
        return 'Physiotherapy';
      case 'blood_pressure':
        return 'BP Check';
      case 'blood_sugar':
        return 'Sugar Check';
      default:
        return category;
    }
  }

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
        return Icons.face_outlined;
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

  @override
  List<Object?> get props => [id, name, isAvailable];
}

// ─────────────────────────────────────────────
//  ✅ ServiceGroup — groups identical services (same
//  name + category) offered by different providers into
//  ONE entry, so the user sees "Blood Test — Up to 30% off
//  · 2 providers" instead of two separate rows.
// ─────────────────────────────────────────────
class ServiceGroup extends Equatable {
  final String name;
  final String category;
  final String categoryLabel;
  final IconData categoryIcon;
  final String? imageUrl;
  final List<ServiceEntity> offerings; // one per provider

  const ServiceGroup({
    required this.name,
    required this.category,
    required this.categoryLabel,
    required this.categoryIcon,
    required this.offerings,
    this.imageUrl,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  int get providerCount =>
      offerings.map((offer) => offer.providerId).toSet().length;

  bool get hasMultipleProviders => providerCount > 1;

  // ✅ Highest discount among all providers offering this service
  int get maxDiscountPercent {
    if (offerings.isEmpty) return 0;
    return offerings
        .map((o) => o.discountPercent)
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  List<Object?> get props => [name, category, offerings];
}
