import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) context.read<AuthBloc>().add(AuthCheckRequested());
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated)   context.go(AppRoutes.home);
        if (state is AuthUnauthenticated) context.go(AppRoutes.promo);
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 20),
                  Text('CarePass',
                      style: AppTextStyles.displayMedium
                          .copyWith(color: Colors.white, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text('Quality Care for Less',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}