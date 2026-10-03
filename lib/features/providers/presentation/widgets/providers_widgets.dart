import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/provider_entities.dart';

class ProviderListTile extends StatelessWidget {
  final MedicalProvider provider;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const ProviderListTile({
    super.key,
    required this.provider,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // ✅ Provider Logo/Image
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: provider.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: provider.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const _ProviderIcon(),
                      errorWidget: (_, _, _) => const _ProviderIcon(),
                    )
                  : const _ProviderIcon(),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    provider.name,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  // Type
                  Text(provider.typeLabel, style: AppTextStyles.bodySmall),

                  const SizedBox(height: 4),

                  // Phone
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 12,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        provider.phoneNumber,
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Discount badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    ),
                    child: Text(
                      provider.discountLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Distance + Arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Distance
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    provider.distanceLabel,
                    style: AppTextStyles.labelSmall,
                  ),
                ),

                const SizedBox(height: 8),

                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      provider.rating.toStringAsFixed(1),
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fallback Icon ─────────────────────────────────────────────────────────────
class _ProviderIcon extends StatelessWidget {
  const _ProviderIcon();
  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.local_hospital, color: AppColors.primary, size: 28);
}
