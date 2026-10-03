part of '../../pages/home_page.dart';

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ✅ "Checkups" entry removed — it linked to Account with
    // no meaningful destination there.
    final actions = [
      (
        Icons.search_outlined,
        'Find Doctor',
        AppColors.primary,
        AppRoutes.providers,
      ),
      (
        Icons.medical_services_outlined,
        'Services',
        AppColors.info,
        AppRoutes.services,
      ),
      (
        Icons.credit_card_outlined,
        'My Card',
        AppColors.success,
        AppRoutes.card,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMD),
      child: GridView.count(
        // ✅ 3 items now instead of 4 — keeps spacing even
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        children: actions.map((a) {
          return GestureDetector(
            onTap: () => context.go(a.$4),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (a.$3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                  ),
                  child: Icon(a.$1, color: a.$3, size: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  a.$2,
                  style: AppTextStyles.labelSmall,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Loading Skeleton
// ─────────────────────────────────────────────
