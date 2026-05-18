import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/service_entities.dart';

// ─────────────────────────────────────────────
//  Location Bar
// ─────────────────────────────────────────────
class LocationBar extends StatelessWidget {
  final String area;
  final VoidCallback onChangeTap;

  const LocationBar({super.key, required this.area, required this.onChangeTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary, size: 18),
          const SizedBox(width: 6),
          Text(area,
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.primary)),
          const Spacer(),
          GestureDetector(
            onTap: onChangeTap,
            child: Text('Change',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Search Bar
// ─────────────────────────────────────────────
class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SearchBar({super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search services',
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Category Tabs
// ─────────────────────────────────────────────
class ServiceCategoryTabs extends StatelessWidget {
  final ServiceCategory selected;
  final ValueChanged<ServiceCategory> onSelect;

  const ServiceCategoryTabs({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ServiceCategory.values;

    return SizedBox(
      height: 58,   // ← أصغر (كان 72)
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = cat == selected;

          return GestureDetector(
            onTap: () => onSelect(cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _categoryIcon(cat),
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _categoryIcon(ServiceCategory cat) {
    switch (cat) {
      case ServiceCategory.all:           return Icons.grid_view_rounded;
      case ServiceCategory.consultation:  return Icons.person_outline;
      case ServiceCategory.diagnostics:   return Icons.biotech_outlined;
      case ServiceCategory.labTests:      return Icons.science_outlined;
      case ServiceCategory.dental:        return Icons.masks_outlined;
      case ServiceCategory.physiotherapy: return Icons.accessibility_outlined;
      case ServiceCategory.xray:          return Icons.image_outlined;
      case ServiceCategory.pharmacy:      return Icons.local_pharmacy_outlined;
    }
  }
}

// ─────────────────────────────────────────────
//  Sort Bar
// ─────────────────────────────────────────────
class ServicesSortBar extends StatelessWidget {
  final ServicesFilter filter;
  final VoidCallback onSortByDistance;
  final VoidCallback onSortAlpha;

  const ServicesSortBar({
    super.key,
    required this.filter,
    required this.onSortByDistance,
    required this.onSortAlpha,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Text('Sort by', style: AppTextStyles.bodySmall),
          const SizedBox(width: 8),

          // Distance sort
          _SortChip(
            label: SortOption.distance.label,
            isSelected: filter.sortBy == SortOption.distance,
            onTap: onSortByDistance,
          ),
          const SizedBox(width: 8),

          // Alphabetical sort
          _SortChip(
            label: SortOption.alphabetical.label,
            isSelected: filter.sortBy == SortOption.alphabetical,
            onTap: onSortAlpha,
          ),

          const Spacer(),

          // Filters button
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppDimens.radiusSM),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune, size: 16,
                    color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Filters',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppDimens.radiusSM),
        ),
        child: Row(
          children: [
            Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                  color:
                      isSelected ? Colors.white : AppColors.textSecondary,
                )),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down,
                size: 14,
                color:
                    isSelected ? Colors.white : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Results Banner
// ─────────────────────────────────────────────
class ResultsBanner extends StatelessWidget {
  final int count;
  final String area;
  final bool isSearching;

  const ResultsBanner({super.key, 
    required this.count,
    required this.area,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSearching
                      ? 'Searching...'
                      : 'Showing results in $area',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.primary),
                ),
                Text(
                  '$count providers found',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.location_on,
                color: AppColors.primary, size: 22),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Service List Tile
// ─────────────────────────────────────────────
class ServiceListTile extends StatelessWidget {
  final MedicalService service;
  final VoidCallback onTap;

  const ServiceListTile({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Service image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSM),
              child: service.imageUrl.startsWith('assets/')
                  ? Container(
                      width: 64, height: 64,
                      color: AppColors.primarySurface,
                      child: const Icon(Icons.medical_services_outlined,
                          color: AppColors.primary, size: 28),
                    )
                  : CachedNetworkImage(
                      imageUrl: service.imageUrl,
                      width: 64, height: 64,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 64, height: 64,
                        color: AppColors.primarySurface,
                        child: const Icon(
                            Icons.medical_services_outlined,
                            color: AppColors.primary, size: 28),
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            // Name + discount
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Text(service.discountLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),

            // Distance + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(service.distanceLabel,
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: 8),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textHint),
              ],
            ),
          ],
        ),
      ),
    );
  }
}