import '../../domain/entities/provider_entities.dart';

class MedicalProviderModel extends MedicalProvider {
  const MedicalProviderModel({
    required super.id,
    required super.name,
    required super.type,
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
  });

  factory MedicalProviderModel.fromFirestore(
    Map<String, dynamic> data,
    String id, {
    double? distanceKm,
    bool isFavorite = false,
  }) {
    return MedicalProviderModel(
      id:              id,
      name:            data['name']            ?? '',
      type:            ProviderTypeExt.fromString(data['type']),
      imageUrl:        data['imageUrl']        ?? '',
      logoUrl:         data['logoUrl']         ?? '',
      rating:          (data['rating']         ?? 0.0).toDouble(),
      reviewCount:     data['reviewCount']     ?? 0,
      discountPercent: data['discountPercent'] ?? 0,
      isInNetwork:     data['isInNetwork']     ?? false,
      phoneNumber:     data['phoneNumber']     ?? '',
      address:         data['address']         ?? '',
      workingHours:    WorkingHours.fromMap(data['workingHours']),
      services:        List<String>.from(data['services'] ?? []),
      totalServices:   data['totalServices']   ?? 0,
      website:         data['website'],
      latitude:        data['latitude']?.toDouble(),
      longitude:       data['longitude']?.toDouble(),
      distanceKm:      distanceKm,
      isFavorite:      isFavorite,
    );
  }

  // ── Mock Data ──────────────────────────────────────────────────────────
  static List<MedicalProviderModel> mockProviders(String area) => [
    MedicalProviderModel(
      id: 'p1', name: '$area Medical Center',
      type: ProviderType.clinic,
      imageUrl: '', logoUrl: '',
      rating: 4.6, reviewCount: 128,
      distanceKm: 0.8, discountPercent: 40,
      isInNetwork: true, phoneNumber: '+233 20 123 4567',
      address: '15 Street 233, $area',
      workingHours: const WorkingHours(
        weekdays: 'Mon - Fri: 9:00 AM - 9:00 PM',
        friday:   'Saturday: 2:00 PM - 9:00 PM',
      ),
      services: ['General Consultation', 'Pediatrics', 'Dermatology',
                 'Dental Care', 'Lab Tests', 'X-Ray'],
      totalServices: 12,
    ),
    MedicalProviderModel(
      id: 'p2', name: 'Life Care Clinic',
      type: ProviderType.clinic,
      imageUrl: '', logoUrl: '',
      rating: 4.3, reviewCount: 89,
      distanceKm: 1.1, discountPercent: 30,
      isInNetwork: true, phoneNumber: '+233 20 987 6543',
      address: '7 Main Road, $area',
      workingHours: const WorkingHours(
        weekdays: 'Mon - Sat: 8:00 AM - 8:00 PM',
        friday:   'Sunday: Closed',
      ),
      services: ['General Consultation', 'Lab Tests', 'Pharmacy'],
      totalServices: 8,
    ),
    MedicalProviderModel(
      id: 'p3', name: '$area Specialty Hospital',
      type: ProviderType.hospital,
      imageUrl: '', logoUrl: '',
      rating: 4.8, reviewCount: 312,
      distanceKm: 1.4, discountPercent: 25,
      isInNetwork: true, phoneNumber: '+233 20 456 7890',
      address: '45 Hospital Ave, $area',
      workingHours: const WorkingHours(
        weekdays: 'Open 24 hours',
        friday:   'Open 24 hours',
      ),
      services: ['Emergency', 'Surgery', 'ICU', 'Radiology'],
      totalServices: 20,
    ),
    MedicalProviderModel(
      id: 'p4', name: 'Health Plus $area',
      type: ProviderType.dental,
      imageUrl: '', logoUrl: '',
      rating: 4.5, reviewCount: 67,
      distanceKm: 1.6, discountPercent: 35,
      isInNetwork: false, phoneNumber: '+233 20 321 7654',
      address: '22 Dental Road, $area',
      workingHours: const WorkingHours(
        weekdays: 'Mon - Fri: 9:00 AM - 6:00 PM',
        friday:   'Saturday: 10:00 AM - 4:00 PM',
      ),
      services: ['Dental Checkup', 'Cleaning', 'Whitening', 'Braces'],
      totalServices: 9,
    ),
    MedicalProviderModel(
      id: 'p5', name: 'Care & Cure $area',
      type: ProviderType.clinic,
      imageUrl: '', logoUrl: '',
      rating: 4.1, reviewCount: 45,
      distanceKm: 1.9, discountPercent: 20,
      isInNetwork: true, phoneNumber: '+233 20 654 3210',
      address: '3 Care Street, $area',
      workingHours: const WorkingHours(
        weekdays: 'Mon - Sat: 8:00 AM - 7:00 PM',
        friday:   'Sunday: Closed',
      ),
      services: ['General Consultation', 'Pediatrics'],
      totalServices: 6,
    ),
    MedicalProviderModel(
      id: 'p6', name: '$area PharmaCare',
      type: ProviderType.pharmacy,
      imageUrl: '', logoUrl: '',
      rating: 4.4, reviewCount: 203,
      distanceKm: 0.5, discountPercent: 15,
      isInNetwork: true, phoneNumber: '+233 20 111 2222',
      address: '1 Pharmacy Lane, $area',
      workingHours: const WorkingHours(
        weekdays: 'Mon - Sun: 7:00 AM - 11:00 PM',
        friday:   'Open daily',
      ),
      services: ['Pharmacy', 'Dispensing', 'Delivery'],
      totalServices: 5,
    ),
  ];
}