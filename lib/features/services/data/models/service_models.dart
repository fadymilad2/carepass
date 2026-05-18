import '../../domain/entities/service_entities.dart';

class MedicalServiceModel extends MedicalService {
  const MedicalServiceModel({
    required super.id,
    required super.name,
    required super.category,
    required super.imageUrl,
    required super.discountPercent,
    super.distanceKm,
    required super.providerCount,
    super.isAvailable,
  });

  factory MedicalServiceModel.fromFirestore(
    Map<String, dynamic> data,
    String id, {
    double? distanceKm,
  }) {
    return MedicalServiceModel(
      id:              id,
      name:            data['name']            ?? '',
      category:        data['category']        ?? '',
      imageUrl:        data['imageUrl']        ?? '',
      discountPercent: data['discountPercent'] ?? 0,
      providerCount:   data['providerCount']   ?? 0,
      isAvailable:     data['isAvailable']     ?? true,
      distanceKm:      distanceKm,
    );
  }

  // ── Static fallback data (بيتستخدم لو Firestore فاضية) ──────────────────
  static List<MedicalServiceModel> get mockServices => [
    const MedicalServiceModel(
      id: 's1', name: 'General Consultation',
      category: 'consultation',
      imageUrl: 'assets/images/service_consultation.png',
      discountPercent: 40, distanceKm: 1.2, providerCount: 25,
    ),
    const MedicalServiceModel(
      id: 's2', name: 'Dental Care',
      category: 'dental',
      imageUrl: 'assets/images/service_dental.png',
      discountPercent: 30, distanceKm: 1.8, providerCount: 18,
    ),
    const MedicalServiceModel(
      id: 's3', name: 'Laboratory Tests',
      category: 'lab_tests',
      imageUrl: 'assets/images/service_lab.png',
      discountPercent: 40, distanceKm: 2.1, providerCount: 12,
    ),
    const MedicalServiceModel(
      id: 's4', name: 'Physiotherapy',
      category: 'physiotherapy',
      imageUrl: 'assets/images/service_physio.png',
      discountPercent: 30, distanceKm: 2.3, providerCount: 8,
    ),
    const MedicalServiceModel(
      id: 's5', name: 'X-Ray',
      category: 'xray',
      imageUrl: 'assets/images/service_xray.png',
      discountPercent: 50, distanceKm: 2.7, providerCount: 10,
    ),
    const MedicalServiceModel(
      id: 's6', name: 'Blood Tests',
      category: 'lab_tests',
      imageUrl: 'assets/images/service_lab.png',
      discountPercent: 35, distanceKm: 1.5, providerCount: 15,
    ),
    const MedicalServiceModel(
      id: 's7', name: 'Eye Examination',
      category: 'diagnostics',
      imageUrl: 'assets/images/service_eye.png',
      discountPercent: 25, distanceKm: 3.0, providerCount: 7,
    ),
    const MedicalServiceModel(
      id: 's8', name: 'Dermatology',
      category: 'consultation',
      imageUrl: 'assets/images/service_derm.png',
      discountPercent: 35, distanceKm: 2.5, providerCount: 9,
    ),
  ];
}