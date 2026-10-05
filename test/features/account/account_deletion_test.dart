import 'dart:async';
import 'package:carepass/core/errors/failures.dart';
import 'package:carepass/features/account/domain/entities/account_entities.dart';
import 'package:carepass/features/account/domain/repositories/account_repository.dart';
import 'package:carepass/features/account/domain/usecases/account_usecases.dart';
import 'package:carepass/features/account/presentation/bloc/account_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

const user = AccountUser(
  id: 'alice',
  username: 'Alice',
  phoneNumber: '',
  email: '',
  subscriptionStatus: 'none',
);

class FakeAccount extends Fake implements AccountRepository {
  int calls = 0;
  Completer<Either<Failure, void>> deletion = Completer();
  @override
  Future<Either<Failure, AccountUser>> getAccountUser() async =>
      const Right(user);
  @override
  Future<Either<Failure, void>> deleteAccount() {
    calls++;
    return deletion.future;
  }
}

void main() {
  Future<AccountBloc> loaded(FakeAccount repo) async {
    final bloc = AccountBloc(
      getUser: GetAccountUser(repo),
      updateUsername: UpdateUsername(repo),
      updateProfile: UpdateProfile(repo),
      signOut: AccountSignOut(repo),
      deleteAccount: DeleteAccount(repo),
    );
    addTearDown(bloc.close);
    final ready = bloc.stream.firstWhere((state) => state is AccountLoaded);
    bloc.add(AccountLoadRequested());
    await ready;
    return bloc;
  }

  test('waits for confirmed deletion and ignores duplicate taps', () async {
    final repo = FakeAccount();
    final bloc = await loaded(repo);
    final busy = bloc.stream.firstWhere((state) => state is AccountLoading);
    bloc.add(AccountDeleteRequested());
    await busy;
    bloc.add(AccountDeleteRequested());
    await Future<void>.delayed(Duration.zero);
    expect(repo.calls, 1);
    expect(bloc.state, isA<AccountLoading>());
    final deleted = bloc.stream.firstWhere((state) => state is AccountDeleted);
    repo.deletion.complete(const Right(null));
    await deleted;
    // The same shared bloc remains usable after a new sign-in.
    final ready = bloc.stream.firstWhere((state) => state is AccountLoaded);
    bloc.add(AccountLoadRequested());
    await ready;
  });

  test(
    'failure preserves account screen and allows retry without false success',
    () async {
      final repo = FakeAccount();
      final bloc = await loaded(repo);
      final failed = bloc.stream.firstWhere(
        (state) => state is AccountDeletionFailed,
      );
      bloc.add(AccountDeleteRequested());
      repo.deletion.complete(
        const Left(ServerFailure('Please sign in again.')),
      );
      await failed;
      expect((bloc.state as AccountDeletionFailed).user, user);
      repo.deletion = Completer();
      final deleted = bloc.stream.firstWhere(
        (state) => state is AccountDeleted,
      );
      bloc.add(AccountDeleteRequested());
      repo.deletion.complete(const Right(null));
      await deleted;
      expect(repo.calls, 2);
    },
  );
}
