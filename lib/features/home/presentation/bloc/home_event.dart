part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeLoadRequested extends HomeEvent {}

class HomeBannersRefreshRequested extends HomeEvent {}

class HomeAreaChanged extends HomeEvent {
  final String area;
  HomeAreaChanged(this.area);
  @override
  List<Object?> get props => [area];
}
