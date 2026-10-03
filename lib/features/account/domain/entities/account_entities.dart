import 'package:equatable/equatable.dart';

class AccountUser extends Equatable {
  final String id;
  final String username;
  final String phoneNumber;
  final String email; // ✅ New
  final String? photoUrl;
  final String subscriptionStatus;
  final String? planName;
  final DateTime? memberSince;
  // ✅ New fields
  final String? dateOfBirth;
  final String? city;
  final String? emergencyContact;
  final String? bloodType;

  const AccountUser({
    required this.id,
    required this.username,
    required this.phoneNumber,
    required this.email,
    this.photoUrl,
    required this.subscriptionStatus,
    this.planName,
    this.memberSince,
    this.dateOfBirth,
    this.city,
    this.emergencyContact,
    this.bloodType,
  });

  bool get isSubscribed => subscriptionStatus == 'active';

  // ✅ Age auto-calculated
  int? get age {
    if (dateOfBirth == null || dateOfBirth!.isEmpty) return null;
    try {
      final birth = DateTime.parse(dateOfBirth!);
      final now = DateTime.now();
      int a = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        a--;
      }
      return a;
    } catch (_) {
      return null;
    }
  }

  String get memberSinceFormatted {
    if (memberSince == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[memberSince!.month - 1]} ${memberSince!.year}';
  }

  @override
  List<Object?> get props => [
    id,
    username,
    phoneNumber,
    email,
    photoUrl,
    subscriptionStatus,
    planName,
    memberSince,
    dateOfBirth,
    city,
    emergencyContact,
    bloodType,
  ];
}
