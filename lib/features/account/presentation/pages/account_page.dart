import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/account_bloc.dart';
import '../../domain/entities/account_entities.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    context.read<AccountBloc>().add(AccountLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AccountBloc, AccountState>(
        listener: (context, state) {
          if (state is AccountSignedOut) {
            context.read<AuthBloc>().add(AuthSignOutRequested());
            context.go(AppRoutes.promo);
          }
          if (state is AccountError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ));
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
    );
  }
}

class _AccountContent extends StatelessWidget {
  final AccountUser user;
  const _AccountContent({required this.user});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [

            // ── Header ────────────────────────────
            _AccountHeader(user: user),

            const SizedBox(height: 8),

            // ── Subscription Banner ───────────────
            if (user.isSubscribed)
              _SubscriptionBanner(user: user)
            else
              _SubscribePrompt(),

            const SizedBox(height: 8),

            // ── Menu Sections ─────────────────────
            _MenuSection(
              title: 'Account',
              items: [
                _MenuItem(
                  icon: Icons.person_outline,
                  label: 'Edit Profile',
                  onTap: () => _showEditProfile(context, user),
                ),
                _MenuItem(
                  icon: Icons.credit_card_outlined,
                  label: 'My Card',
                  onTap: () => context.go(AppRoutes.card),
                ),
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Payment History',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 8),

            _MenuSection(
              title: 'Preferences',
              items: [
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.language_outlined,
                  label: 'Language',
                  trailing: const Text('English',
                      style: TextStyle(color: AppColors.textSecondary)),
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 8),

            _MenuSection(
              title: 'Support',
              items: [
                _MenuItem(
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  label: 'About CarePass',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.star_outline,
                  label: 'Rate the App',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Sign Out ──────────────────────────
            _MenuSection(
              items: [
                _MenuItem(
                  icon: Icons.logout,
                  label: 'Sign Out',
                  color: AppColors.error,
                  onTap: () => _confirmSignOut(context),
                ),
              ],
            ),

            const SizedBox(height: 32),

            Text('CarePass v1.0.0',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textHint)),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, AccountUser user) {
    final ctrl = TextEditingController(text: user.username);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AccountBloc>(),
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Profile',
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                Text('Username', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isNotEmpty) {
                      context.read<AccountBloc>().add(
                            AccountUsernameUpdateRequested(
                                ctrl.text.trim()),
                          );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<AccountBloc>()
                  .add(AccountSignOutRequested());
            },
            child: Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Header
// ─────────────────────────────────────────────
class _AccountHeader extends StatelessWidget {
  final AccountUser user;
  const _AccountHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              user.username.isNotEmpty
                  ? user.username[0].toUpperCase()
                  : '?',
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username,
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 2),
                Text(user.email,
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis),
                if (user.memberSince != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Member since ${user.memberSinceFormatted}',
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _AccountContent(user: user)
                ._showEditProfile(context, user),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Subscription Banner
// ─────────────────────────────────────────────
class _SubscriptionBanner extends StatelessWidget {
  final AccountUser user;
  const _SubscriptionBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.planName ?? 'Standard'} Plan',
                  style: AppTextStyles.titleMedium
                      .copyWith(color: Colors.white),
                ),
                Text('Active subscription',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.card),
            child: Text('View Card',
                style: AppTextStyles.labelLarge
                    .copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Subscribe Prompt
// ─────────────────────────────────────────────
class _SubscribePrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_membership_outlined,
              color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No Active Plan',
                    style: AppTextStyles.titleMedium),
                Text('Subscribe to get discounts',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.payment),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Menu Section
// ─────────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  final String? title;
  final List<_MenuItem> items;

  const _MenuSection({this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(title!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ...items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                e.value,
                if (!isLast)
                  const Divider(height: 1, indent: 56),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label,
          style: AppTextStyles.bodyMedium.copyWith(color: c)),
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios,
              size: 14, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}