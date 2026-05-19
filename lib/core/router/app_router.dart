import 'package:carepass/features/account/presentation/bloc/account_bloc.dart';
import 'package:carepass/features/account/presentation/pages/account_page.dart';
import 'package:carepass/features/auth/presentation/pages/promo_page.dart';
import 'package:carepass/features/card/presentation/bloc/card_bloc.dart';
import 'package:carepass/features/card/presentation/pages/card_page.dart';
import 'package:carepass/features/providers/domain/entities/provider_entities.dart';
import 'package:carepass/features/providers/presentation/bloc/providers_bloc.dart';
import 'package:carepass/features/providers/presentation/pages/provider_detail_page.dart';
import 'package:carepass/features/providers/presentation/pages/providers_page.dart';
import 'package:carepass/features/services/presentation/bloc/services_bloc.dart';
import 'package:carepass/features/services/presentation/pages/services_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../di/service_locator.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// ─────────────────────────────────────────────
//  Route Names
// ─────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String promo = '/promo';
  static const String login = '/login';
  static const String verifyOtp = '/verify-otp';
  static const String register = '/register';

  static const String home = '/home';
  static const String services = '/services';
  static const String card = '/card';
  static const String providers = '/providers';
  static const String account = '/account';

  static const String payment = '/payment';
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

  // AuthBloc instance واحدة بتتشارك بين Splash → Login → OTP → Register
  static AuthBloc? _authBloc;
  static AuthBloc get _sharedAuthBloc {
    if (_authBloc == null || _authBloc!.isClosed) {
      _authBloc = sl<AuthBloc>();
    }
    return _authBloc!;
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,

    routes: [
      // ── Splash ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => BlocProvider.value(
          value: _sharedAuthBloc..add(AuthCheckRequested()),
          child: const SplashPage(),
        ),
      ),

      GoRoute(path: AppRoutes.promo, builder: (_, _) => const PromoPage()),

      // ── Login ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => BlocProvider.value(
          value: _sharedAuthBloc,
          child: const LoginPage(),
        ),
      ),

      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => BlocProvider.value(
          value: _sharedAuthBloc,
          child: const RegisterPage(), // ← مش محتاج extra params دلوقتي
        ),
      ),

      // ── Main Shell (Bottom Nav) ───────────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => BlocProvider(
              create: (_) => sl<HomeBloc>(),
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
            builder: (_, __) => BlocProvider(
              create: (_) => sl<CardBloc>(),
              child: const CardPage(),
            ),
          ),

          GoRoute(
            path: AppRoutes.providers,
            builder: (_, __) => BlocProvider(
              create: (_) => sl<ProvidersBloc>(),
              child: const ProvidersPage(),
            ),
          ),

          GoRoute(
            path: AppRoutes.account,
            builder: (context, __) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => sl<AccountBloc>()),
                BlocProvider.value(value: _sharedAuthBloc),
              ],
              child: const AccountPage(),
            ),
          ),
        ],
      ),

      // ── Full-screen routes (outside shell) ───────────────────────────────
      GoRoute(
        path: AppRoutes.payment,
        builder: (_, _) => const _PlaceholderPage(title: 'Payment'),
      ),

      GoRoute(
        path: AppRoutes.aiAssistant,
        builder: (_, _) => const _PlaceholderPage(title: 'AI Assistant'),
      ),

      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const _PlaceholderPage(title: 'Notifications'),
      ),
      GoRoute(
        path: '/providers/detail',
        builder: (context, state) {
          final provider = state.extra as MedicalProvider;
          return ProviderDetailPage(provider: provider);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const _PlaceholderPage(title: 'Settings'),
      ),
    ],

    // ── Error Page ────────────────────────────────────────────────────────
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
}

// ─────────────────────────────────────────────
//  Shell Scaffold
// ─────────────────────────────────────────────
class _ShellScaffold extends StatelessWidget {
  final Widget child;
  const _ShellScaffold({required this.child});

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith(AppRoutes.services)) return 1;
    if (loc.startsWith(AppRoutes.card)) return 2;
    if (loc.startsWith(AppRoutes.providers)) return 3;
    if (loc.startsWith(AppRoutes.account)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex(context),
        onTap: (i) {
          final routes = [
            AppRoutes.home,
            AppRoutes.services,
            AppRoutes.card,
            AppRoutes.providers,
            AppRoutes.account,
          ];
          context.go(routes[i]);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined),
            activeIcon: Icon(Icons.credit_card),
            label: 'Card',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Providers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Placeholder
// ─────────────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: const TextStyle(fontSize: 24))),
    );
  }
}
