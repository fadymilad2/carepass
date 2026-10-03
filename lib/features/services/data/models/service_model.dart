import '../../domain/entities/service_entities.dart';

class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.name,
    required super.category,
    required super.providerId,
    required super.providerName,
    required super.discountPercent,
    required super.isAvailable,
    super.description,
    super.imageUrl, // ✅ Fixed
  });

  factory ServiceModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ServiceModel(
      id: id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'consultation',
      providerId: data['providerId'] as String? ?? '',
      providerName: data['providerName'] as String? ?? '',
      discountPercent: data['discountPercent'] as int? ?? 0,
      isAvailable: data['isAvailable'] as bool? ?? true,
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?, // ✅ Fixed
    );
  }
}
