import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/providers_bloc.dart';
import '../widgets/providers_widgets.dart';
import '../../domain/entities/provider_entities.dart';

class ProvidersPage extends StatefulWidget {
  const ProvidersPage({super.key});

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _currentArea = 'Accra';

  @override
  void initState() {
    super.initState();
    context.read<ProvidersBloc>().add(
          ProvidersLoadRequested(ProvidersFilter(area: _currentArea)),
        );
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<ProvidersBloc>().add(ProvidersSearchChanged(query));
      }
    });
  }

  // ✅ فتح الـ Area Picker
  void _showAreaPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProvidersAreaPicker(
        currentArea: _currentArea,
        onSelect: (area) {
          setState(() => _currentArea = area);
          context.read<ProvidersBloc>().add(
                ProvidersLoadRequested(ProvidersFilter(area: area)),
              );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────
            _ProvidersHeader(
              area: _currentArea,
              onLocationTap: _showAreaPicker, // ✅ مش () {}
            ),
        


            // ── Search ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextFormField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                decoration: const InputDecoration(
                  hintText: 'Search providers or specialties',
                  prefixIcon:
                      Icon(Icons.search, color: AppColors.textHint),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Filter Row ────────────────────────
            BlocBuilder<ProvidersBloc, ProvidersState>(
              builder: (context, state) {
                final filter = state is ProvidersLoaded
                    ? state.filter
                    : const ProvidersFilter();
                return _FilterRow(
                  filter: filter,
                  onNearbyTap: () => context
                      .read<ProvidersBloc>()
                      .add(ProvidersNearbyToggled()),
                  onSortTap: () => _showSortSheet(context, filter),
                );
              },
            ),

            const SizedBox(height: 8),

            // ── List ──────────────────────────────
            Expanded(
              child: BlocBuilder<ProvidersBloc, ProvidersState>(
                builder: (context, state) {
                  if (state is ProvidersLoading) {
                    return const _ProvidersShimmer();
                  }
                  if (state is ProvidersError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => context
                          .read<ProvidersBloc>()
                          .add(ProvidersLoadRequested(
                              ProvidersFilter(area: _currentArea))),
                    );
                  }
                  if (state is ProvidersLoaded) {
                    return _ProvidersList(
                      providers: state.providers,
                      area: _currentArea,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context, ProvidersFilter filter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        currentSort: filter.sortBy,
        onSelect: (sort) => context
            .read<ProvidersBloc>()
            .add(ProvidersSortChanged(sort)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Header
// ─────────────────────────────────────────────
class _ProvidersHeader extends StatelessWidget {
  final String area;
  final VoidCallback onLocationTap;

  const _ProvidersHeader({
    required this.area,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.go('/home'),
            padding: EdgeInsets.zero,
          ),
          Expanded(
            child: Text(
              'Providers in $area',
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.location_on,
                color: AppColors.primary),
            onPressed: onLocationTap,
          ),
        ],
      ),
    );
  }
}
class _ProvidersAreaPicker extends StatefulWidget {
  final String currentArea;
  final ValueChanged<String> onSelect;

  const _ProvidersAreaPicker({
    required this.currentArea,
    required this.onSelect,
  });

  @override
  State<_ProvidersAreaPicker> createState() => _ProvidersAreaPickerState();
}

class _ProvidersAreaPickerState extends State<_ProvidersAreaPicker> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _isLocating = false;

  static const _popularAreas = [
    'Accra', 'Kumasi', 'Tamale',
    'Takoradi', 'Tema', 'Kasoa',
  ];

  static const _allAreas = [
    'Adenta', 'Ashaiman', 'Cape Coast',
    'Ho', 'Koforidua', 'Obuasi',
    'Sunyani', 'Techiman', 'Teshie',
    'Wa', 'Winneba', 'Bolgatanga',
  ];

  List<String> get _filteredPopular => _query.isEmpty
      ? _popularAreas
      : _popularAreas
          .where((a) => a.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  List<String> get _filteredAll => _query.isEmpty
      ? _allAreas
      : _allAreas
          .where((a) => a.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Please enable location services');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timed out'),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final city = place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            'Current Location';
        widget.onSelect(city);
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {
      _showError('Could not get location. Try again.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasResults =
        _filteredPopular.isNotEmpty || _filteredAll.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Select Area',
                        style: AppTextStyles.headlineSmall),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextFormField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search for area or location',
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textHint),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // List
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: [
                  // Use current location
                  ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                      ),
                      child: _isLocating
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.my_location,
                              color: AppColors.primary, size: 18),
                    ),
                    title: Text(
                      _isLocating
                          ? 'Getting your location...'
                          : 'Use my current location',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: _isLocating ? null : _useCurrentLocation,
                  ),

                  const Divider(height: 1),

                  // Popular
                  if (_filteredPopular.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('Popular Areas',
                          style: AppTextStyles.titleMedium),
                    ),
                    ..._filteredPopular.map((area) => _AreaItem(
                          area: area,
                          isSelected: area == widget.currentArea,
                          onTap: () {
                            widget.onSelect(area);
                            Navigator.pop(context);
                          },
                        )),
                  ],

                  // All
                  if (_filteredAll.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('All Areas',
                          style: AppTextStyles.titleMedium),
                    ),
                    ..._filteredAll.map((area) => _AreaItem(
                          area: area,
                          isSelected: area == widget.currentArea,
                          onTap: () {
                            widget.onSelect(area);
                            Navigator.pop(context);
                          },
                        )),
                  ],

                  // No results
                  if (!hasResults)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off,
                              size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text('No areas found for "$_query"',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaItem extends StatelessWidget {
  final String area;
  final bool isSelected;
  final VoidCallback onTap;

  const _AreaItem({
    required this.area,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(area,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textPrimary,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
              )),
          trailing: isSelected
              ? const Icon(Icons.check,
                  color: AppColors.primary, size: 18)
              : const Icon(Icons.arrow_forward_ios,
                  color: AppColors.textHint, size: 14),
          onTap: onTap,
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }
}
// ─────────────────────────────────────────────
//  Filter Row
// ─────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final ProvidersFilter filter;
  final VoidCallback onNearbyTap;
  final VoidCallback onSortTap;

  const _FilterRow({
    required this.filter,
    required this.onNearbyTap,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // All tab
          _FilterChip(
            label: 'All',
            isSelected: !filter.nearbyOnly,
            onTap: filter.nearbyOnly ? onNearbyTap : null,
          ),
          const SizedBox(width: 8),

          // Nearby tab
          _FilterChip(
            label: 'Nearby',
            isSelected: filter.nearbyOnly,
            onTap: onNearbyTap,
          ),

          const Spacer(),

          // Sort by
          GestureDetector(
            onTap: onSortTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius:
                    BorderRadius.circular(AppDimens.radiusFull),
              ),
              child: Row(
                children: [
                  Text('Sort by',
                      style: AppTextStyles.bodySmall),
                  const SizedBox(width: 4),
                  Text(filter.sortBy.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      )),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color:
                isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius:
              BorderRadius.circular(AppDimens.radiusFull),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color:
                isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Providers List
// ─────────────────────────────────────────────
class _ProvidersList extends StatelessWidget {
  final List<MedicalProvider> providers;
  final String area;

  const _ProvidersList({
    required this.providers,
    required this.area,
  });

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('No providers found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => context.read<ProvidersBloc>().add(
            ProvidersLoadRequested(ProvidersFilter(area: area)),
          ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        children: [
          // Count
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${providers.length} providers found',
              style: AppTextStyles.bodySmall,
            ),
          ),

          // Items
          ...providers.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProviderListTile(
                  provider: p,
                  onTap: () => context.push(
                    '/providers/detail',
                    extra: p,
                  ),
                  onFavoriteTap: () => context
                      .read<ProvidersBloc>()
                      .add(ProviderFavoriteToggled(p.id)),
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Sort Sheet
// ─────────────────────────────────────────────
class _SortSheet extends StatelessWidget {
  final ProviderSortOption currentSort;
  final ValueChanged<ProviderSortOption> onSelect;

  const _SortSheet({
    required this.currentSort,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sort by', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          ...ProviderSortOption.values.map((sort) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(sort.label,
                    style: AppTextStyles.bodyMedium),
                trailing: currentSort == sort
                    ? const Icon(Icons.check,
                        color: AppColors.primary)
                    : null,
                onTap: () {
                  onSelect(sort);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Shimmer + Error
// ─────────────────────────────────────────────
class _ProvidersShimmer extends StatelessWidget {
  const _ProvidersShimmer();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_outlined,
              size: 64, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(message,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try Again')),
        ],
      ),
    );
  }
}