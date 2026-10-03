part of '../../pages/card_page.dart';

class _CardStatusSection extends StatelessWidget {
  final HealthCard card;
  const _CardStatusSection({required this.card});

  Color get _statusColor {
    switch (card.status) {
      case CardStatus.active:
        return AppColors.success;
      case CardStatus.expired:
        return AppColors.error;
      case CardStatus.pending:
        return AppColors.warning;
      case CardStatus.suspended:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Card Status', style: AppTextStyles.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  border: Border.all(
                    color: _statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  card.status.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          if (card.isActive) ...[
            const Divider(height: 20),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Valid Until', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      card.validUntilFormatted,
                      style: AppTextStyles.headlineSmall,
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMD),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Show this card at any partner provider to enjoy your discounts',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!card.isActive) ...[
            const Divider(height: 20),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    card.status == CardStatus.suspended
                        ? 'Your account is suspended. Contact support.'
                        : 'Subscribe to activate your card and access all benefits.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Subscribe CTA
// ─────────────────────────────────────────────
