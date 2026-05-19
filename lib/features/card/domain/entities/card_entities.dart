import 'package:equatable/equatable.dart';

class HealthCard extends Equatable {
  final String id;
  final String memberId;
  final String memberName;
  final CardStatus status;
  final DateTime validThru;
  final String planName;
  final List<CardBenefit> benefits;

  const HealthCard({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.status,
    required this.validThru,
    required this.planName,
    required this.benefits,
  });

  bool get isActive => status == CardStatus.active;

  String get validThruFormatted {
    final m = validThru.month.toString().padLeft(2, '0');
    final y = validThru.year.toString().substring(2);
    return '$m/$y';
  }

  String get validUntilFormatted {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[validThru.month - 1]} ${validThru.day}, ${validThru.year}';
  }

  @override
  List<Object?> get props => [id, memberId, status];
}

enum CardStatus { active, expired, pending, suspended }

extension CardStatusExt on CardStatus {
  String get label {
    switch (this) {
      case CardStatus.active:    return 'Active';
      case CardStatus.expired:   return 'Expired';
      case CardStatus.pending:   return 'Pending';
      case CardStatus.suspended: return 'Suspended';
    }
  }

  static CardStatus fromString(String? v) {
    switch (v) {
      case 'active':    return CardStatus.active;
      case 'expired':   return CardStatus.expired;
      case 'pending':   return CardStatus.pending;
      case 'suspended': return CardStatus.suspended;
      default:          return CardStatus.pending;
    }
  }
}

class CardBenefit extends Equatable {
  final String id;
  final String title;
  final String description;
  final int totalAllowed;
  final int used;
  final String period; // 'monthly' | 'yearly'

  const CardBenefit({
    required this.id,
    required this.title,
    required this.description,
    required this.totalAllowed,
    required this.used,
    required this.period,
  });

  int get remaining => (totalAllowed - used).clamp(0, totalAllowed);
  bool get hasRemaining => remaining > 0;

  @override
  List<Object?> get props => [id];
}