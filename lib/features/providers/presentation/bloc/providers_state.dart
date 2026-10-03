part of 'providers_bloc.dart';

abstract class ProvidersState extends Equatable {
  const ProvidersState();
  @override
  List<Object?> get props => [];
}

class ProvidersInitial extends ProvidersState {}

class ProvidersLoading extends ProvidersState {}

class ProviderDetailLoading extends ProvidersState {}

class ProvidersLoaded extends ProvidersState {
  final List<MedicalProvider> providers;
  final ProvidersFilter filter;

  const ProvidersLoaded({required this.providers, required this.filter});

  ProvidersLoaded copyWith({
    List<MedicalProvider>? providers,
    ProvidersFilter? filter,
  }) => ProvidersLoaded(
    providers: providers ?? this.providers,
    filter: filter ?? this.filter,
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
