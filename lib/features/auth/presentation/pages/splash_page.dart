import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  bool _isAnimationDone = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));

    context.read<AuthBloc>().add(AuthCheckRequested());

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _isAnimationDone = true;
        _checkAndNavigate(context.read<AuthBloc>().state);
      }
    });
  }

  void _checkAndNavigate(AuthState state) {
    if (!_isAnimationDone) return;

    if (state is AuthNeedsProfile) {
      context.go(AppRoutes.login);
      return;
    }

    if (state is AuthAuthenticated) {
      context.go(AppRoutes.home);
    }
    // ✅ Fixed — was `context.go(AppRoutes.promo)`. Guests should
    // land directly on Home and be able to browse providers,
    // services, and discounts freely. Sign-in / OTP is now only
    // ever triggered from AuthGate (e.g. when tapping the Card
    // tab) or an explicit "Sign in" action — never forced at
    // app launch. AppRoutes.promo is left defined and untouched
    // in case it's still useful elsewhere (e.g. a "Learn More"
    // entry point), it's just no longer the automatic landing
    // spot for unauthenticated users.
    if (state is AuthUnauthenticated) {
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _checkAndNavigate(state),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Image.asset(
                'assets/images/logo.png',
                width: 220,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
