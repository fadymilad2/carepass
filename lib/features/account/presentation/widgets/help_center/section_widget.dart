part of '../../pages/help_center_page.dart';

class _SectionWidget extends StatelessWidget {
  final _HelpSection section;
  const _SectionWidget({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(section.icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Text(section.title, style: AppTextStyles.titleMedium),
              ],
            ),
          ),

          const Divider(height: 1),

          // Items
          ...section.items.map((item) => _HelpItemWidget(item: item)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Help Item Widget (Expandable)
// ─────────────────────────────────────────────
