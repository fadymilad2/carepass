part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final UserSummary user;
  final List<HomeBanner> banners;
  final HomeQuickStat? stats;
  final bool isBannersLoading;
  // ✅ الإضافات الجديدة
  final List<HomeServiceItem> services;
  final List<HomeProviderItem> providers;
  final bool hasProvidersError;
  final bool isProvidersLoading;

  const HomeLoaded({
    required this.user,
    required this.banners,
    this.stats,
    this.isBannersLoading = false,
    this.services = const [],
    this.providers = const [],
    this.hasProvidersError = false,
    this.isProvidersLoading = false,
  });

  HomeLoaded copyWith({
    UserSummary? user,
    List<HomeBanner>? banners,
    HomeQuickStat? stats,
    bool? isBannersLoading,
    List<HomeServiceItem>? services,
    List<HomeProviderItem>? providers,
    bool? hasProvidersError,
    bool? isProvidersLoading,
  }) {
    return HomeLoaded(
      user: user ?? this.user,
      banners: banners ?? this.banners,
      stats: stats ?? this.stats,
      isBannersLoading: isBannersLoading ?? this.isBannersLoading,
      services: services ?? this.services,
      providers: providers ?? this.providers,
      hasProvidersError: hasProvidersError ?? this.hasProvidersError,
      isProvidersLoading: isProvidersLoading ?? this.isProvidersLoading,
    );
  }

  @override
  List<Object?> get props => [
    user,
    banners,
    stats,
    isBannersLoading,
    services,
    providers,
    hasProvidersError,
    isProvidersLoading,
  ];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}
