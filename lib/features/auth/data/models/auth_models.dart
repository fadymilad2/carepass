import '../../domain/entities/auth_entities.dart';

class AppUserModel extends AppUser {
  final bool isNewUser;

  const AppUserModel({
    required super.uid,
    required super.phoneNumber,
    required super.username,
    required super.email,
    required super.isSubscribed,
    required super.subscriptionStatus,
    super.dateOfBirth,
    super.city,
    super.emergencyContact,
    super.bloodType,
    this.isNewUser = false,
  });

  factory AppUserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    final status = data['subscriptionStatus'] as String? ?? 'none';
    return AppUserModel(
      uid: uid,
      phoneNumber: data['phoneNumber'] as String? ?? '',
      username: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      isSubscribed: status == 'active',
      subscriptionStatus: status,
      // ✅ New fields
      dateOfBirth: data['dateOfBirth'] as String?,
      city: data['city'] as String?,
      emergencyContact: data['emergencyContact'] as String?,
      bloodType: data['bloodType'] as String?,
      isNewUser: false,
    );
  }
}
