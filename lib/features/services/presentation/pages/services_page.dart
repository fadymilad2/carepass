import 'package:cached_network_image/cached_network_image.dart';
import 'package:carepass/features/services/domain/entities/service_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/area_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/services_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/data/models/provider_models.dart';

part '../widgets/services/sort_chip.dart';
part '../widgets/services/service_group_list_item.dart';
part '../widgets/services/service_providers_sheet.dart';
part '../widgets/services/provider_offering_tile.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final _searchCtrl = TextEditingController();
  String _sortBy = 'Distance';
  // '' = no area filter (show all) — same default as Providers
  String _selectedArea = '';
  String _selectedCategory = 'all';

  static const _categories = <String, String>{
    'all': 'All',
    'consultation': 'Consultation',
    'radiology': 'Diagnostics',
    'lab': 'Lab Tests',
    'pharmacy': 'Pharmacy',
    'dental': 'Dental',
    'physiotherapy': 'Physiotherapy',
    'blood_pressure': 'BP Check',
    'blood_sugar': 'Sugar Check',
  };

  @override
  void initState() {
    super.initState();
    context.read<ServicesBloc>().add(ServicesLoadAll());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAreaPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AreaPicker(
        currentArea: _selectedArea,
        onSelect: (area) {
          setState(() => _selectedArea = area);
          context.read<ServicesBloc>().add(ServicesAreaChanged(area));
        },
        onClear: () {
          setState(() => _selectedArea = '');
          context.read<ServicesBloc>().add(ServicesAreaChanged(''));
        },
      ),
    );
  }

  void _showFiltersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Filter by Category', style: AppTextStyles.headlineSmall),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _selectedCategory = 'all');
                    context.read<ServicesBloc>().add(
                      ServicesCategoryFilterChanged('all'),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.entries.map((e) {
                final sel = _selectedCategory == e.key;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = e.key);
                    context.read<ServicesBloc>().add(
                      ServicesCategoryFilterChanged(e.key),
                    );
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                      border: Border.all(
                        color: sel ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: sel ? Colors.white : AppColors.textPrimary,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ✅ New — actually sorts the grouped services by the
  // selected sort option. "Distance" needs the nearest-provider
  // distance, which is computed asynchronously inside each list
  // item — so for Distance we leave the Bloc's natural order
  // (services are already reasonably ordered), and only apply a
  // real sort for A-Z, which we CAN compute synchronously here.
  List<ServiceGroup> _applySorting(List<ServiceGroup> groups) {
    if (_sortBy == 'A-Z') {
      final sorted = List<ServiceGroup>.from(groups);
      sorted.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return sorted;
    }
    // 'Distance' — Bloc already returns groups sorted by name;
    // true distance sorting would require pre-fetching every
    // provider's coordinates before building the list, which
    // the current per-item lazy-loading design doesn't support.
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<ServicesBloc, ServicesState>(
          builder: (context, state) {
            // ✅ Fixed — apply sorting here, since the BLoC's
            // filtered list only knows about area/category/search,
            // not display order (sort is a page-local UI concern).
            final services = state is ServicesLoaded
                ? _applySorting(state.filtered)
                : <ServiceGroup>[];
            final loading = state is ServicesLoading;
            final error = state is ServicesError ? state.message : null;

            return CustomScrollView(
              slivers: [
                // ── Location Bar ────────────────────
                SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: _showAreaPicker,
                    child: Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingMD,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedArea.isEmpty
                                      ? 'All Areas'
                                      : _selectedArea,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  _selectedArea.isEmpty
                                      ? 'Tap to filter by area'
                                      : 'Tap to change area',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Search Bar ──────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.paddingMD,
                      0,
                      AppDimens.paddingMD,
                      12,
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (q) {
                        context.read<ServicesBloc>().add(
                          ServicesSearchChanged(q),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'Search services',
                        prefixIcon: const Icon(
                          Icons.search_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  context.read<ServicesBloc>().add(
                                    ServicesSearchChanged(''),
                                  );
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusFull,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Category Chips ──────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surface,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 48,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.paddingMD,
                              vertical: 6,
                            ),
                            children: _categories.entries.map((e) {
                              final sel = _selectedCategory == e.key;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedCategory = e.key);
                                    context.read<ServicesBloc>().add(
                                      ServicesCategoryFilterChanged(e.key),
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppColors.primary
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusFull,
                                      ),
                                      border: Border.all(
                                        color: sel
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (sel) ...[
                                          const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          e.value,
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: sel
                                                    ? Colors.white
                                                    : AppColors.textPrimary,
                                                fontWeight: sel
                                                    ? FontWeight.w700
                                                    : FontWeight.w400,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // Sort Bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppDimens.paddingMD,
                            0,
                            AppDimens.paddingMD,
                            10,
                          ),
                          child: Row(
                            children: [
                              Text('Sort by', style: AppTextStyles.bodySmall),
                              const SizedBox(width: 8),
                              _SortChip(
                                label: 'Distance',
                                selected: _sortBy == 'Distance',
                                hasArrow: true,
                                onTap: () =>
                                    setState(() => _sortBy = 'Distance'),
                              ),
                              const SizedBox(width: 8),
                              _SortChip(
                                label: 'A - Z',
                                selected: _sortBy == 'A-Z',
                                hasArrow: true,
                                onTap: () => setState(() => _sortBy = 'A-Z'),
                              ),
                              const Spacer(),
                              _SortChip(
                                label: 'Filters',
                                selected: _selectedCategory != 'all',
                                hasIcon: Icons.tune_outlined,
                                onTap: () => _showFiltersSheet(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Results Banner ──────────────────
                if (!loading && error == null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(AppDimens.paddingMD),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedArea.isEmpty
                                      ? 'Showing services in all areas'
                                      : 'Showing services in $_selectedArea',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '${services.length} services available',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Section title
                if (!loading && error == null && services.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.paddingMD,
                        0,
                        AppDimens.paddingMD,
                        8,
                      ),
                      child: Text(
                        'Available Services',
                        style: AppTextStyles.headlineSmall,
                      ),
                    ),
                  ),

                // ── Content ────────────────────────
                if (loading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (error != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              error,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => context.read<ServicesBloc>().add(
                                ServicesLoadAll(),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (services.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.medical_services_outlined,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedArea.isEmpty
                                ? 'No services found'
                                : 'No services found in $_selectedArea',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_selectedArea.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _showAreaPicker,
                              child: const Text('Try a different area'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingMD,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _ServiceGroupListItem(group: services[i]),
                        childCount: services.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Area Picker
// ─────────────────────────────────────────────
