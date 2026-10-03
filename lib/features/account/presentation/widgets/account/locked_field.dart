part of '../../pages/account_page.dart';

class _LockedField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _LockedField({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              Text(value, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Account Header
// ─────────────────────────────────────────────
