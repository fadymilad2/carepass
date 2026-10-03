import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/area_picker.dart';

import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/providers_bloc.dart';
import '../widgets/providers_widgets.dart';
import '../../domain/entities/provider_entities.dart';

part '../widgets/providers/providers_header.dart';

part '../widgets/providers/filter_row.dart';
part '../widgets/providers/filter_chip.dart';
part '../widgets/providers/providers_list.dart';
part '../widgets/providers/sort_sheet.dart';
part '../widgets/providers/providers_shimmer.dart';
part '../widgets/providers/error_view.dart';

class ProvidersPage extends StatefulWidget {
  const ProvidersPage({super.key});

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _currentArea = '';

  @override
  void initState() {
    super.initState();
    context.read<ProvidersBloc>().add(
      ProvidersLoadRequested(const ProvidersFilter()),
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

  void _showAreaPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AreaPicker(
        currentArea: _currentArea,
        onSelect: (area) {
          setState(() => _currentArea = area);
          context.read<ProvidersBloc>().add(
            ProvidersLoadRequested(ProvidersFilter(area: area)),
          );
        },
        onClear: () {
          setState(() => _currentArea = '');
          context.read<ProvidersBloc>().add(
            ProvidersLoadRequested(const ProvidersFilter()),
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
            _ProvidersHeader(
              area: _currentArea,
              onLocationTap: _showAreaPicker,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextFormField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                decoration: const InputDecoration(
                  hintText: 'Search providers or specialties',
                  prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                ),
              ),
            ),
            const SizedBox(height: 12),
            BlocBuilder<ProvidersBloc, ProvidersState>(
              builder: (context, state) {
                final filter = state is ProvidersLoaded
                    ? state.filter
                    : const ProvidersFilter();
                return Column(
                  children: [
                    _FilterRow(
                      filter: filter,
                      onNearbyTap: () => context.read<ProvidersBloc>().add(
                        ProvidersNearbyToggled(),
                      ),
                      onSortTap: () => _showSortSheet(context, filter),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All categories',
                            isSelected: filter.type == null,
                            onTap: () => context.read<ProvidersBloc>().add(
                              ProvidersTypeChanged(null),
                            ),
                          ),
                          ...ProviderType.values.map(
                            (type) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _FilterChip(
                                label: type.label,
                                isSelected: filter.type == type,
                                onTap: () => context.read<ProvidersBloc>().add(
                                  ProvidersTypeChanged(type),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<ProvidersBloc, ProvidersState>(
                builder: (context, state) {
                  if (state is ProvidersLoading) {
                    return const _ProvidersShimmer();
                  }
                  if (state is ProvidersError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => context.read<ProvidersBloc>().add(
                        ProvidersLoadRequested(
                          ProvidersFilter(area: _currentArea),
                        ),
                      ),
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
        onSelect: (sort) =>
            context.read<ProvidersBloc>().add(ProvidersSortChanged(sort)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Header
// ─────────────────────────────────────────────
