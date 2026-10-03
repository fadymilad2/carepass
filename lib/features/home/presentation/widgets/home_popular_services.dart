import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/home_entities.dart';
import 'home_section_header.dart';

class HomePopularServices extends StatelessWidget {
  final List<HomeServiceItem> services;
  final VoidCallback onSeeMore;

  const HomePopularServices({
    super.key,
    required this.services,
    required this.onSeeMore,
  });

  @override
  Widget build(BuildContext context) {
    final hasRealData = services.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(title: 'Popular Services', onActionTap: onSeeMore),
        const SizedBox(height: 12),
        SizedBox(
          height: 148,
          child: hasRealData
              ? _RealServicesList(services: services, onSeeMore: onSeeMore)
              : _FallbackServicesList(onSeeMore: onSeeMore),
        ),
      ],
    );
  }
}

class _RealServicesList extends StatelessWidget {
  final List<HomeServiceItem> services;
  final VoidCallback onSeeMore;

  const _RealServicesList({required this.services, required this.onSeeMore});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMD),
      scrollDirection: Axis.horizontal,
      itemCount: services.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final s = services[i];
        return GestureDetector(
          onTap: onSeeMore,
          child: Container(
            width: 128,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusLG),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                  ),
                  child: Icon(
                    s.categoryIcon,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const Spacer(),
                Text(
                  s.name,
                  style: AppTextStyles.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  s.discountLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FallbackServicesList extends StatelessWidget {
  final VoidCallback onSeeMore;
  const _FallbackServicesList({required this.onSeeMore});

  static const _items = [
    _SvcItem('General\nConsultation', 'Up to 40% off', Icons.person_outlined),
    _SvcItem('Dental\nCare', 'Up to 30% off', Icons.masks_outlined),
    _SvcItem('Lab\nTests', 'Up to 40% off', Icons.science_outlined),
    _SvcItem('X-Ray', 'Up to 50% off', Icons.image_outlined),
    _SvcItem('Physiotherapy', 'Up to 30% off', Icons.accessibility_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMD),
      scrollDirection: Axis.horizontal,
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, i) => _ServiceCard(item: _items[i], onTap: onSeeMore),
    );
  }
}

class _SvcItem {
  final String name, discount;
  final IconData icon;
  const _SvcItem(this.name, this.discount, this.icon);
}

class _ServiceCard extends StatelessWidget {
  final _SvcItem item;
  final VoidCallback onTap;
  const _ServiceCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusSM),
              ),
              child: Icon(item.icon, color: AppColors.primary, size: 22),
            ),
            const Spacer(),
            Text(item.name, style: AppTextStyles.labelLarge, maxLines: 2),
            const SizedBox(height: 4),
            Text(
              item.discount,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
