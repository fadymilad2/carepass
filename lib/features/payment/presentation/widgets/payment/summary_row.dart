part of '../../pages/payment_page.dart';

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold ? AppTextStyles.titleMedium : AppTextStyles.bodyMedium,
        ),
        Text(
          value,
          style: (isBold ? AppTextStyles.titleMedium : AppTextStyles.bodyMedium)
              .copyWith(color: valueColor),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Plan Card
// ─────────────────────────────────────────────
