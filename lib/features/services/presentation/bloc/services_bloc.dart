import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/service_entities.dart';
import '../../domain/usecases/get_services.dart';

// ── Events ──────────────────────────────────────────────
part 'services_event.dart';
part 'services_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final GetServicesByProvider _getByProvider;
  final GetAllServices _getAll;

  List<ServiceEntity> _all = [];
  String _categoryFilter = 'all';
  String _searchQuery = '';

  // Area filter state
  int _areaVersion = 0;
  String _currentArea = ''; // '' = no filter
  Set<String> _providerIdsInArea = {};

  ServicesBloc({
    required GetServicesByProvider getByProvider,
    required GetAllServices getAll,
  }) : _getByProvider = getByProvider,
       _getAll = getAll,
       super(ServicesInitial()) {
    on<ServicesLoadByProvider>(_onLoadByProvider);
    on<ServicesLoadAll>(_onLoadAll);
    on<ServicesSearchChanged>(_onSearch);
    on<ServicesCategoryFilterChanged>(_onFilter);
    on<ServicesAreaChanged>(_onAreaChanged);
  }

  // ✅ Collapses casing/whitespace differences so the same service
  // typed slightly differently in the dashboard still groups together
  String _normalize(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  // Category + search + area — flat list, before grouping
  List<ServiceEntity> _applyFlatFilter() {
    final query = _searchQuery.toLowerCase().trim();
    final selCat = _categoryFilter.toLowerCase().replaceAll('_', ' ').trim();

    return _all.where((s) {
      final normCat = s.category.toLowerCase().replaceAll('_', ' ').trim();
      final normLabel = s.categoryLabel
          .toLowerCase()
          .replaceAll('_', ' ')
          .trim();

      final matchCat =
          selCat == 'all' ||
          normCat.contains(selCat) ||
          selCat.contains(normCat) ||
          normLabel.contains(selCat);

      final matchSearch =
          query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          normLabel.contains(query) ||
          normCat.contains(query);

      // ✅ Area filter — only applies when an area is actually selected
      final matchArea =
          _currentArea.isEmpty || _providerIdsInArea.contains(s.providerId);

      return matchCat && matchSearch && matchArea;
    }).toList();
  }

  // ✅ Groups identical services (same name + category) from
  // different providers into ONE card. Applied AFTER area filtering,
  // so a group's "Up to X%" and provider count reflect only
  // providers located in the selected area.
  List<ServiceGroup> _groupServices(List<ServiceEntity> services) {
    final Map<String, List<ServiceEntity>> buckets = {};

    for (final s in services) {
      final key = '${_normalize(s.category)}::${_normalize(s.name)}';
      buckets.putIfAbsent(key, () => []).add(s);
    }

    final groups = buckets.values.map((offerings) {
      final withImage = offerings.where((o) => o.hasImage);
      final imageUrl = withImage.isNotEmpty ? withImage.first.imageUrl : null;
      final first = offerings.first;

      return ServiceGroup(
        name: first.name,
        category: first.category,
        categoryLabel: first.categoryLabel,
        categoryIcon: first.categoryIcon,
        imageUrl: imageUrl,
        offerings: offerings,
      );
    }).toList();

    groups.sort((a, b) => a.name.compareTo(b.name));
    return groups;
  }

  List<ServiceGroup> _applyFilter() => _groupServices(_applyFlatFilter());

  Future<void> _onLoadByProvider(
    ServicesLoadByProvider e,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());
    final result = await _getByProvider(e.providerId);
    if (result.isLeft()) {
      emit(ServicesError(result.fold((f) => f.message, (_) => '')));
      return;
    }
    _all = result.getOrElse(() => []);
    emit(
      ServicesLoaded(
        all: _all,
        filtered: _applyFilter(),
        categoryFilter: _categoryFilter,
        areaFilter: _currentArea,
      ),
    );
  }

  Future<void> _onLoadAll(
    ServicesLoadAll e,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());
    final result = await _getAll();
    if (result.isLeft()) {
      emit(ServicesError(result.fold((f) => f.message, (_) => '')));
      return;
    }
    _all = result.getOrElse(() => []);
    emit(
      ServicesLoaded(
        all: _all,
        filtered: _applyFilter(),
        categoryFilter: _categoryFilter,
        areaFilter: _currentArea,
      ),
    );
  }

  void _onSearch(ServicesSearchChanged e, Emitter<ServicesState> emit) {
    _searchQuery = e.query.toLowerCase();
    if (state is ServicesLoaded) {
      emit(
        ServicesLoaded(
          all: _all,
          filtered: _applyFilter(),
          categoryFilter: _categoryFilter,
          areaFilter: _currentArea,
        ),
      );
    }
  }

  void _onFilter(ServicesCategoryFilterChanged e, Emitter<ServicesState> emit) {
    _categoryFilter = e.category;
    if (state is ServicesLoaded) {
      emit(
        ServicesLoaded(
          all: _all,
          filtered: _applyFilter(),
          categoryFilter: _categoryFilter,
          areaFilter: _currentArea,
        ),
      );
    }
  }

  // Loads providers in the selected area (single-field query,
  // no compound index needed), then re-filters + re-groups
  Future<void> _onAreaChanged(
    ServicesAreaChanged e,
    Emitter<ServicesState> emit,
  ) async {
    final version = ++_areaVersion;
    _currentArea = e.area;
    _providerIdsInArea.clear();

    if (e.area.isNotEmpty) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('providers')
            .where('isActive', isEqualTo: true)
            .where('area', isEqualTo: e.area)
            .get();

        if (emit.isDone || version != _areaVersion) return;
        _providerIdsInArea = snap.docs.map((d) => d.id).toSet();
      } catch (_) {
        if (emit.isDone || version != _areaVersion) return;
        _providerIdsInArea = {};
      }
    }

    if (!emit.isDone && state is ServicesLoaded) {
      emit(
        ServicesLoaded(
          all: _all,
          filtered: _applyFilter(),
          categoryFilter: _categoryFilter,
          areaFilter: _currentArea,
        ),
      );
    }
  }
}
