import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import 'terms_page.dart';

part '../widgets/login/phone_step.dart';
part '../widgets/login/otp_step.dart';
part '../widgets/login/profile_step.dart';
part '../widgets/login/terms_checkbox.dart';
part '../widgets/login/field_label.dart';
part '../widgets/login/confirm_row.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  AuthState? _stepState;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStep(context, state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(BuildContext context, AuthState state) {
    // Keep form state and entered values while a request is pending or fails.
    final loading = state is AuthLoading;
    if (state is! AuthLoading && state is! AuthError) _stepState = state;
    state = _stepState ?? state;
    if (state is AuthOtpSent) {
      return _OtpStep(
        phoneNumber: state.phoneNumber,
        verificationId: state.verificationId,
      );
    }
    if (state is AuthNeedsProfile) {
      return _ProfileStep(uid: state.uid, phoneNumber: state.phoneNumber);
    }
    return _PhoneStep(
      formKey: _formKey,
      phoneCtrl: _phoneCtrl,
      loading: loading,
    );
  }
}

// ─────────────────────────────────────────────
//  Step 1: Phone
// ─────────────────────────────────────────────
