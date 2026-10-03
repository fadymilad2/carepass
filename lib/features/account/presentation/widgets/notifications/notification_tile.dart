part of '../../pages/notifications_page.dart';

class _NotificationTile extends StatelessWidget {
  final String title;
  final String body;
  final String type;
  final String time;
  final bool isRead;

  const _NotificationTile({
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    required this.isRead,
  });

  IconData get _icon {
    switch (type) {
      case 'subscription':
        return Icons.card_membership_outlined;
      case 'subscription_expiry':
        return Icons.timer_outlined;
      case 'provider':
        return Icons.local_hospital_outlined;
      case 'reminder':
        return Icons.monitor_heart_outlined;
      case 'payment':
        return Icons.receipt_outlined;
      case 'account_status':
        return Icons.account_circle_outlined;
      case 'promotion':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _color {
    switch (type) {
      case 'subscription':
        return AppColors.success;
      case 'subscription_expiry':
        return AppColors.warning;
      case 'provider':
        return AppColors.primary;
      case 'reminder':
        return AppColors.warning;
      case 'payment':
        return AppColors.info;
      case 'account_status':
        return AppColors.error;
      case 'promotion':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(AppDimens.paddingMD),
      decoration: BoxDecoration(
        color: isRead ? AppColors.surface : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        border: Border.all(
          color: isRead
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.2),
        ),
        boxShadow: isRead
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _color, size: 20),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Unread dot
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTextStyles.bodySmall.copyWith(height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
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
