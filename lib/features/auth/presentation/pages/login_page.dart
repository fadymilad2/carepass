import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passwordCtrl= TextEditingController();
  bool _obscure      = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthSignInRequested(
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) context.go(AppRoutes.home);
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingLG),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Logo
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          color: Colors.white, size: 30),
                    ),

                    const SizedBox(height: 32),
                    Text('Welcome back', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 8),
                    Text('Sign in to your CarePass account',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),

                    const SizedBox(height: 40),

                    // Email
                    Text('Email', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Password
                    Text('Password', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showForgotPassword(context),
                        child: Text('Forgot Password?',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: AppColors.primary)),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Sign In button
                    ElevatedButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Sign In'),
                    ),

                    const SizedBox(height: 24),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ",
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.register),
                          child: Text('Sign Up',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(AppDimens.paddingLG),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reset Password',
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 8),
                Text('Enter your email and we\'ll send a reset link.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                BlocConsumer<AuthBloc, AuthState>(
                  listener: (ctx, state) {
                    if (state is AuthPasswordResetSent) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reset link sent! Check your email.'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  builder: (ctx, state) {
                    final loading = state is AuthLoading;
                    return ElevatedButton(
                      onPressed: loading
                          ? null
                          : () {
                              if (emailCtrl.text.trim().isNotEmpty) {
                                ctx.read<AuthBloc>().add(
                                  AuthPasswordResetRequested(
                                      emailCtrl.text.trim()),
                                );
                              }
                            },
                      child: loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Send Reset Link'),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}