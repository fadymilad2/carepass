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
            // Logo
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.local_hospital,
                  color: AppColors.primary, size: 28),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.name,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(provider.typeLabel,
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(provider.phoneNumber,
                          style: AppTextStyles.labelSmall),
                    ],
                  ),
                ],
              ),
            ),

            // Distance + Call
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(provider.distanceLabel,
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone,
                        color: AppColors.primary, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}