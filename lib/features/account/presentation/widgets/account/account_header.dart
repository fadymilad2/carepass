part of '../../pages/account_page.dart';

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
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
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
                Text(user.username, style: AppTextStyles.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  user.phoneNumber,
                  style: AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
            onPressed: () =>
                _AccountContent(user: user)._showEditProfile(context, user),
          ),
        ],
      ),
    );
  }
}
