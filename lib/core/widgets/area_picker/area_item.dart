part of '../area_picker.dart';

class _AreaItem extends StatelessWidget {
  final String area;
  final bool isSelected;
  final VoidCallback onTap;

  const _AreaItem({
    required this.area,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            area,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check, color: AppColors.primary, size: 18)
              : const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textHint,
                  size: 14,
                ),
          onTap: onTap,
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }
}
