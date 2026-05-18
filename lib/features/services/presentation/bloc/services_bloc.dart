import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/service_entities.dart';
import '../../domain/usecases/services_usecases.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class ServicesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ServicesLoadRequested extends ServicesEvent {
  final ServicesFilter filter;
  ServicesLoadRequested(this.filter);
  @override
  List<Object?> get props => [filter];
}

class ServicesCategoryChanged extends ServicesEvent {
  final ServiceCategory category;
  ServicesCategoryChanged(this.category);
  @override
  List<Object?> get props => [category];
}

class ServicesSortChanged extends ServicesEvent {
  final SortOption sort;
  ServicesSortChanged(this.sort);
  @override
  List<Object?> get props => [sort];
}

class ServicesSearchChanged extends ServicesEvent {
  final String query;
  ServicesSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class ServicesAreaChanged extends ServicesEvent {
  final String area;
  ServicesAreaChanged(this.area);
  @override
  List<Object?> get props => [area];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class ServicesState extends Equatable {
  const ServicesState();
  @override
  List<Object?> get props => [];
}

class ServicesInitial  extends ServicesState {}
class ServicesLoading  extends ServicesState {}

class ServicesLoaded extends ServicesState {
  final List<MedicalService> services;
  final ServicesFilter filter;
  final bool isSearching;

  const ServicesLoaded({
    required this.services,
    required this.filter,
    this.isSearching = false,
  });

  ServicesLoaded copyWith({
    List<MedicalService>? services,
    ServicesFilter? filter,
    bool? isSearching,
  }) => ServicesLoaded(
    services:   services   ?? this.services,
    filter:     filter     ?? this.filter,
    isSearching: isSearching ?? this.isSearching,
  );

  @override
  List<Object?> get props => [services, filter, isSearching];
}

class ServicesError extends ServicesState {
  final String message;
  const ServicesError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final GetServices    _getServices;
  final SearchServices _searchServices;


  ServicesBloc({
    required GetServices    getServices,
    required SearchServices searchServices,
  })  : _getServices    = getServices,
        _searchServices = searchServices,
        super(ServicesInitial()) {
    on<ServicesLoadRequested>(_onLoad);
    on<ServicesCategoryChanged>(_onCategoryChanged);
    on<ServicesSortChanged>(_onSortChanged);
    on<ServicesSearchChanged>(_onSearchChanged);
    on<ServicesAreaChanged>(_onAreaChanged);
  }

  ServicesFilter get _currentFilter =>
      state is ServicesLoaded
          ? (state as ServicesLoaded).filter
          : const ServicesFilter();

  Future<void> _onLoad(
    ServicesLoadRequested e,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());
    final result = await _getServices(e.filter);

    if (result.isLeft()) {
      emit(ServicesError(result.fold((f) => f.message, (_) => '')));
      return;
    }

    emit(ServicesLoaded(
      services: result.getOrElse(() => []),
      filter:   e.filter,
    ));
  }

  Future<void> _onCategoryChanged(
    ServicesCategoryChanged e,
    Emitter<ServicesState> emit,
  ) async {
    final newFilter = _currentFilter.copyWith(category: e.category);

    if (state is ServicesLoaded) {
      emit((state as ServicesLoaded).copyWith(filter: newFilter));
    }

    final result = await _getServices(newFilter);
    result.fold(
      (_) {},
      (services) {
        if (state is ServicesLoaded) {
          emit((state as ServicesLoaded).copyWith(services: services));
        }
      },
    );
  }

  Future<void> _onSortChanged(
    ServicesSortChanged e,
    Emitter<ServicesState> emit,
  ) async {
    final newFilter = _currentFilter.copyWith(sortBy: e.sort);
    final result = await _getServices(newFilter);

    result.fold(
      (_) {},
      (services) {
        if (state is ServicesLoaded) {
          emit((state as ServicesLoaded)
              .copyWith(services: services, filter: newFilter));
        }
      },
    );
  }

  Future<void> _onSearchChanged(
  ServicesSearchChanged e,
  Emitter<ServicesState> emit,
) async {
  if (state is! ServicesLoaded) return;
  final current = state as ServicesLoaded;

  if (e.query.isEmpty) {
    // رجّع الـ full list
    final result = await _getServices(current.filter);
    result.fold(
      (_) {},
      (services) => emit(current.copyWith(
        services: services,
        isSearching: false,
      )),
    );
    return;
  }

  // Search محلي على الـ data الموجودة
  final result = await _searchServices(
    query: e.query,
    area: current.filter.area,
  );

  if (emit.isDone) return; // ✅ check قبل emit

  result.fold(
    (_) {},
    (services) => emit(current.copyWith(
      services: services,
      isSearching: false,
    )),
  );
}

  Future<void> _onAreaChanged(
    ServicesAreaChanged e,
    Emitter<ServicesState> emit,
  ) async {
    final newFilter = _currentFilter.copyWith(area: e.area);
    add(ServicesLoadRequested(newFilter));
  }

}