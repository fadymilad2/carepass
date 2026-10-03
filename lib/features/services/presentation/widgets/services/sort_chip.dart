part of '../../pages/services_page.dart';

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool hasArrow;
  final IconData? hasIcon;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.selected,
    this.hasArrow = false,
    this.hasIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasIcon != null) ...[
              Icon(
                hasIcon,
                size: 14,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            if (hasArrow) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ✅ Service Group List Item — replaces _ServiceListItem
// ─────────────────────────────────────────────
