part of '../../pages/card_page.dart';

class _SubscribeCTA extends StatelessWidget {
  const _SubscribeCTA();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.credit_card_outlined,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text('No Active Subscription', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Subscribe to access your health card,\ndiscounts, and free checkups',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.payment),
              child: const Text('Subscribe Now'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Quick Actions
// ─────────────────────────────────────────────
