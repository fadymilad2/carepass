import 'core/notifications/notification_service.dart';
import 'package:carepass/core/constants/app_constants.dart';
import 'package:carepass/core/theme/app_theme.dart';
import 'package:carepass/features/card/presentation/bloc/card_bloc.dart';
import 'package:carepass/features/home/presentation/bloc/home_bloc.dart';
import 'package:carepass/features/services/presentation/bloc/services_bloc.dart';
import 'package:carepass/features/providers/presentation/bloc/providers_bloc.dart';
import 'package:carepass/features/account/presentation/bloc/account_bloc.dart';
import 'package:carepass/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/di/service_locator.dart';

// ✅ مفتاح جلوبال عشان نظهر الـ SnackBar من غير ما نعتمد على الـ Context بتاع الشاشة
final GlobalKey<ScaffoldMessengerState> globalMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// ─────────────────────────────────────────────
//  main()
// ─────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Background handler
  FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

  // ✅ Local notifications init + channel creation
  await initializeLocalNotifications();

  await setupDependencies();

  runApp(const CarePassApp());
}

// ─────────────────────────────────────────────
//  App Widget
// ─────────────────────────────────────────────
class CarePassApp extends StatefulWidget {
  const CarePassApp({super.key});

  @override
  State<CarePassApp> createState() => _CarePassAppState();
}

class _CarePassAppState extends State<CarePassApp> {
  final _notifications = NotificationService();
  @override
  void initState() {
    super.initState();
    _notifications.start();
  }

  @override
  void dispose() {
    _notifications.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: AppRouter.sharedAuthBloc),
        BlocProvider(create: (_) => sl<HomeBloc>()),
        BlocProvider(create: (_) => sl<ServicesBloc>()),
        BlocProvider(create: (_) => sl<CardBloc>()),
        BlocProvider(create: (_) => sl<ProvidersBloc>()),
        BlocProvider(create: (_) => sl<AccountBloc>()),
        BlocProvider(create: (_) => sl<PaymentBloc>()),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        scaffoldMessengerKey: globalMessengerKey,
      ),
    );
  }
}
