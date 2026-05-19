import 'package:equatable/equatable.dart';

class AccountUser extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? photoUrl;
  final String subscriptionStatus;
  final String? planName;
  final DateTime? memberSince;

  const AccountUser({
    required this.id,
    required this.username,
    required this.email,
    this.photoUrl,
    required this.subscriptionStatus,
    this.planName,
    this.memberSince,
  });

  bool get isSubscribed => subscriptionStatus == 'active';

  String get memberSinceFormatted {
    if (memberSince == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[memberSince!.month - 1]} ${memberSince!.year}';
  }

  @override
  List<Object?> get props => [id, email];
}