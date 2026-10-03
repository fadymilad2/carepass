import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String phoneNumber;
  final String username;
  final String email;
  final bool isSubscribed;
  final String subscriptionStatus;
  // ✅ Phase 3 — New fields
  final String? dateOfBirth;
  final String? city;
  final String? emergencyContact;
  final String? bloodType;

  const AppUser({
    required this.uid,
    required this.phoneNumber,
    required this.username,
    required this.email,
    required this.isSubscribed,
    required this.subscriptionStatus,
    this.dateOfBirth,
    this.city,
    this.emergencyContact,
    this.bloodType,
  });

  bool get hasProfile => username.isNotEmpty;

  // ✅ Age auto-calculated from DOB
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

  @override
  List<Object?> get props => [
    uid,
    phoneNumber,
    username,
    email,
    isSubscribed,
    subscriptionStatus,
    dateOfBirth,
    city,
    emergencyContact,
    bloodType,
  ];
}
