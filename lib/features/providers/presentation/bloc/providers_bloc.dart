import 'package:carepass/features/providers/data/models/provider_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/provider_entities.dart';
import '../../domain/usecases/providers_usecases.dart';

// ── Events ────────────────────────────────────────────────────────────────────
part 'providers_event.dart';
part 'providers_state.dart';

class ProvidersBloc extends Bloc<ProvidersEvent, ProvidersState> {
  final GetProviders _getProviders;
  final GetProviderById _getProviderById;
  int _requestVersion = 0;
  final ToggleFavorite _toggleFavorite;

  ProvidersBloc({
    required GetProviders getProviders,
    required GetProviderById getProviderById,
    required SearchProviders searchProviders,
    required ToggleFavorite toggleFavorite,
  }) : _getProviders = getProviders,
       _getProviderById = getProviderById,
       _toggleFavorite = toggleFavorite,
       super(ProvidersInitial()) {
    on<ProvidersLoadRequested>(_onLoad);
    on<ProvidersTypeChanged>(_onTypeChanged);
    on<ProvidersSortChanged>(_onSortChanged);
    on<ProvidersSearchChanged>(_onSearch);
    on<ProvidersNearbyToggled>(_onNearbyToggled);
    on<ProviderDetailRequested>(_onDetailRequested);
    on<ProviderFavoriteToggled>(_onFavoriteToggled);
  }

  Future<void> _onLoad(
    ProvidersLoadRequested e,
    Emitter<ProvidersState> emit,
  ) async {
    final version = ++_requestVersion;
    emit(ProvidersLoading());
    final result = await _getProviders(e.filter);

    if (emit.isDone || version != _requestVersion) return;
    if (result.isLeft()) {
      emit(ProvidersError(result.fold((f) => f.message, (_) => '')));
      return;
    }

    emit(
      ProvidersLoaded(providers: result.getOrElse(() => []), filter: e.filter),
    );
  }

  Future<void> _onTypeChanged(
    ProvidersTypeChanged e,
    Emitter<ProvidersState> emit,
  ) async {
    if (state is! ProvidersLoaded) return;
    final version = ++_requestVersion;
    final current = state as ProvidersLoaded;

    final newFilter = e.type == null
        ? current.filter.copyWith(clearType: true)
        : current.filter.copyWith(type: e.type);

    emit(current.copyWith(filter: newFilter));
    final result = await _getProviders(newFilter);
    if (emit.isDone || version != _requestVersion) return;

    result.fold(
      (failure) => emit(ProvidersError(failure.message)),
      (providers) =>
          emit(current.copyWith(providers: providers, filter: newFilter)),
    );
  }

  Future<void> _onSortChanged(
    ProvidersSortChanged e,
    Emitter<ProvidersState> emit,
  ) async {
    if (state is! ProvidersLoaded) return;
    final version = ++_requestVersion;
    final current = state as ProvidersLoaded;
    final newFilter = current.filter.copyWith(sortBy: e.sort);

    emit(current.copyWith(filter: newFilter));
    final result = await _getProviders(newFilter);
    if (emit.isDone || version != _requestVersion) return;

    result.fold(
      (failure) => emit(ProvidersError(failure.message)),
      (providers) =>
          emit(current.copyWith(providers: providers, filter: newFilter)),
    );
  }

  Future<void> _onSearch(
    ProvidersSearchChanged e,
    Emitter<ProvidersState> emit,
  ) async {
    if (state is! ProvidersLoaded) return;
    final version = ++_requestVersion;
    final current = state as ProvidersLoaded;

    final filter = current.filter.copyWith(searchQuery: e.query.trim());
    emit(current.copyWith(filter: filter));
    final result = await _getProviders(filter);
    if (emit.isDone || version != _requestVersion) return;
    result.fold(
      (failure) => emit(ProvidersError(failure.message)),
      (providers) =>
          emit(current.copyWith(providers: providers, filter: filter)),
    );
  }

  Future<void> _onNearbyToggled(
    ProvidersNearbyToggled e,
    Emitter<ProvidersState> emit,
  ) async {
    if (state is! ProvidersLoaded) return;
    final version = ++_requestVersion;
    final current = state as ProvidersLoaded;
    final newFilter = current.filter.copyWith(
      nearbyOnly: !current.filter.nearbyOnly,
    );

    emit(current.copyWith(filter: newFilter));
    final result = await _getProviders(newFilter);
    if (emit.isDone || version != _requestVersion) return;

    result.fold(
      (failure) => emit(ProvidersError(failure.message)),
      (providers) =>
          emit(current.copyWith(providers: providers, filter: newFilter)),
    );
  }

  Future<void> _onDetailRequested(
    ProviderDetailRequested e,
    Emitter<ProvidersState> emit,
  ) async {
    final version = ++_requestVersion;
    emit(ProviderDetailLoading());
    final result = await _getProviderById(e.providerId);

    if (emit.isDone || version != _requestVersion) return;
    if (result.isLeft()) {
      emit(ProvidersError(result.fold((f) => f.message, (_) => '')));
      return;
    }

    emit(ProviderDetailLoaded(result.getOrElse(() => throw Exception())));
  }

  Future<void> _onFavoriteToggled(
    ProviderFavoriteToggled e,
    Emitter<ProvidersState> emit,
  ) async {
    if (state is! ProvidersLoaded) return;
    final current = state as ProvidersLoaded;

    // Optimistic update
    final updated = current.providers.map((p) {
      if (p.id == e.providerId) {
        return MedicalProviderModel(
          id: p.id,
          name: p.name,
          type: p.type,
          types: p.types,
          imageUrl: p.imageUrl,
          logoUrl: p.logoUrl,
          rating: p.rating,
          reviewCount: p.reviewCount,
          distanceKm: p.distanceKm,
          discountPercent: p.discountPercent,
          isInNetwork: p.isInNetwork,
          phoneNumber: p.phoneNumber,
          address: p.address,
          workingHours: p.workingHours,
          services: p.services,
          totalServices: p.totalServices,
          website: p.website,
          latitude: p.latitude,
          longitude: p.longitude,
          isFavorite: !p.isFavorite,
          area: p.area,
        );
      }
      return p;
    }).toList();

    emit(current.copyWith(providers: updated));
    final result = await _toggleFavorite(e.providerId);
    if (emit.isDone) return;
    if (result.isLeft() && state == current.copyWith(providers: updated)) {
      emit(current);
    }
  }
}
