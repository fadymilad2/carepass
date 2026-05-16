import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/home_entities.dart';
import '../../domain/usecases/home_usecases.dart';

// ═══════════════════════════════════════════════
//  EVENTS
// ═══════════════════════════════════════════════
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

// ═══════════════════════════════════════════════
//  STATES
// ═══════════════════════════════════════════════
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

  const HomeLoaded({
    required this.user,
    required this.banners,
    this.stats,
    this.isBannersLoading = false,
  });

  HomeLoaded copyWith({
    UserSummary? user,
    List<HomeBanner>? banners,
    HomeQuickStat? stats,
    bool? isBannersLoading,
  }) {
    return HomeLoaded(
      user: user ?? this.user,
      banners: banners ?? this.banners,
      stats: stats ?? this.stats,
      isBannersLoading: isBannersLoading ?? this.isBannersLoading,
    );
  }

  @override
  List<Object?> get props => [user, banners, stats, isBannersLoading];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}

// ═══════════════════════════════════════════════
//  BLOC
// ═══════════════════════════════════════════════
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetUserSummary _getUserSummary;
  final GetHomeBanners _getHomeBanners;
  final GetHomeQuickStats _getHomeQuickStats;

  HomeBloc({
    required GetUserSummary getUserSummary,
    required GetHomeBanners getHomeBanners,
    required GetHomeQuickStats getHomeQuickStats,
  })  : _getUserSummary = getUserSummary,
        _getHomeBanners = getHomeBanners,
        _getHomeQuickStats = getHomeQuickStats,
        super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeBannersRefreshRequested>(_onRefreshBanners);
    on<HomeAreaChanged>(_onAreaChanged);
  }

  Future<void> _onLoad(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());

    // Step 1: Get user
    final userResult = await _getUserSummary();
    
    // هنستخدم طريقة الـ await fold عشان الـ BLoC يستنى النتيجة صح
    await userResult.fold(
      (failure) async {
        emit(HomeError(failure.message));
      },
      (user) async {
        // Step 2: Load banners & stats in parallel
        final results = await Future.wait([
          _getHomeBanners(
            isSubscribed: user.subscriptionStatus != SubscriptionStatus.none, // عدلها حسب الـ entity بتاعك
            area: user.selectedArea,
          ),
          _getHomeQuickStats(
            userId: user.id,
            area: user.selectedArea,
          ),
        ]);

        final bannersResult = results[0];
        final statsResult = results[1];

        // استخراج البانرات
        final banners = bannersResult.fold(
          (_) => <HomeBanner>[],
          (b) => b as List<HomeBanner>,
        );

        // استخراج الإحصائيات
        final stats = statsResult.fold(
          (_) => null,
          (s) => s as HomeQuickStat,
        );

        emit(HomeLoaded(user: user, banners: banners, stats: stats));
      },
    );
  }

  Future<void> _onRefreshBanners(
    HomeBannersRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final current = state as HomeLoaded;

    emit(current.copyWith(isBannersLoading: true));

    final result = await _getHomeBanners(
      isSubscribed: current.user.isSubscribed,
      area: current.user.selectedArea,
    );

    result.fold(
      (_) => emit(current.copyWith(isBannersLoading: false)),
      (banners) => emit(current.copyWith(banners: banners, isBannersLoading: false)),
    );
  }

  Future<void> _onAreaChanged(
    HomeAreaChanged event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final current = state as HomeLoaded;

    // Reload banners for new area
    final result = await _getHomeBanners(
      isSubscribed: current.user.isSubscribed,
      area: event.area,
    );

    result.fold(
      (_) {},
      (banners) => emit(current.copyWith(banners: banners)),
    );
  }
}