import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/auth_gate.dart'; // ✅ New
import '../bloc/account_bloc.dart';
import '../../domain/entities/account_entities.dart';
import 'payment_history_page.dart';
import 'help_center_page.dart';
import 'about_page.dart';

part '../widgets/account/account_content.dart';
part '../widgets/account/locked_field.dart';
part '../widgets/account/account_header.dart';
part '../widgets/account/subscription_banner.dart';
part '../widgets/account/subscribe_prompt.dart';
part '../widgets/account/menu_section.dart';
part '../widgets/account/menu_item.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    if (context.read<AuthBloc>().state is AuthAuthenticated) {
      context.read<AccountBloc>().add(AccountLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Fixed — AccountPage now wraps itself with AuthGate, exactly
    // like CardPage already does. Before this, a guest reaching this
    // page had no in-place handling at all (initState fired
    // AccountLoadRequested unconditionally, and _AccountContent
    // assumed a fully-populated AccountUser existed) — it would have
    // either crashed or shown broken/empty state. Now guests see the
    // same friendly "Sign in Required" prompt used on the Card tab,
    // and this StatefulWidget's initState/build only ever run once
    // AuthGate confirms the user is actually authenticated — so the
    // AccountLoadRequested() above never fires for a guest at all.
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.read<AccountBloc>().add(AccountLoadRequested());
        }
      },
      child: AuthGate(
        message: 'Sign in to view your CarePass profile',
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: BlocConsumer<AccountBloc, AccountState>(
            listener: (context, state) {
              if (state is AccountSignedOut) {
                context.read<AuthBloc>().add(AuthSignOutRequested());
                context.go(AppRoutes.promo);
              }
              if (state is AccountError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              if (state is AccountUpdateSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated ✅'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is AccountLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (state is AccountLoaded || state is AccountUpdateSuccess) {
                final user = state is AccountLoaded
                    ? state.user
                    : (state as AccountUpdateSuccess).user;
                return _AccountContent(user: user);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Account Content
// ─────────────────────────────────────────────
