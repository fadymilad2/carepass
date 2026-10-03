import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/home_entities.dart';
import 'home_section_header.dart';

class HomeNearbyProviders extends StatelessWidget {
  final List<HomeProviderItem> providers;
  final VoidCallback onSeeMore;
  final bool hasError;
  final bool isLoading;
  final VoidCallback? onRetry;

  const HomeNearbyProviders({
    super.key,
    required this.providers,
    required this.onSeeMore,
    this.hasError = false,
    this.isLoading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: providers.any((p) => p.distanceKm != null)
              ? 'Nearby Providers'
              : 'Healthcare Providers',
          onActionTap: onSeeMore,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMD),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasError
              ? Column(
                  children: [
                    const Text('Unable to load providers. Please try again.'),
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    ),
                  ],
                )
              : providers.isEmpty
              ? const Text('No providers are available in this area yet.')
              : Column(
                  children: providers
                      .take(2)
                      .map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RealProviderTile(
                            provider: p,
                            onTap: onSeeMore,
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _RealProviderTile extends StatelessWidget {
  final HomeProviderItem provider;
  final VoidCallback onTap;

  const _RealProviderTile({required this.provider, required this.onTap});

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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusSM),
              ),
              child: const Icon(
                Icons.local_hospital_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(provider.typeLabel, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 12,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(provider.phone, style: AppTextStyles.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
              child: Text(
                provider.distanceKm != null
                    ? provider.distanceLabel
                    : provider.area,
                style: AppTextStyles.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
