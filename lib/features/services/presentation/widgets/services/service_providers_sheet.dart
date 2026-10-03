part of '../../pages/services_page.dart';

class _ServiceProvidersSheet extends StatelessWidget {
  final ServiceGroup group;
  const _ServiceProvidersSheet({required this.group});

  @override
  Widget build(BuildContext context) {
    final sorted = List<ServiceEntity>.from(group.offerings)
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: group.hasImage
                        ? CachedNetworkImage(
                            imageUrl: group.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Icon(
                              group.categoryIcon,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            errorWidget: (_, _, _) => Icon(
                              group.categoryIcon,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          )
                        : Icon(
                            group.categoryIcon,
                            color: AppColors.primary,
                            size: 22,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name, style: AppTextStyles.titleLarge),
                        Text(
                          'Available at ${group.providerCount} providers',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'Choose a provider to compare discounts',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: sorted.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 16),
                itemBuilder: (_, i) => _ProviderOfferingTile(
                  service: sorted[i],
                  isBest: i == 0 && sorted[i].discountPercent > 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Single provider row inside the comparison sheet
// ─────────────────────────────────────────────
