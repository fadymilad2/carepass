import 'dart:async';
import 'package:carepass/core/errors/failures.dart';
import 'package:carepass/features/providers/domain/entities/provider_entities.dart';
import 'package:carepass/features/providers/domain/repositories/providers_repository.dart';
import 'package:carepass/features/providers/domain/usecases/providers_usecases.dart';
import 'package:carepass/features/providers/presentation/bloc/providers_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProviders extends Fake implements ProvidersRepository {
  final requests =
      <String, Completer<Either<Failure, List<MedicalProvider>>>>{};
  @override
  Future<Either<Failure, List<MedicalProvider>>> getProviders(
    ProvidersFilter filter,
  ) async {
    final query = filter.searchQuery ?? '';
    if (query.isEmpty) return const Right([]);
    final pending = Completer<Either<Failure, List<MedicalProvider>>>();
    requests[query] = pending;
    return pending.future;
  }
}

void main() {
  test('a late search cannot overwrite the latest query', () async {
    final repo = FakeProviders();
    final bloc = ProvidersBloc(
      getProviders: GetProviders(repo),
      getProviderById: GetProviderById(repo),
      searchProviders: SearchProviders(repo),
      toggleFavorite: ToggleFavorite(repo),
    );
    addTearDown(bloc.close);
    var ready = bloc.stream.firstWhere((s) => s is ProvidersLoaded);
    bloc.add(ProvidersLoadRequested(const ProvidersFilter()));
    await ready;
    ready = bloc.stream.firstWhere(
      (s) => s is ProvidersLoaded && s.filter.searchQuery == 'old',
    );
    bloc.add(ProvidersSearchChanged('old'));
    await ready;
    ready = bloc.stream.firstWhere(
      (s) => s is ProvidersLoaded && s.filter.searchQuery == 'new',
    );
    bloc.add(ProvidersSearchChanged('new'));
    await ready;
    repo.requests['new']!.complete(const Right([]));
    await Future<void>.delayed(Duration.zero);
    repo.requests['old']!.complete(const Right([]));
    await Future<void>.delayed(Duration.zero);
    expect((bloc.state as ProvidersLoaded).filter.searchQuery, 'new');
  });
}
