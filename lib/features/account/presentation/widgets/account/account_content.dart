part of '../../pages/account_page.dart';

class _AccountContent extends StatelessWidget {
  final AccountUser user;
  const _AccountContent({required this.user});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _AccountHeader(user: user),
            const SizedBox(height: 8),

            if (user.isSubscribed)
              _SubscriptionBanner(user: user)
            else
              _SubscribePrompt(),
            const SizedBox(height: 8),

            _MenuSection(
              title: 'Account',
              items: [
                _MenuItem(
                  icon: Icons.person_outline,
                  label: 'Edit Profile',
                  onTap: () => _showEditProfile(context, user),
                ),
                _MenuItem(
                  icon: Icons.delete_forever_outlined,
                  label: 'Delete Account',
                  color: AppColors.error,
                  onTap: () => _confirmDeletion(context),
                ),
                _MenuItem(
                  icon: Icons.credit_card_outlined,
                  label: 'My Card',
                  onTap: () => context.go(AppRoutes.card),
                ),
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Payment History',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentHistoryPage(),
                    ),
                  ),
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
                  onTap: () => AppRouter.router.push(AppRoutes.notifications),
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpCenterPage()),
                  ),
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  label: 'About CarePass',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutPage()),
                  ),
                ),
                _MenuItem(
                  icon: Icons.star_outline,
                  label: 'Rate the App',
                  onTap: () => _showRateDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _MenuSection(
              items: [
                _MenuItem(
                  icon: Icons.logout,
                  label: 'Sign Out',
                  color: AppColors.error,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dc) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text(
                          'Are you sure you want to sign out?',
                        ),
                        actionsAlignment: MainAxisAlignment.end,
                        actions: [
                          TextButton(
                            onPressed: () => dc.pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => dc.pop(true),
                            child: Text(
                              'Sign Out',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      context.read<AuthBloc>().add(AuthSignOutRequested());
                      context.go(AppRoutes.home);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),
            Text(
              'CarePass v1.0.0',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ✅ Star Rating Dialog
  Future<void> _confirmDeletion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permanently delete account?'),
        content: const Text(
          'This removes your sign-in account, profile, family details, membership, '
          'favorites, notifications and payment records stored by CarePass. '
          'You will lose access to your membership. This cannot be undone and does '
          'not issue a refund or delete records held by payment providers. '
          'A minimal deletion-status record is kept to prevent account data from '
          'being recreated. For your security, sign in again first if your last '
          'sign-in was more than five minutes ago.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete permanently',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AccountBloc>().add(AccountDeleteRequested());
    }
  }

  void _showRateDialog(BuildContext outerContext) {
    showDialog(
      context: outerContext,
      builder: (dialogContext) {
        int selectedStars = 0;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Rate CarePass', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'How would you rate your\nCarePass experience?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedStars = i + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: Icon(
                          i < selectedStars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: i < selectedStars
                              ? Colors.amber
                              : Colors.grey.shade400,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _ratingText(selectedStars),
                    key: ValueKey(selectedStars),
                    style: TextStyle(
                      color: selectedStars >= 4
                          ? AppColors.primary
                          : selectedStars > 0
                          ? AppColors.textSecondary
                          : Colors.transparent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedStars == 0
                          ? null
                          : () async {
                              Navigator.pop(dialogContext);
                              if (outerContext.mounted) {
                                ScaffoldMessenger.of(outerContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Thank you for your '
                                      '$selectedStars-star rating! ⭐',
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              if (selectedStars >= 4) {
                                final uri = Uri.parse(
                                  'https://carepassghana.com',
                                );
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              }
                            },
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  String _ratingText(int stars) {
    switch (stars) {
      case 1:
        return "We're sorry to hear that 😔";
      case 2:
        return "We'll try to do better 🙏";
      case 3:
        return "Thanks for your feedback!";
      case 4:
        return "Great! We're glad you like it 😊";
      case 5:
        return "Awesome! You made our day! 🎉";
      default:
        return '';
    }
  }

  // ✅ Edit Profile
  void _showEditProfile(BuildContext context, AccountUser user) {
    final emailCtrl = TextEditingController(text: user.email);
    final emergencyCtrl = TextEditingController(
      text: user.emergencyContact ?? '',
    );
    String? selectedCity = user.city;
    String? selectedBloodType = user.bloodType;

    const cities = [
      'Accra',
      'Kumasi',
      'Tamale',
      'Takoradi',
      'Tema',
      'Cape Coast',
      'Ho',
      'Koforidua',
      'Wa',
      'Sunyani',
    ];
    const bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => BlocProvider.value(
          value: context.read<AccountBloc>(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Edit Profile',
                          style: AppTextStyles.headlineSmall,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lock_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Locked — cannot be changed',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _LockedField(
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            value: user.username,
                          ),
                          const SizedBox(height: 8),
                          _LockedField(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: user.phoneNumber,
                          ),
                          if (user.dateOfBirth != null &&
                              user.dateOfBirth!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _LockedField(
                              icon: Icons.cake_outlined,
                              label: 'Date of Birth',
                              value: () {
                                try {
                                  return DateFormat(
                                    'dd MMM yyyy',
                                  ).format(DateTime.parse(user.dateOfBirth!));
                                } catch (_) {
                                  return user.dateOfBirth!;
                                }
                              }(),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warningSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_outlined,
                                  size: 13,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'To change locked info, contact support.',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Editable Fields', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 12),

                    Text('Email', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'your@email.com',
                      ),
                    ),

                    const SizedBox(height: 14),
                    Text('City', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCity,
                      hint: const Text('Select city'),
                      onChanged: (v) => setModalState(() => selectedCity = v),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      items: cities
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 14),

                    Text('Blood Type', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBloodType,
                      hint: const Text('Select blood type'),
                      onChanged: (v) =>
                          setModalState(() => selectedBloodType = v),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.water_drop_outlined),
                      ),
                      items: bloodTypes
                          .map(
                            (bt) =>
                                DropdownMenuItem(value: bt, child: Text(bt)),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),

                    Text('Emergency Contact', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: emergencyCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.emergency_outlined),
                        hintText: '+233 XX XXX XXXX',
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<AccountBloc>().add(
                            AccountProfileUpdateRequested(
                              email: emailCtrl.text.trim().isEmpty
                                  ? null
                                  : emailCtrl.text.trim(),
                              city: selectedCity,
                              bloodType: selectedBloodType,
                              emergencyContact:
                                  emergencyCtrl.text.trim().isEmpty
                                  ? null
                                  : emergencyCtrl.text.trim(),
                            ),
                          );
                          Navigator.pop(sheetCtx);
                        },
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Locked Field ──────────────────────────────
