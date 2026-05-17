import '../../domain/entities/auth_entities.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.username,
    required super.email,
    super.photoUrl,
  });

  factory AppUserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUserModel(
      id: id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'username':   username,
    'email':      email,
    'photoUrl':   photoUrl,
    'createdAt':  DateTime.now().toIso8601String(),
    'subscriptionStatus': 'none',
    'selectedArea': '',
  };
}