import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/provider_entities.dart';

abstract class ProvidersRepository {
  Future<Either<Failure, List<MedicalProvider>>> getProviders(
    ProvidersFilter filter,
  );

  Future<Either<Failure, MedicalProvider>> getProviderById(String id);

  Future<Either<Failure, List<MedicalProvider>>> searchProviders({
    required String query,
    String? area,
  });

  Future<Either<Failure, void>> toggleFavorite(String providerId);
}