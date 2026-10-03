part of 'services_bloc.dart';

abstract class ServicesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ServicesLoadByProvider extends ServicesEvent {
  final String providerId;
  ServicesLoadByProvider(this.providerId);
  @override
  List<Object?> get props => [providerId];
}

class ServicesLoadAll extends ServicesEvent {}

class ServicesSearchChanged extends ServicesEvent {
  final String query;
  ServicesSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class ServicesCategoryFilterChanged extends ServicesEvent {
  final String category;
  ServicesCategoryFilterChanged(this.category);
  @override
  List<Object?> get props => [category];
}

// ✅ Real area filter — same pattern as ProvidersBloc
class ServicesAreaChanged extends ServicesEvent {
  final String area; // '' = show all
  ServicesAreaChanged(this.area);
  @override
  List<Object?> get props => [area];
}
