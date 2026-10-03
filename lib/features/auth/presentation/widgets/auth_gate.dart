import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

/// Wraps any widget that requires authentication
/// لما المستخدم يحاول يدخل صفحة محتاج login
/// هيظهرله prompt بدل الصفحة
class AuthGate extends StatefulWidget {
  final Widget child;
  final String? message;

  const AuthGate({super.key, required this.child, this.message});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // ✅ New — ensures we only trigger the self-heal check once per
  // mount, not on every rebuild (e.g. every time the Bloc emits a
  // new state while this widget is active).
  bool _hasSelfHealed = false;

  @override
  void initState() {
    super.initState();
    _selfHealIfNeeded();
  }

  // ✅ New — the actual fix. AuthGate no longer blindly trusts
  // whatever state happens to be current the instant it's built.
  // If, right when this widget mounts, the Bloc's state isn't
  // AuthAuthenticated, we proactively re-dispatch AuthCheckRequested
  // — the exact same event the app's Splash screen fires on a cold
  // start. AuthCheckRequested reads Firebase Auth's real current
  // user directly, so this re-sync happens almost instantly and
  // corrects any stale/transient state left over from a route
  // rebuild that raced with the last emission from the login flow.
  // This is what previously only happened by restarting the whole
  // app, or by any other rebuild that happened to occur after the
  // state had settled (what felt like needing to "Try Again").
  void _selfHealIfNeeded() {
    if (_hasSelfHealed) return;
    final bloc = context.read<AuthBloc>();
    if (bloc.state is! AuthAuthenticated) {
      _hasSelfHealed = true;
      bloc.add(AuthCheckRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) return widget.child;

        // ✅ Fixed — AuthUnauthenticated is now treated the same as
        // Loading/Initial for a brief moment right after mount,
        // since _selfHealIfNeeded() above may have just dispatched
        // a fresh check that hasn't resolved yet. Once that check
        // resolves to a real "not signed in", the Bloc's own
        // AuthCheckRequested handler emits AuthUnauthenticated
        // again — at which point _hasSelfHealed is already true,
        // so we don't loop, and this correctly falls through to
        // showing the sign-in prompt below on the next build.
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        return _LoginPromptPage(message: widget.message);
      },
    );
  }
}

class _LoginPromptPage extends StatelessWidget {
  final String? message;
  const _LoginPromptPage({this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.cardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Colors.white,
                  size: 50,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Sign in Required',
                style: AppTextStyles.headlineLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                message ??
                    'Sign in to access your CarePass\nhealthcare benefits.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.login),
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text(
                    'Sign in with Phone',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(
                  'Continue without signing in',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
