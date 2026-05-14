import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─── Import Pages (uncomment as you build them) ──
// import '../features/auth/presentation/pages/splash_page.dart';
// import '../features/auth/presentation/pages/onboarding_page.dart';
// import '../features/auth/presentation/pages/login_page.dart';
// import '../features/auth/presentation/pages/verify_otp_page.dart';
// import '../features/auth/presentation/pages/register_page.dart';
// import '../features/home/presentation/pages/home_page.dart';
// import '../features/services/presentation/pages/services_page.dart';
// import '../features/card/presentation/pages/card_page.dart';
// import '../features/providers/presentation/pages/providers_page.dart';
// import '../features/providers/presentation/pages/provider_detail_page.dart';
// import '../features/account/presentation/pages/account_page.dart';
// import '../features/payment/presentation/pages/payment_page.dart';
// import '../features/payment/presentation/pages/payment_success_page.dart';
// import '../features/ai_assistant/presentation/pages/ai_assistant_page.dart';
// import 'shell_scaffold.dart';

// ─────────────────────────────────────────────
//  Route Names
// ─────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String splash          = '/';
  static const String onboarding      = '/onboarding';
  static const String login           = '/login';
  static const String verifyOtp       = '/verify-otp';
  static const String register        = '/register';
  static const String selectArea      = '/select-area';

  // Main Shell
  static const String home            = '/home';
  static const String services        = '/services';
  static const String card            = '/card';
  static const String providers       = '/providers';
  static const String account         = '/account';

  // Sub-routes
  static const String providerDetail  = '/providers/detail';
  static const String serviceDetail   = '/services/detail';
  static const String payment         = '/payment';
  static const String paymentSuccess  = '/payment/success';
  static const String paymentHistory  = '/account/payments';
  static const String editProfile     = '/account/edit';
  static const String aiAssistant     = '/ai-assistant';
  static const String notifications   = '/notifications';
  static const String settings        = '/settings';
}

// ─────────────────────────────────────────────
//  App Router
// ─────────────────────────────────────────────
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,

    // ── Redirect logic (auth guard) ──────────────
    redirect: (context, state) {
      // TODO: inject AuthBloc/Cubit and check auth state
      // final isLoggedIn = context.read<AuthBloc>().state is AuthAuthenticated;
      // final isOnboarded = SharedPrefs.getBool(AppConstants.keyOnboarding);
      // if (!isOnboarded && state.fullPath != AppRoutes.onboarding) {
      //   return AppRoutes.onboarding;
      // }
      // if (!isLoggedIn && !_publicRoutes.contains(state.fullPath)) {
      //   return AppRoutes.login;
      // }
      return null;
    },

    routes: [
      // ── Splash ──────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _PlaceholderPage(title: 'Splash'),
      ),

      // ── Onboarding ───────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const _PlaceholderPage(title: 'Onboarding'),
      ),

      // ── Auth Routes ──────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const _PlaceholderPage(title: 'Login'),
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        builder: (context, state) => const _PlaceholderPage(title: 'Verify OTP'),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const _PlaceholderPage(title: 'Register'),
      ),
      GoRoute(
        path: AppRoutes.selectArea,
        builder: (context, state) => const _PlaceholderPage(title: 'Select Area'),
      ),

      // ── Main Shell (Bottom Nav) ───────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _ShellScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const _PlaceholderPage(title: 'Home'),
          ),
          GoRoute(
            path: AppRoutes.services,
            builder: (context, state) => const _PlaceholderPage(title: 'Services'),
            routes: [
              GoRoute(
                path: 'detail',
                builder: (context, state) =>
                    const _PlaceholderPage(title: 'Service Detail'),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.card,
            builder: (context, state) => const _PlaceholderPage(title: 'My Card'),
          ),
          GoRoute(
            path: AppRoutes.providers,
            builder: (context, state) => const _PlaceholderPage(title: 'Providers'),
            routes: [
              GoRoute(
                path: 'detail',
                builder: (context, state) =>
                    const _PlaceholderPage(title: 'Provider Detail'),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.account,
            builder: (context, state) => const _PlaceholderPage(title: 'Account'),
            routes: [
              GoRoute(
                path: 'payments',
                builder: (context, state) =>
                    const _PlaceholderPage(title: 'Payment History'),
              ),
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    const _PlaceholderPage(title: 'Edit Profile'),
              ),
            ],
          ),
        ],
      ),

      // ── Full-screen routes (outside shell) ───────
      GoRoute(
        path: AppRoutes.payment,
        builder: (context, state) => const _PlaceholderPage(title: 'Payment'),
        routes: [
          GoRoute(
            path: 'success',
            builder: (context, state) =>
                const _PlaceholderPage(title: 'Payment Success'),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.aiAssistant,
        builder: (context, state) => const _PlaceholderPage(title: 'AI Assistant'),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const _PlaceholderPage(title: 'Notifications'),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const _PlaceholderPage(title: 'Settings'),
      ),
    ],

    // ── Error Page ────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}

// ─────────────────────────────────────────────
//  Shell Scaffold (Bottom Nav)
//  → Will be replaced with full implementation
// ─────────────────────────────────────────────
class _ShellScaffold extends StatelessWidget {
  final Widget child;
  const _ShellScaffold({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.services))  return 1;
    if (location.startsWith(AppRoutes.card))      return 2;
    if (location.startsWith(AppRoutes.providers)) return 3;
    if (location.startsWith(AppRoutes.account))   return 4;
    return 0; // Default to Home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (i) {
          final routes = [
            AppRoutes.home, AppRoutes.services, AppRoutes.card,
            AppRoutes.providers, AppRoutes.account,
          ];
          context.go(routes[i]);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),   activeIcon: Icon(Icons.home),         label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card_outlined), activeIcon: Icon(Icons.credit_card), label: 'Card'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on), label: 'Providers'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline),  activeIcon: Icon(Icons.person),       label: 'Account'),
        ],
      ),
    );
  }
}

// Temporary placeholder — delete when real pages are built
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