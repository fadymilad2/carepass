part of '../../pages/providers_page.dart';

class _SortSheet extends StatelessWidget {
  final ProviderSortOption currentSort;
  final ValueChanged<ProviderSortOption> onSelect;

  const _SortSheet({required this.currentSort, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sort by', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          ...ProviderSortOption.values.map(
            (sort) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(sort.label, style: AppTextStyles.bodyMedium),
              trailing: currentSort == sort
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                onSelect(sort);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Shimmer + Error
// ─────────────────────────────────────────────
