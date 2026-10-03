import 'package:equatable/equatable.dart';

class PaymentCheckout {
  final String url;
  final String reference;
  const PaymentCheckout({required this.url, required this.reference});
}

enum PaymentVerification { success, pending, failed }

// ─────────────────────────────────────────────
//  Family Member
// ─────────────────────────────────────────────
class FamilyMember extends Equatable {
  final String id;
  final String name;
  final String relationship; // spouse, child, parent, sibling
  final String? dateOfBirth;
  final String? phoneNumber;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.dateOfBirth,
    this.phoneNumber,
  });

  String get relationshipLabel {
    switch (relationship) {
      case 'spouse':
        return 'Spouse';
      case 'child':
        return 'Child';
      case 'parent':
        return 'Parent';
      case 'sibling':
        return 'Sibling';
      default:
        return relationship;
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'relationship': relationship,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
  };

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      relationship: map['relationship'] as String? ?? 'spouse',
      dateOfBirth: map['dateOfBirth'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, relationship, dateOfBirth, phoneNumber];
}

// ─────────────────────────────────────────────
//  Subscription Plan
// ─────────────────────────────────────────────
class SubscriptionPlan extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String period;
  final List<String> features;
  final bool isPopular;
  final int durationDays;
  final bool isFamilyPlan; // ✅ New
  final int maxFamilyMembers; // ✅ New

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.period,
    required this.features,
    required this.isPopular,
    this.durationDays = 30,
    this.isFamilyPlan = false,
    this.maxFamilyMembers = 0,
  });

  String get priceLabel => '$currency ${totalAmount.toStringAsFixed(2)}';

  String get periodLabel {
    switch (period) {
      case 'year':
        return 'per year';
      case '3 months':
      case 'quarter':
        return 'per 3 months';
      default:
        return 'per month';
    }
  }

  // Ghana taxes: VAT 15% + NHIL 2.5% + GetFund 2.5% = 20%
  double get _taxRate => 0.20;
  double get vatAmount => price * _taxRate;
  double get totalAmount => price * (1 + _taxRate);

  double discountedTotal(double discountPercent) {
    final discounted = price * (1 - discountPercent.clamp(0, 100) / 100);
    return discounted * (1 + _taxRate);
  }

  @override
  List<Object?> get props => [id, name, price, currency, period];
}

// ─────────────────────────────────────────────
//  Discount Code
// ─────────────────────────────────────────────
class DiscountCode extends Equatable {
  final String id;
  final String code;
  final String type;
  final double value;
  final int maxUses;
  final int currentUses;
  final bool isActive;
  final String? expiryDate;

  const DiscountCode({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.maxUses,
    required this.currentUses,
    required this.isActive,
    this.expiryDate,
  });

  bool get isExhausted => maxUses > 0 && currentUses >= maxUses;

  bool get isExpired {
    if (expiryDate == null) return false;
    try {
      return DateTime.parse(expiryDate!).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool get isValid => isActive && !isExhausted && !isExpired;

  double discountAmount(double price) {
    if (type == 'percent') return price * (value.clamp(0, 100) / 100);
    return value.clamp(0, price);
  }

  double applyTo(double price) =>
      (price - discountAmount(price)).clamp(0, price);

  @override
  List<Object?> get props => [
    id,
    code,
    type,
    value,
    maxUses,
    currentUses,
    isActive,
    expiryDate,
  ];
}

// ─────────────────────────────────────────────
//  Payment Transaction
// ─────────────────────────────────────────────
enum PaymentStatus { pending, success, failed, cancelled }

class PaymentTransaction extends Equatable {
  final String id;
  final String reference;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String planId;
  final String? discountCode;
  final double? discountAmount;
  final DateTime createdAt;

  const PaymentTransaction({
    required this.id,
    required this.reference,
    required this.amount,
    required this.currency,
    required this.status,
    required this.planId,
    required this.createdAt,
    this.discountCode,
    this.discountAmount,
  });

  @override
  List<Object?> get props => [id, reference];
}
