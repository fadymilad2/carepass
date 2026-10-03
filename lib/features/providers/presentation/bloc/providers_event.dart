part of 'providers_bloc.dart';

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
