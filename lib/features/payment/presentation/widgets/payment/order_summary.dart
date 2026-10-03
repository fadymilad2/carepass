part of '../../pages/payment_page.dart';

class _OrderSummary extends StatelessWidget {
  final SubscriptionPlan plan;
  final DiscountCode? discount;
  final bool isUpgrade;
  final bool isEarlyUpgradeWindow;
  final String? currentPlanName;
  final double currentPlanPrice;
  final double upgradeBaseAmount;

  const _OrderSummary({
    required this.plan,
    this.discount,
    this.isUpgrade = false,
    this.isEarlyUpgradeWindow = false,
    this.currentPlanName,
    this.currentPlanPrice = 0,
    double? upgradeBaseAmount,
  }) : upgradeBaseAmount = upgradeBaseAmount ?? 0;

  @override
  Widget build(BuildContext context) {
    final effectiveBase = isUpgrade ? upgradeBaseAmount : plan.price;

    final discountAmount = discount != null
        ? discount!.discountAmount(effectiveBase)
        : 0.0;
    final priceAfterDiscount = effectiveBase - discountAmount;
    final total = priceAfterDiscount * 1.20;

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),

          if (isUpgrade) ...[
            _SummaryRow(
              label: '${plan.name} Plan (full price)',
              value: '${plan.currency} ${plan.price.toStringAsFixed(2)}',
              valueColor: AppColors.textSecondary,
            ),

            if (isEarlyUpgradeWindow) ...[
              const SizedBox(height: 6),
              _SummaryRow(
                label: 'Credit for ${currentPlanName ?? 'current plan'}',
                value:
                    '- ${plan.currency} ${currentPlanPrice.toStringAsFixed(2)}',
                valueColor: AppColors.success,
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text(
                'Full price applies — past the first 15 days '
                'of your billing cycle.',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Upgrade Amount',
              value: '${plan.currency} ${upgradeBaseAmount.toStringAsFixed(2)}',
              isBold: true,
            ),
          ] else ...[
            _SummaryRow(
              label: '${plan.name} Plan (${plan.period})',
              value: '${plan.currency} ${plan.price.toStringAsFixed(2)}',
            ),
            if (plan.isFamilyPlan) ...[
              const SizedBox(height: 4),
              Text(
                'Covers up to ${plan.maxFamilyMembers} family members',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],

          if (discount != null) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Discount (${discount!.code})',
              value:
                  '- ${plan.currency} '
                  '${discountAmount.toStringAsFixed(2)}',
              valueColor: AppColors.success,
            ),
          ],

          const Divider(height: 20),

          _SummaryRow(
            label: 'Total',
            value:
                '${plan.currency} '
                '${total.toStringAsFixed(2)}',
            isBold: true,
            valueColor: AppColors.primary,
          ),

          const SizedBox(height: 8),
          Text(
            'All prices include applicable taxes',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
