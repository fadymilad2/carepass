import '../../domain/entities/provider_entities.dart';

class MedicalProviderModel extends MedicalProvider {
  const MedicalProviderModel({
    required super.id,
    required super.name,
    required super.type,
    super.types,
    required super.imageUrl,
    required super.logoUrl,
    required super.rating,
    required super.reviewCount,
    super.distanceKm,
    required super.discountPercent,
    required super.isInNetwork,
    required super.phoneNumber,
    required super.address,
    required super.workingHours,
    required super.services,
    required super.totalServices,
    super.website,
    super.latitude,
    super.longitude,
    super.isFavorite,
    super.area,
  });

  factory MedicalProviderModel.fromFirestore(
    Map<String, dynamic> data,
    String id, {
    double? distanceKm,
    bool isFavorite = false,
  }) {
    // ✅ معالجة حقل مواعيد العمل عشان يقبل الـ String (من الداشبورد) أو الـ Map (لو قديم)
    final whData = data['workingHours'];
    Map<String, dynamic> safeWorkingHours;

    if (whData is String) {
      safeWorkingHours = {'weekdays': whData, 'friday': ''};
    } else if (whData is Map) {
      safeWorkingHours = Map<String, dynamic>.from(whData);
    } else {
      safeWorkingHours = {'weekdays': 'N/A', 'friday': ''};
    }

    return MedicalProviderModel(
      id: id,
      name: data['name'] ?? '',
      type: ProviderTypeExt.fromString(data['type'] ?? ''),
      types:
          (data['types'] as List?)
              ?.whereType<String>()
              .where((value) => value.isNotEmpty)
              .map(ProviderTypeExt.fromString)
              .toSet()
              .toList() ??
          const [],
      imageUrl: data['imageUrl'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      discountPercent: data['discountPercent'] ?? 0,
      isInNetwork: data['isInNetwork'] ?? false,
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      workingHours: WorkingHours.fromMap(safeWorkingHours),
      services: List<String>.from(data['services'] ?? []),
      totalServices: data['totalServices'] ?? 0,
      website: data['website'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      distanceKm: distanceKm,
      isFavorite: isFavorite,
      area: data['area'] as String?,
    );
  }
}
