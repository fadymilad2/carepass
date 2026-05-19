import 'package:equatable/equatable.dart';

class MedicalProvider extends Equatable {
  final String id;
  final String name;
  final ProviderType type;
  final String imageUrl;
  final String logoUrl;
  final double rating;
  final int reviewCount;
  final double? distanceKm;
  final int discountPercent;
  final bool isInNetwork;
  final String phoneNumber;
  final String address;
  final WorkingHours workingHours;
  final List<String> services;
  final int totalServices;
  final String? website;
  final double? latitude;
  final double? longitude;
  final bool isFavorite;

  const MedicalProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.imageUrl,
    required this.logoUrl,
    required this.rating,
    required this.reviewCount,
    this.distanceKm,
    required this.discountPercent,
    required this.isInNetwork,
    required this.phoneNumber,
    required this.address,
    required this.workingHours,
    required this.services,
    required this.totalServices,
    this.website,
    this.latitude,
    this.longitude,
    this.isFavorite = false,
  });

  String get distanceLabel => distanceKm != null
      ? '${distanceKm!.toStringAsFixed(1)} km'
      : '';

  String get discountLabel => 'Up to $discountPercent% off';

  String get typeLabel => type.label;

  @override
  List<Object?> get props => [id, name, isFavorite];
}

// ─────────────────────────────────────────────
enum ProviderType { clinic, hospital, pharmacy, lab, dental }

extension ProviderTypeExt on ProviderType {
  String get label {
    switch (this) {
      case ProviderType.clinic:   return 'Clinic';
      case ProviderType.hospital: return 'Hospital';
      case ProviderType.pharmacy: return 'Pharmacy';
      case ProviderType.lab:      return 'Laboratory';
      case ProviderType.dental:   return 'Dental Clinic';
    }
  }

  String get firestoreKey {
    switch (this) {
      case ProviderType.clinic:   return 'clinic';
      case ProviderType.hospital: return 'hospital';
      case ProviderType.pharmacy: return 'pharmacy';
      case ProviderType.lab:      return 'lab';
      case ProviderType.dental:   return 'dental';
    }
  }

  static ProviderType fromString(String? v) {
    switch (v) {
      case 'hospital': return ProviderType.hospital;
      case 'pharmacy': return ProviderType.pharmacy;
      case 'lab':      return ProviderType.lab;
      case 'dental':   return ProviderType.dental;
      default:         return ProviderType.clinic;
    }
  }
}

// ─────────────────────────────────────────────
class WorkingHours extends Equatable {
  final String weekdays;  // e.g. "Sat - Thu: 9:00 AM - 9:00 PM"
  final String friday;    // e.g. "Friday: 2:00 PM - 9:00 PM"

  const WorkingHours({required this.weekdays, required this.friday});

  factory WorkingHours.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const WorkingHours(weekdays: '', friday: '');
    return WorkingHours(
      weekdays: map['weekdays'] ?? '',
      friday:   map['friday']   ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'weekdays': weekdays,
    'friday':   friday,
  };

  @override
  List<Object?> get props => [weekdays, friday];
}

// ─────────────────────────────────────────────
enum ProviderSortOption { distance, rating, discount }

extension ProviderSortExt on ProviderSortOption {
  String get label {
    switch (this) {
      case ProviderSortOption.distance: return 'Distance';
      case ProviderSortOption.rating:   return 'Rating';
      case ProviderSortOption.discount: return 'Discount';
    }
  }
}

// ─────────────────────────────────────────────
class ProvidersFilter extends Equatable {
  final ProviderType? type;
  final ProviderSortOption sortBy;
  final String? area;
  final bool nearbyOnly;
  final String? searchQuery;

  const ProvidersFilter({
    this.type,
    this.sortBy    = ProviderSortOption.distance,
    this.area,
    this.nearbyOnly = false,
    this.searchQuery,
  });

  ProvidersFilter copyWith({
    ProviderType? type,
    ProviderSortOption? sortBy,
    String? area,
    bool? nearbyOnly,
    String? searchQuery,
    bool clearType = false,
  }) => ProvidersFilter(
    type:        clearType ? null : (type ?? this.type),
    sortBy:      sortBy      ?? this.sortBy,
    area:        area        ?? this.area,
    nearbyOnly:  nearbyOnly  ?? this.nearbyOnly,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  @override
  List<Object?> get props => [type, sortBy, area, nearbyOnly, searchQuery];
}