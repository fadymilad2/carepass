import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────
//  Service Entity
// ─────────────────────────────────────────────
class MedicalService extends Equatable {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final int discountPercent;
  final double? distanceKm;
  final int providerCount;
  final bool isAvailable;

  const MedicalService({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.discountPercent,
    this.distanceKm,
    required this.providerCount,
    this.isAvailable = true,
  });

  String get discountLabel => 'Up to $discountPercent% off';

  String get distanceLabel => distanceKm != null
      ? '${distanceKm!.toStringAsFixed(1)} km'
      : '';

  @override
  List<Object?> get props => [id, name, category];
}

// ─────────────────────────────────────────────
//  Service Category
// ─────────────────────────────────────────────
enum ServiceCategory {
  all,
  consultation,
  diagnostics,
  labTests,
  dental,
  physiotherapy,
  xray,
  pharmacy,
}

extension ServiceCategoryExt on ServiceCategory {
  String get label {
    switch (this) {
      case ServiceCategory.all:           return 'All';
      case ServiceCategory.consultation:  return 'Consultation';
      case ServiceCategory.diagnostics:   return 'Diagnostics';
      case ServiceCategory.labTests:      return 'Lab Tests';
      case ServiceCategory.dental:        return 'Dental';
      case ServiceCategory.physiotherapy: return 'Physiotherapy';
      case ServiceCategory.xray:          return 'X-Ray';
      case ServiceCategory.pharmacy:      return 'Pharmacy';
    }
  }

  String get firestoreKey {
    switch (this) {
      case ServiceCategory.all:           return '';
      case ServiceCategory.consultation:  return 'consultation';
      case ServiceCategory.diagnostics:   return 'diagnostics';
      case ServiceCategory.labTests:      return 'lab_tests';
      case ServiceCategory.dental:        return 'dental';
      case ServiceCategory.physiotherapy: return 'physiotherapy';
      case ServiceCategory.xray:          return 'xray';
      case ServiceCategory.pharmacy:      return 'pharmacy';
    }
  }
}

// ─────────────────────────────────────────────
//  Sort Option
// ─────────────────────────────────────────────
enum SortOption { distance, discount, alphabetical }

extension SortOptionExt on SortOption {
  String get label {
    switch (this) {
      case SortOption.distance:     return 'Distance';
      case SortOption.discount:     return 'Discount';
      case SortOption.alphabetical: return 'A - Z';
    }
  }
}

// ─────────────────────────────────────────────
//  Services Filter
// ─────────────────────────────────────────────
class ServicesFilter extends Equatable {
  final ServiceCategory category;
  final SortOption sortBy;
  final String? area;
  final String? searchQuery;

  const ServicesFilter({
    this.category  = ServiceCategory.all,
    this.sortBy    = SortOption.distance,
    this.area,
    this.searchQuery,
  });

  ServicesFilter copyWith({
    ServiceCategory? category,
    SortOption? sortBy,
    String? area,
    String? searchQuery,
  }) {
    return ServicesFilter(
      category:    category    ?? this.category,
      sortBy:      sortBy      ?? this.sortBy,
      area:        area        ?? this.area,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [category, sortBy, area, searchQuery];
}