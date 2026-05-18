import 'dart:async';
import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/services_bloc.dart';
import '../widgets/services_widgets.dart';
import '../../domain/entities/service_entities.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  Timer? _debounce;
  final _searchCtrl = TextEditingController();
  String _currentArea = 'Accra';

  @override
  void initState() {
    super.initState();
    context.read<ServicesBloc>().add(
          ServicesLoadRequested(ServicesFilter(area: _currentArea)),
        );
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<ServicesBloc>().add(ServicesSearchChanged(query));
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _showAreaPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AreaPickerSheet(
        currentArea: _currentArea,
        onSelect: (area) {
          setState(() => _currentArea = area);
          context.read<ServicesBloc>().add(ServicesAreaChanged(area));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Services'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          // ── Location bar ──────────────────────────
          LocationBar(
            area: _currentArea,
            onChangeTap: () => _showAreaPicker(context),
          ),

          // ── Search bar ────────────────────────────
          SearchBar(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
          ),

          // ── Category tabs ─────────────────────────
          BlocBuilder<ServicesBloc, ServicesState>(
            builder: (context, state) {
              final selected = state is ServicesLoaded
                  ? state.filter.category
                  : ServiceCategory.all;
              return ServiceCategoryTabs(
                selected: selected,
                onSelect: (cat) => context
                    .read<ServicesBloc>()
                    .add(ServicesCategoryChanged(cat)),
              );
            },
          ),

          // ── Sort bar ──────────────────────────────
          BlocBuilder<ServicesBloc, ServicesState>(
            builder: (context, state) {
              final filter = state is ServicesLoaded
                  ? state.filter
                  : const ServicesFilter();
              return ServicesSortBar(
                filter: filter,
                onSortByDistance: () => context
                    .read<ServicesBloc>()
                    .add(ServicesSortChanged(SortOption.distance)),
                onSortAlpha: () => context
                    .read<ServicesBloc>()
                    .add(ServicesSortChanged(SortOption.alphabetical)),
              );
            },
          ),

          // ── Content ───────────────────────────────
          Expanded(
            child: BlocBuilder<ServicesBloc, ServicesState>(
              builder: (context, state) {
                if (state is ServicesLoading) {
                  return const _ServicesShimmer();
                }
                if (state is ServicesError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () => context
                        .read<ServicesBloc>()
                        .add(ServicesLoadRequested(
                            ServicesFilter(area: _currentArea))),
                  );
                }
                if (state is ServicesLoaded) {
                  return _ServicesList(
                    services: state.services,
                    area: _currentArea,
                    isSearching: state.isSearching,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Services List
// ─────────────────────────────────────────────
class _ServicesList extends StatelessWidget {
  final List<MedicalService> services;
  final String area;
  final bool isSearching;

  const _ServicesList({
    required this.services,
    required this.area,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('No services found',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<ServicesBloc>().add(
              ServicesLoadRequested(ServicesFilter(area: area)),
            );
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          ResultsBanner(
            count: services.length,
            area: area,
            isSearching: isSearching,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Popular Services in $area',
              style: AppTextStyles.headlineSmall,
            ),
          ),
          ...services.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ServiceListTile(
                service: service,
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Area Picker Sheet — مع Search + Location
// ─────────────────────────────────────────────
class _AreaPickerSheet extends StatefulWidget {
  final String currentArea;
  final ValueChanged<String> onSelect;

  const _AreaPickerSheet({
    required this.currentArea,
    required this.onSelect,
  });

  @override
  State<_AreaPickerSheet> createState() => _AreaPickerSheetState();
}

class _AreaPickerSheetState extends State<_AreaPickerSheet> {
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
      // ── Check if service enabled ─────────────────
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Please enable location services');
        return;
      }

      // ── Check / Request permission ───────────────
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        // iOS & Android → open settings
        await Geolocator.openAppSettings();
        return;
      }

      // ── Get position ─────────────────────────────
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // ── Reverse geocode ──────────────────────────
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
    } on TimeoutException {
      _showError('Location timed out. Try again.');
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

            // ── Handle ────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),

            // ── Header ────────────────────────────
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

            // ── Search ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextFormField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search for area or location',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textHint,
                  ),
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

            // ── List ──────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: [

                  // Use my current location
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
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

                  // ── Popular Areas ──────────────
                  if (_filteredPopular.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text('Popular Areas',
                          style: AppTextStyles.titleMedium),
                    ),
                    ..._filteredPopular.map((area) => _AreaTile(
                          area: area,
                          isSelected: area == widget.currentArea,
                          onTap: () {
                            widget.onSelect(area);
                            Navigator.pop(context);
                          },
                        )),
                  ],

                  // ── All Areas ──────────────────
                  if (_filteredAll.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text('All Areas',
                          style: AppTextStyles.titleMedium),
                    ),
                    ..._filteredAll.map((area) => _AreaTile(
                          area: area,
                          isSelected: area == widget.currentArea,
                          onTap: () {
                            widget.onSelect(area);
                            Navigator.pop(context);
                          },
                        )),
                  ],

                  // ── No results ─────────────────
                  if (!hasResults)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off,
                              size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text(
                            'No areas found for "$_query"',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
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

// ─────────────────────────────────────────────
//  Area Tile
// ─────────────────────────────────────────────
class _AreaTile extends StatelessWidget {
  final String area;
  final bool isSelected;
  final VoidCallback onTap;

  const _AreaTile({
    required this.area,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 2),
          title: Text(
            area,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textPrimary,
              fontWeight: isSelected
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
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
//  Shimmer
// ─────────────────────────────────────────────
class _ServicesShimmer extends StatelessWidget {
  const _ServicesShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Error View
// ─────────────────────────────────────────────
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
          Text(
            message,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}