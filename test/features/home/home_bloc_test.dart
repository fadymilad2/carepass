import 'package:carepass/core/errors/failures.dart';
import 'package:carepass/features/home/domain/entities/home_entities.dart';
import 'package:carepass/features/home/domain/repositories/home_repository.dart';
import 'package:carepass/features/home/domain/usecases/home_usecases.dart';
import 'package:carepass/features/home/presentation/bloc/home_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class HomeTestRepository extends Fake implements HomeRepository {
  Future<Either<Failure, List<HomeProviderItem>>> Function(String) providers =
      (_) async => const Right([]);
  @override
  Future<Either<Failure, UserSummary>> getUserSummary() async => const Right(
    UserSummary(
      id: 'u',
      fullName: 'Test',
      subscriptionStatus: SubscriptionStatus.none,
      selectedArea: 'Accra',
    ),
  );
  @override
  Future<Either<Failure, List<HomeBanner>>> getHomeBanners({
    required bool isSubscribed,
    String? area,
  }) async => const Right([]);
  @override
  Future<Either<Failure, HomeQuickStat>> getHomeQuickStats({
    required String userId,
    String? area,
  }) async => const Right(
    HomeQuickStat(
      nearbyProviders: 0,
      availableServices: 0,
      checkupsRemaining: 0,
    ),
  );
  @override
  Future<Either<Failure, List<HomeServiceItem>>> getPopularServices(
    String area,
  ) async => const Right([]);
  @override
  Future<Either<Failure, List<HomeProviderItem>>> getNearbyProviders(
    String area,
  ) => providers(area);
}

HomeBloc createBloc(HomeTestRepository repo) => HomeBloc(
  getUserSummary: GetUserSummary(repo),
  getHomeBanners: GetHomeBanners(repo),
  getHomeQuickStats: GetHomeQuickStats(repo),
  getPopularServices: GetPopularServices(repo),
  getNearbyProviders: GetNearbyProviders(repo),
);

void main() {
  test(
    'provider failure differs from an empty catalog and clears on successful retry',
    () async {
      final repo = HomeTestRepository()
        ..providers = (_) async => const Left(ServerFailure('denied'));
      final bloc = createBloc(repo);
      addTearDown(bloc.close);
      var loaded = bloc.stream.firstWhere((s) => s is HomeLoaded);
      bloc.add(HomeLoadRequested());
      expect((await loaded as HomeLoaded).hasProvidersError, isTrue);
      repo.providers = (_) async => const Right([]);
      loaded = bloc.stream.firstWhere((s) => s is HomeLoaded);
      bloc.add(HomeLoadRequested());
      expect((await loaded as HomeLoaded).hasProvidersError, isFalse);
    },
  );

  test(
    'a failed area change does not retain providers from the previous area',
    () async {
      final repo = HomeTestRepository()
        ..providers = (_) async => const Right([
          HomeProviderItem(
            id: 'a',
            name: 'Accra Clinic',
            type: 'clinic',
            phone: '',
            area: 'Accra',
          ),
        ]);
      final bloc = createBloc(repo);
      addTearDown(bloc.close);
      var loaded = bloc.stream.firstWhere((s) => s is HomeLoaded);
      bloc.add(HomeLoadRequested());
      expect((await loaded as HomeLoaded).providers, hasLength(1));
      repo.providers = (_) async => const Left(ServerFailure('denied'));
      loaded = bloc.stream.firstWhere(
        (s) => s is HomeLoaded && s.hasProvidersError,
      );
      bloc.add(HomeAreaChanged('Tema'));
      expect((await loaded as HomeLoaded).providers, isEmpty);
    },
  );
}
