import '../../domain/entities/account_entities.dart';

class AccountUserModel extends AccountUser {
  const AccountUserModel({
    required super.id,
    required super.username,
    required super.email,
    super.photoUrl,
    required super.subscriptionStatus,
    super.planName,
    super.memberSince,
  });

  factory AccountUserModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return AccountUserModel(
      id:                 id,
      username:           data['username']           ?? '',
      email:              data['email']              ?? '',
      photoUrl:           data['photoUrl'],
      subscriptionStatus: data['subscriptionStatus'] ?? 'none',
      planName:           data['planName'],
      memberSince: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'])
          : null,
    );
  }
}