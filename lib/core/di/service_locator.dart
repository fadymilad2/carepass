import 'package:get_it/get_it.dart';

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
  // Network checker, local storage, etc.
  // sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  // sl.registerLazySingleton<LocalStorage>(() => LocalStorageImpl());
}

void _registerAuth() {
  // Bloc
  // sl.registerFactory(() => AuthBloc(signIn: sl(), signOut: sl(), getUser: sl()));

  // Use Cases
  // sl.registerLazySingleton(() => SignInWithPhone(sl()));
  // sl.registerLazySingleton(() => VerifyOtp(sl()));
  // sl.registerLazySingleton(() => SignOut(sl()));
  // sl.registerLazySingleton(() => GetCurrentUser(sl()));

  // Repository
  // sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()));

  // Data Sources
  // sl.registerLazySingleton<AuthRemoteDataSource>(
  //   () => AuthRemoteDataSourceImpl(FirebaseAuth.instance),
  // );
  // sl.registerLazySingleton<AuthLocalDataSource>(
  //   () => AuthLocalDataSourceImpl(sl()),
  // );
}

void _registerHome() {
  // sl.registerFactory(() => HomeBloc(getUser: sl(), getNearbyProviders: sl()));
}

void _registerServices() {
  // sl.registerFactory(() => ServicesBloc(getServices: sl()));
  // sl.registerLazySingleton(() => GetServices(sl()));
  // sl.registerLazySingleton<ServicesRepository>(
  //   () => ServicesRepositoryImpl(sl()),
  // );
  // sl.registerLazySingleton<ServicesRemoteDataSource>(
  //   () => ServicesRemoteDataSourceImpl(FirebaseFirestore.instance),
  // );
}

void _registerCard() {
  // sl.registerFactory(() => CardBloc(getCard: sl()));
  // sl.registerLazySingleton(() => GetUserCard(sl()));
  // sl.registerLazySingleton<CardRepository>(
  //   () => CardRepositoryImpl(sl()),
  // );
  // sl.registerLazySingleton<CardRemoteDataSource>(
  //   () => CardRemoteDataSourceImpl(FirebaseFirestore.instance),
  // );
}

void _registerProviders() {
  // sl.registerFactory(() => ProvidersBloc(getProviders: sl(), searchProviders: sl()));
  // sl.registerLazySingleton(() => GetProviders(sl()));
  // sl.registerLazySingleton(() => SearchProviders(sl()));
  // sl.registerLazySingleton<ProvidersRepository>(
  //   () => ProvidersRepositoryImpl(sl()),
  // );
  // sl.registerLazySingleton<ProvidersRemoteDataSource>(
  //   () => ProvidersRemoteDataSourceImpl(FirebaseFirestore.instance),
  // );
}

void _registerAccount() {
  // sl.registerFactory(() => AccountBloc(updateProfile: sl(), getPaymentHistory: sl()));
}

void _registerPayment() {
  // sl.registerFactory(() => PaymentBloc(createPayment: sl(), verifyPayment: sl()));
  // sl.registerLazySingleton(() => CreateMomoPayment(sl()));
  // sl.registerLazySingleton(() => VerifyMomoPayment(sl()));
  // sl.registerLazySingleton<PaymentRepository>(
  //   () => PaymentRepositoryImpl(sl()),
  // );
  // sl.registerLazySingleton<PaymentRemoteDataSource>(
  //   () => PaymentRemoteDataSourceImpl(FirebaseFunctions.instance),
  // );
}

void _registerAiAssistant() {
  // sl.registerFactory(() => AiAssistantBloc(analyzeSymptoms: sl()));
  // sl.registerLazySingleton(() => AnalyzeSymptoms(sl()));
  // sl.registerLazySingleton<AiAssistantRepository>(
  //   () => AiAssistantRepositoryImpl(sl()),
  // );
  // sl.registerLazySingleton<AiAssistantRemoteDataSource>(
  //   () => AiAssistantRemoteDataSourceImpl(FirebaseFunctions.instance),
  // );
}