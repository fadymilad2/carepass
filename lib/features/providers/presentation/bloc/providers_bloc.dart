import 'package:carepass/features/providers/data/models/provider_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/provider_entities.dart';
import '../../domain/usecases/providers_usecases.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class ProvidersEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProvidersLoadRequested extends ProvidersEvent {
  final ProvidersFilter filter;
  ProvidersLoadRequested(this.filter);
  @override
  List<Object?> get props => [filter];
}

class ProvidersTypeChanged extends ProvidersEvent {
  final ProviderType? type; // null = All
  ProvidersTypeChanged(this.type);
  @override
  List<Object?> get props => [type];
}

class ProvidersSortChanged extends ProvidersEvent {
  final ProviderSortOption sort;
  ProvidersSortChanged(this.sort);
  @override
  List<Object?> get props => [sort];
}

class ProvidersSearchChanged extends ProvidersEvent {
  final String query;
  ProvidersSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class ProvidersNearbyToggled extends ProvidersEvent {}

class ProviderDetailRequested extends ProvidersEvent {
  final String providerId;
  ProviderDetailRequested(this.providerId);
  @override
  List<Object?> get props => [providerId];
}

class ProviderFavoriteToggled extends ProvidersEvent {
  final String providerId;
  ProviderFavoriteToggled(this.providerId);
  @override
  List<Object?> get props => [providerId];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class ProvidersState extends Equatable {
  const ProvidersState();
  @override
  List<Object?> get props => [];
}

class ProvidersInitial  extends ProvidersState {}
class ProvidersLoading  extends ProvidersState {}
class ProviderDetailLoading extends ProvidersState {}

class ProvidersLoaded extends ProvidersState {
  final List<MedicalProvider> providers;
  final ProvidersFilter filter;

  const ProvidersLoaded({
    required this.providers,
    required this.filter,
  });

  ProvidersLoaded copyWith({
    List<MedicalProvider>? providers,
    ProvidersFilter? filter,
  }) => ProvidersLoaded(
    providers: providers ?? this.providers,
    filter:    filter    ?? this.filter,
  );

  @override
  List<Object?> get props => [providers, filter];
}

class ProviderDetailLoaded extends ProvidersState {
  final MedicalProvider provider;
  const ProviderDetailLoaded(this.provider);
  @override
  List<Object?> get props => [provider];
}

class ProvidersError extends ProvidersState {
  final String message;
  const ProvidersError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class ProvidersBloc extends Bloc<ProvidersEvent, ProvidersState> {
  final GetProviders    _getProviders;
  final GetProviderById _getProviderById;
  final SearchProviders _searchProviders;
  final ToggleFavorite  _toggleFavorite;

  ProvidersBloc({
    required GetProviders    getProviders,
    required GetProviderById getProviderById,
    required SearchProviders searchProviders,
    required ToggleFavorite  toggleFavorite,
  })  : _getProviders    = getProviders,
        _getProviderById = getProviderById,
        _searchProviders = searchProviders,
        _toggleFavorite  = toggleFavorite,
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
    emit(ProvidersLoading());
    final result = await _getProviders(e.filter);

    if (result.isLeft()) {
      emit(ProvidersError(result.fold((f) => f.message, (_) => '')));
      return;
    }

    emit(ProvidersLoaded(
      providers: result.getOrElse(() => []),
      filter:    e.filter,
    ));
  }

  Future<void> _onTypeChanged(
    ProvidersTypeChanged e,
    Emitter<ProvidersState> emit,
  ) async {
    if (state is! ProvidersLoaded) return;
    final current = state as ProvidersLoaded;

    final newFilter = e.type == null
        ? current.filter.copyWith(clearType: true)
        : current.filter.copyWith(type: e.type);

    emit(current.copyWith(filter: newFilter));

    final result = await _getProviders(newFilter);
    if (emit.isDone) return;

    result.fold(
      (_) {},
      (providers) => emit(current.copyWith(
        providers: providers,
        filter:    newFilter,
      )),
    );
  }

  Future<void> _onSortChanged(
    ProvidersSortChanged e,
    Emitter<ProvidersState> emit,
  ) async {
    if (state is! ProvidersLoaded) return;
    final current = state as ProvidersLoaded;
    final newFilter = current.filter.copyWith(sortBy: e.sort);

    final result = await _getProviders(newFilter);
    if (emit.isDone) return;

    result.fold(
      (_) {},
      (providers) => emit(current.copyWith(
        providers: providers,
        filter:    newFilter,
      )),
    );
  }

  Future<void> _onSearch(
    ProvidersSearchChanged e,
    Emitter<ProvidersState> emit,
  ) async {
    if (state is! ProvidersLoaded) return;
    final current = state as ProvidersLoaded;

    if (e.query.isEmpty) {
      final result = await _getProviders(current.filter);
      if (emit.isDone) return;
      result.fold(
        (_) {},
        (providers) => emit(current.copyWith(providers: providers)),
      );
      return;
    }

    final result = await _searchProviders(
      query: e.query,
      area: current.filter.area,
    );
    if (emit.isDone) return;

    result.fold(
      (_) {},
      (providers) => emit(current.copyWith(providers: providers)),
    );
  }

  Future<void> _onNearbyToggled(
    ProvidersNearbyToggled e,
    Emitter<ProvidersState> emit,
  ) async {
    if (state is! ProvidersLoaded) return;
    final current = state as ProvidersLoaded;
    final newFilter = current.filter.copyWith(
      nearbyOnly: !current.filter.nearbyOnly,
    );

    final result = await _getProviders(newFilter);
    if (emit.isDone) return;

    result.fold(
      (_) {},
      (providers) => emit(current.copyWith(
        providers: providers,
        filter:    newFilter,
      )),
    );
  }

  Future<void> _onDetailRequested(
    ProviderDetailRequested e,
    Emitter<ProvidersState> emit,
  ) async {
    emit(ProviderDetailLoading());
    final result = await _getProviderById(e.providerId);

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
          id: p.id, name: p.name, type: p.type,
          imageUrl: p.imageUrl, logoUrl: p.logoUrl,
          rating: p.rating, reviewCount: p.reviewCount,
          distanceKm: p.distanceKm, discountPercent: p.discountPercent,
          isInNetwork: p.isInNetwork, phoneNumber: p.phoneNumber,
          address: p.address, workingHours: p.workingHours,
          services: p.services, totalServices: p.totalServices,
          website: p.website, latitude: p.latitude,
          longitude: p.longitude,
          isFavorite: !p.isFavorite,
        );
      }
      return p;
    }).toList();

    emit(current.copyWith(providers: updated));
    await _toggleFavorite(e.providerId);
  }
}