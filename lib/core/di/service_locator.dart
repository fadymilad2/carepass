import 'package:carepass/features/account/data/datasources/account_remote_datasource.dart';
import 'package:carepass/features/account/data/repositories/account_repository_impl.dart';
import 'package:carepass/features/account/domain/repositories/account_repository.dart';
import 'package:carepass/features/account/domain/usecases/account_usecases.dart';
import 'package:carepass/features/account/presentation/bloc/account_bloc.dart';
import 'package:carepass/features/ai_assistant/data/datasources/ai_remote_datasource.dart';
import 'package:carepass/features/ai_assistant/data/repositories/ai_repository_impl.dart';
import 'package:carepass/features/ai_assistant/domain/repositories/ai_repository.dart';
import 'package:carepass/features/ai_assistant/domain/usecases/ai_usecases.dart';
import 'package:carepass/features/ai_assistant/presentation/bloc/ai_bloc.dart';
import 'package:carepass/features/auth/data/datasources/auth_datasource.dart';
import 'package:carepass/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:carepass/features/auth/domain/repositories/auth_repository.dart';
import 'package:carepass/features/auth/domain/usecases/auth_usecases.dart';
import 'package:carepass/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carepass/features/card/data/datasources/card_remote_datasource.dart';
import 'package:carepass/features/card/data/repositories/card_repository_impl.dart';
import 'package:carepass/features/card/domain/repositories/card_repository.dart';
import 'package:carepass/features/card/domain/usecases/card_usecases.dart';
import 'package:carepass/features/card/presentation/bloc/card_bloc.dart';
import 'package:carepass/features/home/data/datasources/home_remote_datasource.dart';
import 'package:carepass/features/home/data/repositories/home_repository_impl.dart';
import 'package:carepass/features/home/domain/repositories/home_repository.dart';
import 'package:carepass/features/home/domain/usecases/home_usecases.dart';
import 'package:carepass/features/home/presentation/bloc/home_bloc.dart';
import 'package:carepass/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:carepass/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:carepass/features/payment/domain/repositories/payment_repository.dart';
import 'package:carepass/features/payment/domain/usecases/payment_usecases.dart';
import 'package:carepass/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:carepass/features/providers/data/datasources/providers_remote_datasource.dart';
import 'package:carepass/features/providers/data/repositories/providers_repository_impl.dart';
import 'package:carepass/features/providers/domain/repositories/providers_repository.dart';
import 'package:carepass/features/providers/domain/usecases/providers_usecases.dart';
import 'package:carepass/features/providers/presentation/bloc/providers_bloc.dart';
import 'package:carepass/features/services/data/datasources/services_remote_datasource.dart';
import 'package:carepass/features/services/data/repositories/services_repository_impl.dart';
import 'package:carepass/features/services/domain/repositories/services_repository.dart';
import 'package:carepass/features/services/domain/usecases/get_services.dart';
import 'package:carepass/features/services/presentation/bloc/services_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

Future<void> setupDependencies() async {
  _registerCore();
  _registerAuth();
  _registerHome();
  _registerServices();
  _registerCard();
  _registerProviders();
  _registerAccount();
  _registerPayment();
  _registerAiAssistant();
}

// ── Core ───────────────────────────────────────────────────────────────
void _registerCore() {
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
}

// ── Auth ───────────────────────────────────────────────────────────────
void _registerAuth() {
  sl.registerLazySingleton<AuthDataSource>(
    () => AuthDataSourceImpl(auth: sl(), db: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => SendOtp(sl()));
  sl.registerLazySingleton(() => VerifyOtp(sl()));
  sl.registerLazySingleton(() => CreateProfile(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));

  sl.registerFactory(
    () => AuthBloc(
      sendOtp: sl(),
      verifyOtp: sl(),
      createProfile: sl(),
      getCurrentUser: sl(),
      signOut: sl(),
    ),
  );
}

// ── Home ───────────────────────────────────────────────────────────────
void _registerHome() {
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(firestore: sl(), auth: sl()),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetUserSummary(sl()));
  sl.registerLazySingleton(() => GetHomeBanners(sl()));
  sl.registerLazySingleton(() => GetHomeQuickStats(sl()));
  sl.registerLazySingleton(() => GetPopularServices(sl()));
  sl.registerLazySingleton(() => GetNearbyProviders(sl()));

  sl.registerFactory(
    () => HomeBloc(
      getUserSummary: sl(),
      getHomeBanners: sl(),
      getPopularServices: sl(),
      getNearbyProviders: sl(),
      getHomeQuickStats: sl(),
    ),
  );
}

// ── Services ───────────────────────────────────────────────────────────
void _registerServices() {
  sl.registerLazySingleton<ServicesRemoteDataSource>(
    () => ServicesRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ServicesRepository>(
    () => ServicesRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetServicesByProvider(sl()));
  sl.registerLazySingleton(() => GetAllServices(sl()));

  sl.registerFactory(() => ServicesBloc(getByProvider: sl(), getAll: sl()));
}

// ── Card ───────────────────────────────────────────────────────────────
void _registerCard() {
  sl.registerLazySingleton<CardRemoteDataSource>(
    () => CardRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    ),
  );
  sl.registerLazySingleton<CardRepository>(() => CardRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetUserCard(sl()));
  sl.registerLazySingleton(() => RenewCard(sl()));

  sl.registerFactory(
    () => CardBloc(getCard: sl(), renewCard: sl(), auth: sl()),
  );
}

// ── Providers ──────────────────────────────────────────────────────────
void _registerProviders() {
  sl.registerLazySingleton<ProvidersRemoteDataSource>(
    () => ProvidersRemoteDataSourceImpl(firestore: FirebaseFirestore.instance),
  );
  sl.registerLazySingleton<ProvidersRepository>(
    () => ProvidersRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetProviders(sl()));
  sl.registerLazySingleton(() => GetProviderById(sl()));
  sl.registerLazySingleton(() => SearchProviders(sl()));
  sl.registerLazySingleton(() => ToggleFavorite(sl()));

  sl.registerFactory(
    () => ProvidersBloc(
      getProviders: sl(),
      getProviderById: sl(),
      searchProviders: sl(),
      toggleFavorite: sl(),
    ),
  );
}

// ── Account ────────────────────────────────────────────────────────────
void _registerAccount() {
  sl.registerLazySingleton<AccountRemoteDataSource>(
    () => AccountRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
      functions: FirebaseFunctions.instance,
    ),
  );
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetAccountUser(sl()));
  sl.registerLazySingleton(() => UpdateUsername(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl())); // ✅ New
  sl.registerLazySingleton(() => AccountSignOut(sl()));
  sl.registerLazySingleton(() => DeleteAccount(sl()));

  sl.registerFactory(
    () => AccountBloc(
      getUser: sl(),
      updateUsername: sl(),
      updateProfile: sl(), // ✅ New
      signOut: sl(),
      deleteAccount: sl(),
    ),
  );
}

// ── Payment ────────────────────────────────────────────────────────────
void _registerPayment() {
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
      functions: FirebaseFunctions.instance,
    ),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetPlans(sl()));
  sl.registerLazySingleton(() => InitializePayment(sl()));
  sl.registerLazySingleton(() => VerifyPayment(sl()));

  sl.registerFactory(() => PaymentBloc(dataSource: sl()));
}

// ── AI Assistant ───────────────────────────────────────────────────────
void _registerAiAssistant() {
  sl.registerLazySingleton<AiRemoteDataSource>(
    () => AiRemoteDataSourceImpl(functions: FirebaseFunctions.instance),
  );
  sl.registerLazySingleton<AiAssistantRepository>(
    () => AiAssistantRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => AnalyzeSymptoms(sl()));

  sl.registerFactory(() => AiBloc(analyze: sl()));
}
