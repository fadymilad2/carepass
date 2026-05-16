import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/home_entities.dart';
import '../repositories/home_repository.dart';

// ─────────────────────────────────────────────
//  Use Case: Get User Summary
// ─────────────────────────────────────────────
class GetUserSummary {
  final HomeRepository repository;
  GetUserSummary(this.repository);

  Future<Either<Failure, UserSummary>> call() {
    return repository.getUserSummary();
  }
}

// ─────────────────────────────────────────────
//  Use Case: Get Home Banners
// ─────────────────────────────────────────────
class GetHomeBanners {
  final HomeRepository repository;
  GetHomeBanners(this.repository);

  Future<Either<Failure, List<HomeBanner>>> call({
    required bool isSubscribed,
    String? area,
  }) {
    return repository.getHomeBanners(isSubscribed: isSubscribed, area: area);
  }
}

// ─────────────────────────────────────────────
//  Use Case: Get Quick Stats
// ─────────────────────────────────────────────
class GetHomeQuickStats {
  final HomeRepository repository;
  GetHomeQuickStats(this.repository);

  Future<Either<Failure, HomeQuickStat>> call({
    required String userId,
    String? area,
  }) {
    return repository.getHomeQuickStats(userId: userId, area: area);
  }
}
