import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey      = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscure       = true;
  bool _obscureConfirm= true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthRegisterRequested(
      username: _usernameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
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
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingLG),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create Account',
                      style: AppTextStyles.headlineLarge),
                  const SizedBox(height: 8),
                  Text('Join CarePass and start saving on healthcare.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),

                  const SizedBox(height: 32),

                  // Username
                  Text('Username', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'johndoe',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (v.trim().length < 3) {
                        return 'Min 3 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                        return 'Only letters, numbers and underscores';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

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

                  const SizedBox(height: 20),

                  // Confirm Password
                  Text('Confirm Password', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (v != _passwordCtrl.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: loading ? null : _submit,
                    child: loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Create Account'),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: Text('Sign In',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}