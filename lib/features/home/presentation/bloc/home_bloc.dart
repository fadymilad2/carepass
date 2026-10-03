import 'package:carepass/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/home_entities.dart';
import '../../domain/usecases/home_usecases.dart';

// ═══════════════════════════════════════════════
//  EVENTS
// ═══════════════════════════════════════════════
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetUserSummary _getUserSummary;
  final GetHomeBanners _getHomeBanners;
  final GetHomeQuickStats _getHomeQuickStats;
  // ✅ تعريف الـ UseCases الجديدة
  final GetPopularServices _getPopularServices;
  final GetNearbyProviders _getNearbyProviders;
  int _loadVersion = 0;

  HomeBloc({
    required GetUserSummary getUserSummary,
    required GetHomeBanners getHomeBanners,
    required GetHomeQuickStats getHomeQuickStats,
    required GetPopularServices getPopularServices,
    required GetNearbyProviders getNearbyProviders,
  }) : _getUserSummary = getUserSummary,
       _getHomeBanners = getHomeBanners,
       _getHomeQuickStats = getHomeQuickStats,
       _getPopularServices = getPopularServices,
       _getNearbyProviders = getNearbyProviders,
       super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeBannersRefreshRequested>(_onRefreshBanners);
    on<HomeAreaChanged>(_onAreaChanged);
  }

  Future<void> _onLoad(HomeLoadRequested event, Emitter<HomeState> emit) async {
    final version = ++_loadVersion;
    emit(HomeLoading());

    // Step 1: Get user
    final userResult = await _getUserSummary();

    await userResult.fold(
      (failure) async {
        if (emit.isDone || version != _loadVersion) return;
        emit(HomeError(failure.message));
      },
      (user) async {
        if (emit.isDone || version != _loadVersion) return;
        // Step 2: Load banners, stats, services, & providers in parallel
        final results = await Future.wait([
          _getHomeBanners(
            isSubscribed: user.subscriptionStatus != SubscriptionStatus.none,
            area: user.selectedArea,
          ),
          _getHomeQuickStats(userId: user.id, area: user.selectedArea),
          _getPopularServices(user.selectedArea ?? ''), // ✅ جلب الخدمات
          _getNearbyProviders(user.selectedArea ?? ''), // ✅ جلب البروفايدرز
        ]);
        if (emit.isDone || version != _loadVersion) return;

        // استخراج النتائج بـ fold عشان نفصل النجاح عن الفشل (Clean Architecture)
        final banners = (results[0] as Either<Failure, List<HomeBanner>>).fold(
          (_) => <HomeBanner>[],
          (b) => b,
        );

        final stats = (results[1] as Either<Failure, HomeQuickStat>).fold(
          (_) => null,
          (s) => s,
        );

        final services = (results[2] as Either<Failure, List<HomeServiceItem>>)
            .fold((_) => <HomeServiceItem>[], (s) => s);

        final providers =
            (results[3] as Either<Failure, List<HomeProviderItem>>).fold(
              (_) => <HomeProviderItem>[],
              (p) => p,
            );

        emit(
          HomeLoaded(
            user: user,
            banners: banners,
            stats: stats,
            services: services, // ✅ إرسال الخدمات للـ UI
            providers: providers, // ✅ إرسال البروفايدرز للـ UI
            hasProvidersError:
                (results[3] as Either<Failure, List<HomeProviderItem>>)
                    .isLeft(),
          ),
        );
      },
    );
  }

  Future<void> _onRefreshBanners(
    HomeBannersRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final current = state as HomeLoaded;

    final version = _loadVersion;

    emit(current.copyWith(isBannersLoading: true));

    final result = await _getHomeBanners(
      isSubscribed: current.user.isSubscribed,
      area: current.user.selectedArea,
    );
    if (emit.isDone || version != _loadVersion || state is! HomeLoaded) return;
    final latest = state as HomeLoaded;

    result.fold(
      (_) => emit(latest.copyWith(isBannersLoading: false)),
      (banners) =>
          emit(latest.copyWith(banners: banners, isBannersLoading: false)),
    );
  }

  Future<void> _onAreaChanged(
    HomeAreaChanged event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeLoaded) return;
    final current = state as HomeLoaded;
    final version = ++_loadVersion;
    emit(
      current.copyWith(
        providers: [],
        hasProvidersError: false,
        isProvidersLoading: true,
      ),
    );

    // Reload banners, services, and providers for the new area
    final results = await Future.wait([
      _getHomeBanners(
        isSubscribed: current.user.isSubscribed,
        area: event.area,
      ),
      _getPopularServices(event.area),
      _getNearbyProviders(event.area),
    ]);
    if (emit.isDone || version != _loadVersion) return;

    final banners = (results[0] as Either<Failure, List<HomeBanner>>).fold(
      (_) => current.banners,
      (b) => b,
    );
    final services = (results[1] as Either<Failure, List<HomeServiceItem>>)
        .fold((_) => current.services, (s) => s);
    final providers = (results[2] as Either<Failure, List<HomeProviderItem>>)
        .fold((_) => <HomeProviderItem>[], (p) => p);

    emit(
      current.copyWith(
        banners: banners,
        services: services,
        providers: providers,
        isProvidersLoading: false,
        hasProvidersError:
            (results[2] as Either<Failure, List<HomeProviderItem>>).isLeft(),
      ),
    );
  }
}
