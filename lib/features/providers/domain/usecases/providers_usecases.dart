import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/provider_entities.dart';
import '../repositories/providers_repository.dart';

class GetProviders {
  final ProvidersRepository repo;
  GetProviders(this.repo);
  Future<Either<Failure, List<MedicalProvider>>> call(ProvidersFilter filter) =>
      repo.getProviders(filter);
}

class GetProviderById {
  final ProvidersRepository repo;
  GetProviderById(this.repo);
  Future<Either<Failure, MedicalProvider>> call(String id) =>
      repo.getProviderById(id);
}

class SearchProviders {
  final ProvidersRepository repo;
  SearchProviders(this.repo);
  Future<Either<Failure, List<MedicalProvider>>> call({
    required String query,
    String? area,
  }) => repo.searchProviders(query: query, area: area);
}

class ToggleFavorite {
  final ProvidersRepository repo;
  ToggleFavorite(this.repo);
  Future<Either<Failure, void>> call(String id) => repo.toggleFavorite(id);
}
