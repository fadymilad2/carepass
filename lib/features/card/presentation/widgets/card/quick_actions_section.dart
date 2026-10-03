part of '../../pages/card_page.dart';

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.grid_view_outlined,
                label: 'View Services',
                onTap: () => context.go(AppRoutes.services),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.location_on_outlined,
                label: 'Find Providers',
                onTap: () => context.go(AppRoutes.providers),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
