part of 'services_bloc.dart';

abstract class ServicesState extends Equatable {
  const ServicesState();
  @override
  List<Object?> get props => [];
}

class ServicesInitial extends ServicesState {}

class ServicesLoading extends ServicesState {}

class ServicesLoaded extends ServicesState {
  final List<ServiceEntity> all; // flat list — for counts
  final List<ServiceGroup> filtered; // ✅ grouped by name+category
  final String categoryFilter;
  final String areaFilter;

  const ServicesLoaded({
    required this.all,
    required this.filtered,
    required this.categoryFilter,
    required this.areaFilter,
  });

  @override
  List<Object?> get props => [all, filtered, categoryFilter, areaFilter];
}

class ServicesError extends ServicesState {
  final String message;
  const ServicesError(this.message);
  @override
  List<Object?> get props => [message];
}
