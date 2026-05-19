import 'package:carepass/features/auth/data/datasources/auth_remote_datasource.dart';
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
import 'package:carepass/features/providers/data/datasources/providers_remote_datasource.dart';
import 'package:carepass/features/providers/data/repositories/providers_repository_impl.dart';
import 'package:carepass/features/providers/domain/repositories/providers_repository.dart';
import 'package:carepass/features/providers/domain/usecases/providers_usecases.dart';
import 'package:carepass/features/providers/presentation/bloc/providers_bloc.dart';
import 'package:carepass/features/services/data/datasources/services_remote_datasource.dart';
import 'package:carepass/features/services/data/repositories/services_repository_impl.dart';
import 'package:carepass/features/services/domain/repositories/services_repository.dart';
import 'package:carepass/features/services/domain/usecases/services_usecases.dart';
import 'package:carepass/features/services/presentation/bloc/services_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
// استدعي ملفات الـ Home اللي عملناها
 // مسار ملف الـ NetworkInfo لو عامله

final GetIt sl = GetIt.instance;

Future<void> setupDependencies() async {
  // ─── Core ─────────────────────────────────────────────────────────────
  _registerCore();

  // ─── Features ──────────────────────────────────────────────────────────
  _registerAuth();
  _registerHome();
  _registerServices();
  _registerCard();
  _registerProviders();
  _registerAccount();
  _registerPayment();
  _registerAiAssistant();
}

void _registerCore() {
  // تسجيل أدوات فايربيز الأساسية
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance); // ضفنا دي عشان الـ Auth

  // Network checker (فك الكومنت بتاعها لو عملت الكلاس بتاعها)
  // sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl()); 
}

void _registerHome() {
  // 1. Data Sources
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(
      firestore: sl(),
      auth: sl(), // دلوقتي GetIt هيعرف يجيب الـ FirebaseAuth ويبعتها هنا
    ),
  );

  // 2. Repository
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // 3. Use Cases
  sl.registerLazySingleton(() => GetUserSummary(sl()));
  sl.registerLazySingleton(() => GetHomeBanners(sl()));
  sl.registerLazySingleton(() => GetHomeQuickStats(sl()));

  // 4. Bloc
  sl.registerFactory(
    () => HomeBloc(
      getUserSummary: sl(),
      getHomeBanners: sl(),
      getHomeQuickStats: sl(),
    ),
  );
}

// ───────────────────────────────────────────────────────────────────────
// باقي الفيتشرز سيبها كومنت زي ما هي لحد ما نبنيها
// ───────────────────────────────────────────────────────────────────────
void _registerAuth() {
  sl.registerFactory(() => AuthBloc(
    signIn:             sl(),
    register:           sl(),
    getCurrentUser:     sl(),
    signOut:            sl(),
    sendPasswordReset:  sl(),
  ));

  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => Register(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => SendPasswordReset(sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      auth:      FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    ),
  );
}

void _registerServices() {
  sl.registerFactory(() => ServicesBloc(
    getServices:    sl(),
    searchServices: sl(),
  ));

  sl.registerLazySingleton(() => GetServices(sl()));
  sl.registerLazySingleton(() => SearchServices(sl()));

  sl.registerLazySingleton<ServicesRepository>(
    () => ServicesRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<ServicesRemoteDataSource>(
    () => ServicesRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
    ),
  );
}
void _registerCard() {
  sl.registerFactory(() => CardBloc(
    getCard:   sl(),
    renewCard: sl(),
  ));
  sl.registerLazySingleton(() => GetUserCard(sl()));
  sl.registerLazySingleton(() => RenewCard(sl()));
  sl.registerLazySingleton<CardRepository>(
    () => CardRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CardRemoteDataSource>(
    () => CardRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
      auth:      FirebaseAuth.instance,
    ),
  );
}
void _registerProviders() {
  sl.registerFactory(() => ProvidersBloc(
    getProviders:    sl(),
    getProviderById: sl(),
    searchProviders: sl(),
    toggleFavorite:  sl(),
  ));

  sl.registerLazySingleton(() => GetProviders(sl()));
  sl.registerLazySingleton(() => GetProviderById(sl()));
  sl.registerLazySingleton(() => SearchProviders(sl()));
  sl.registerLazySingleton(() => ToggleFavorite(sl()));

  sl.registerLazySingleton<ProvidersRepository>(
    () => ProvidersRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<ProvidersRemoteDataSource>(
    () => ProvidersRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
    ),
  );
}
void _registerAccount() {}
void _registerPayment() {}
void _registerAiAssistant() {}