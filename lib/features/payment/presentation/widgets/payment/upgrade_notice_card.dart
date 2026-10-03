part of '../../pages/payment_page.dart';

class _UpgradeNoticeCard extends StatelessWidget {
  final bool blocked;
  final bool earlyWindow;
  final int daysElapsed;
  final String currentPlanName;
  final VoidCallback onContactSupport;

  const _UpgradeNoticeCard({
    required this.blocked,
    required this.earlyWindow,
    required this.daysElapsed,
    required this.currentPlanName,
    required this.onContactSupport,
  });

  @override
  Widget build(BuildContext context) {
    if (blocked) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warningSurface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.support_agent_outlined,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Annual Plan — Assisted Upgrade',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your current plan ($currentPlanName) is an Annual '
              'subscription. To switch to a Family plan, please '
              'contact our customer support team — they\'ll help '
              'work out the right amount for your remaining time.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.upgrade, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrading from $currentPlanName',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  earlyWindow
                      ? 'You\'re within the first 15 days of your billing '
                            'cycle ($daysElapsed days used) — you\'ll only pay '
                            'the price difference to switch to Family.'
                      : 'You\'re past 15 days into your billing cycle '
                            '($daysElapsed days used) — the full Family plan '
                            'price applies for this switch.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Family Members Section
// ─────────────────────────────────────────────
