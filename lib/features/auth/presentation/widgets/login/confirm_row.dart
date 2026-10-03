part of '../../pages/login_page.dart';

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool locked;

  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    if (locked) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.lock_outlined,
                        size: 10,
                        color: AppColors.warning,
                      ),
                    ],
                  ],
                ),
                Text(value, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
