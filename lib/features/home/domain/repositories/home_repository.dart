import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/home_entities.dart';

abstract class HomeRepository {
  /// Get current logged-in user summary
  Future<Either<Failure, UserSummary>> getUserSummary();

  /// Get home banners
  /// - If subscribed → provider banners + promotional
  /// - If not subscribed → general onboarding banners
  Future<Either<Failure, List<HomeBanner>>> getHomeBanners({
    required bool isSubscribed,
    String? area,
  });

  /// Get quick stats for the home screen
  Future<Either<Failure, HomeQuickStat>> getHomeQuickStats({
    required String userId,
    String? area,
  });
  // ... جوه الـ abstract class HomeRepository
  Future<Either<Failure, List<HomeServiceItem>>> getPopularServices(
    String area,
  );
  Future<Either<Failure, List<HomeProviderItem>>> getNearbyProviders(
    String area,
  );
}
