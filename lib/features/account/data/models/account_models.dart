import '../../domain/entities/account_entities.dart';

class AccountUserModel extends AccountUser {
  const AccountUserModel({
    required super.id,
    required super.username,
    required super.phoneNumber,
    required super.email,
    super.photoUrl,
    required super.subscriptionStatus,
    super.planName,
    super.memberSince,
    // ✅ New fields
    super.dateOfBirth,
    super.city,
    super.emergencyContact,
    super.bloodType,
  });

  factory AccountUserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AccountUserModel(
      id: id,
      username: data['username'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      subscriptionStatus: data['subscriptionStatus'] as String? ?? 'none',
      planName: data['planName'] as String?,
      memberSince: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
      // ✅ New fields
      dateOfBirth: data['dateOfBirth'] as String?,
      city: data['city'] as String?,
      emergencyContact: data['emergencyContact'] as String?,
      bloodType: data['bloodType'] as String?,
    );
  }
}
