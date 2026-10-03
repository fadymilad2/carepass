import 'package:geolocator/geolocator.dart';
import '../../domain/entities/home_entities.dart';

class HomeProviderModel extends HomeProviderItem {
  const HomeProviderModel({
    required super.id,
    required super.name,
    required super.type,
    super.types,
    required super.phone,
    required super.area,
    super.distanceKm,
  });

  factory HomeProviderModel.fromFirestore(
    Map<String, dynamic> data,
    String id, {
    Position? position,
  }) {
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    double? distance;
    if (position != null &&
        latitude is num &&
        longitude is num &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180) {
      distance =
          Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            latitude.toDouble(),
            longitude.toDouble(),
          ) /
          1000;
    }
    return HomeProviderModel(
      id: id,
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? 'clinic',
      types:
          (data['types'] as List?)
              ?.whereType<String>()
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList() ??
          const [],
      phone: data['phoneNumber'] as String? ?? '',
      area: data['area'] as String? ?? '',
      distanceKm: distance,
    );
  }
}

List<HomeProviderItem> nearestHomeProviders(
  Iterable<HomeProviderItem> providers, {
  int limit = 5,
}) {
  final sorted = providers.toList()
    ..sort((a, b) {
      final distance = (a.distanceKm ?? double.infinity).compareTo(
        b.distanceKm ?? double.infinity,
      );
      if (distance != 0) return distance;
      final name = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return name != 0 ? name : a.id.compareTo(b.id);
    });
  return sorted.take(limit).toList();
}
