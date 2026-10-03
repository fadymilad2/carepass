part of '../../pages/family_members_page.dart';

class _NotFamilyPlanView extends StatelessWidget {
  const _NotFamilyPlanView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.group_off_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text('No Family Plan', style: AppTextStyles.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Upgrade to a Family plan to add members and share your '
              'CarePass benefits.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.payment),
              child: const Text('Upgrade Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
