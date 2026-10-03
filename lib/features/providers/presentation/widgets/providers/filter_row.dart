part of '../../pages/providers_page.dart';

class _FilterRow extends StatelessWidget {
  final ProvidersFilter filter;
  final VoidCallback onNearbyTap;
  final VoidCallback onSortTap;

  const _FilterRow({
    required this.filter,
    required this.onNearbyTap,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: !filter.nearbyOnly,
            onTap: filter.nearbyOnly ? onNearbyTap : null,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Nearby',
            isSelected: filter.nearbyOnly,
            onTap: onNearbyTap,
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSortTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
              child: Row(
                children: [
                  Text('Sort by', style: AppTextStyles.bodySmall),
                  const SizedBox(width: 4),
                  Text(
                    filter.sortBy.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
