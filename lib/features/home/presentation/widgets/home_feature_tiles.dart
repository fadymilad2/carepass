import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HomeFeatureTiles extends StatelessWidget {
  const HomeFeatureTiles({super.key});

  static const _features = [
    (
      Icons.local_offer_outlined,
      'Discounted Services',
      'Save up to 50% on medical services',
    ),
    (
      Icons.verified_outlined,
      'Trusted Providers',
      'Wide network of clinics and hospitals',
    ),
    (
      Icons.credit_card_outlined,
      'Easy Subscription',
      'Simple plans, cancel anytime',
    ),
    (
      Icons.favorite_border_rounded,
      'Your Health, Our Priority',
      'Healthcare made affordable',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMD),
      child: Column(
        children: _features.map((f) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.paddingSM),
            child: Container(
              padding: const EdgeInsets.all(AppDimens.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                    ),
                    child: Icon(f.$1, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.$2, style: AppTextStyles.titleMedium),
                        const SizedBox(height: 2),
                        Text(f.$3, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
