import 'package:carepass/features/account/presentation/bloc/account_bloc.dart';
import 'package:carepass/features/account/presentation/pages/account_page.dart';
import 'package:carepass/features/account/presentation/pages/notifications_page.dart';
import 'package:carepass/features/ai_assistant/presentation/bloc/ai_bloc.dart';
import 'package:carepass/features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import 'package:carepass/features/auth/presentation/pages/promo_page.dart';
import 'package:carepass/features/card/presentation/bloc/card_bloc.dart';
import 'package:carepass/features/card/presentation/pages/card_page.dart';
import 'package:carepass/features/card/presentation/pages/health_check_card_page.dart';
import 'package:carepass/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:carepass/features/payment/presentation/pages/family_members_page.dart';
import 'package:carepass/features/payment/presentation/pages/payment_page.dart';
import 'package:carepass/features/payment/presentation/pages/payment_success_page.dart';
import 'package:carepass/features/providers/domain/entities/provider_entities.dart';
import 'package:carepass/features/providers/presentation/bloc/providers_bloc.dart';
import 'package:carepass/features/providers/presentation/pages/book_now_page.dart';
import 'package:carepass/features/providers/presentation/pages/provider_detail_page.dart';
import 'package:carepass/features/providers/presentation/pages/providers_page.dart';
import 'package:carepass/features/services/presentation/bloc/services_bloc.dart';
import 'package:carepass/features/services/presentation/pages/services_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'shell_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../di/service_locator.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// ─────────────────────────────────────────────
//  Route Names
// ─────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String promo = '/promo';
  static const String login = '/login';
  static const String home = '/home';
  static const String services = '/services';
  static const String card = '/card';
  static const String bookNow = '/book-now';
  static const String providers = '/providers';
  static const String account = '/account';
  static const String healthCheck = '/health-check';
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment/success';
  static const String familyMembers = '/family-members';

  static const String aiAssistant = '/ai-assistant';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
}

// ─────────────────────────────────────────────
//  App Router
// ─────────────────────────────────────────────
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static AuthBloc? _authBloc;
  static AuthBloc get _sharedAuthBloc {
    if (_authBloc == null || _authBloc!.isClosed) {
      _authBloc = sl<AuthBloc>();
    }
    return _authBloc!;
  }

  static AuthBloc get sharedAuthBloc => _sharedAuthBloc;

  static HomeBloc? _homeBloc;
  static HomeBloc get _sharedHomeBloc {
    if (_homeBloc == null || _homeBloc!.isClosed) {
      _homeBloc = sl<HomeBloc>();
    }
    return _homeBloc!;
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,

    redirect: (context, state) {
      final isSignedIn = FirebaseAuth.instance.currentUser != null;
      final loc = state.uri.path;

      const protected = [
        AppRoutes.payment,
        AppRoutes.aiAssistant,
        AppRoutes.familyMembers,
        AppRoutes.healthCheck,
        AppRoutes.notifications,
      ];

      final isProtected = protected.any(
        (r) => (loc == r || loc.startsWith('$r/')),
      );
      if (!isSignedIn && isProtected) return AppRoutes.login;
      return null;
    },

    routes: [
      // ── Splash ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => BlocProvider.value(
          value: _sharedAuthBloc,
          child: const SplashPage(),
        ),
      ),

      GoRoute(path: AppRoutes.promo, builder: (_, _) => const PromoPage()),

      // ── Login ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => BlocProvider.value(
          value: _sharedAuthBloc,
          child: const LoginPage(),
        ),
      ),

      // ── Main Shell ───────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => BlocProvider.value(
              value: _sharedHomeBloc,
              child: const HomePage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.services,
            builder: (_, _) => BlocProvider(
              create: (_) => sl<ServicesBloc>(),
              child: const ServicesPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.card,
            builder: (_, _) => BlocProvider(
              create: (_) => sl<CardBloc>(),
              child: const CardPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.healthCheck,
            builder: (context, state) {
              final type = state.extra as String? ?? 'blood_pressure';
              return BlocProvider(
                create: (_) => sl<CardBloc>()..add(CardLoadRequested()),
                child: HealthCheckCardPage(type: type),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.providers,
            builder: (_, _) => BlocProvider(
              create: (_) => sl<ProvidersBloc>(),
              child: const ProvidersPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.account,
            builder: (context, _) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => sl<AccountBloc>()),
                BlocProvider.value(value: _sharedAuthBloc),
              ],
              child: const AccountPage(),
            ),
          ),
        ],
      ),

      // ── Full-screen routes ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.payment,
        builder: (_, _) => BlocProvider(
          create: (_) => sl<PaymentBloc>(),
          child: const PaymentPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        builder: (_, _) => const PaymentSuccessPage(),
      ),
      GoRoute(
        path: AppRoutes.bookNow,
        builder: (context, state) {
          final provider = state.extra;
          if (provider is! MedicalProvider) {
            return const _PlaceholderPage(title: 'Provider unavailable');
          }
          return BookNowPage(provider: provider);
        },
      ),
      GoRoute(
        path: AppRoutes.aiAssistant,
        builder: (_, _) => BlocProvider(
          create: (_) => sl<AiBloc>(),
          child: const AiAssistantPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.familyMembers,
        builder: (_, _) => const FamilyMembersPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/providers/detail',
        builder: (context, state) {
          final provider = state.extra;
          if (provider is! MedicalProvider) {
            return const _PlaceholderPage(title: 'Provider unavailable');
          }
          return ProviderDetailPage(provider: provider);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const _PlaceholderPage(title: 'Settings'),
      ),
    ],

    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
}

// ─────────────────────────────────────────────
//  Shell Scaffold ✅ With Back Button Fix
// ─────────────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
