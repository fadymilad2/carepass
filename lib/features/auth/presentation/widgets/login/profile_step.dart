part of '../../pages/login_page.dart';

class _ProfileStep extends StatefulWidget {
  final String uid;
  final String phoneNumber;

  const _ProfileStep({required this.uid, required this.phoneNumber});

  @override
  State<_ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<_ProfileStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();

  DateTime? _selectedDob;
  String? _selectedCity;
  String? _selectedBloodType;
  bool _termsAccepted = false;
  bool _cancelling = false; // ✅ New

  static const _cities = [
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

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  int? get _age {
    if (_selectedDob == null) return null;
    final now = DateTime.now();
    int a = now.year - _selectedDob!.year;
    if (now.month < _selectedDob!.month ||
        (now.month == _selectedDob!.month && now.day < _selectedDob!.day)) {
      a--;
    }
    return a;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      helpText: 'Select Date of Birth',
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  // ✅ New — lets the user back out of registration entirely.
  // The user is already Firebase-authenticated at this point (the
  // OTP step already succeeded) but has no Firestore profile yet —
  // that's exactly what AuthNeedsProfile means. Without an explicit
  // way out, the Android back button (or accidentally leaving this
  // screen) would strand them: re-opening the login flow later would
  // land right back here with no fresh start available, since the
  // shared AuthBloc + Firebase Auth session both remember this
  // half-registered state.
  //
  // Signing out here fully resets that: Firebase forgets the phone
  // verification, AuthBloc goes back to its initial unauthenticated
  // state, and popping the route returns the user to wherever they
  // came from (the Card or Account tab's AuthGate prompt) — free to
  // either try again from scratch or just keep browsing as a guest.
  Future<void> _cancelRegistration(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Registration?'),
        content: const Text(
          "You'll need to verify your phone number again if you "
          "want to sign in later. Your progress won't be saved.",
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => dc.pop(false),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () => dc.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    setState(() => _cancelling = true);

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Even if sign-out fails for some reason, still let the user
      // leave the screen rather than trapping them here.
    }

    if (!context.mounted) return;

    context.read<AuthBloc>().add(AuthCheckRequested());

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<bool> _showConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Review Your Information',
                        style: AppTextStyles.headlineSmall,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warningSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_outlined,
                                color: AppColors.warning,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your name and date of birth cannot be '
                                  'changed after registration.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ConfirmRow(
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: _nameCtrl.text.trim(),
                          locked: true,
                        ),
                        _ConfirmRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: widget.phoneNumber,
                          locked: true,
                        ),
                        if (_selectedDob != null)
                          _ConfirmRow(
                            icon: Icons.cake_outlined,
                            label: 'Date of Birth',
                            value:
                                '${DateFormat('dd MMM yyyy').format(_selectedDob!)} '
                                '(Age: ${_age ?? '—'})',
                            locked: true,
                          ),
                        if (_emailCtrl.text.isNotEmpty)
                          _ConfirmRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: _emailCtrl.text.trim(),
                          ),
                        if (_selectedCity != null)
                          _ConfirmRow(
                            icon: Icons.location_city_outlined,
                            label: 'City',
                            value: _selectedCity!,
                          ),
                        if (_selectedBloodType != null)
                          _ConfirmRow(
                            icon: Icons.water_drop_outlined,
                            label: 'Blood Type',
                            value: _selectedBloodType!,
                          ),
                        if (_emergencyCtrl.text.isNotEmpty)
                          _ConfirmRow(
                            icon: Icons.emergency_outlined,
                            label: 'Emergency Contact',
                            value: _emergencyCtrl.text.trim(),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Confirm & Register'),
                  ),
                ),

                const SizedBox(height: 6),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions to continue'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final confirmed = await _showConfirmation();
    if (!confirmed || !context.mounted) return;

    context.read<AuthBloc>().add(
      AuthCreateProfileRequested(
        uid: widget.uid,
        username: _nameCtrl.text.trim(),
        phoneNumber: widget.phoneNumber,
        email: _emailCtrl.text.trim(),
        dateOfBirth: _selectedDob?.toIso8601String().split('T')[0],
        city: _selectedCity,
        emergencyContact: _emergencyCtrl.text.trim(),
        bloodType: _selectedBloodType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthBloc>().state is AuthLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingXL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // ✅ New — explicit back/cancel arrow, matching the
            // visual style already used on the OTP step, so the
            // registration flow has a consistent, discoverable way
            // out at every step instead of only the first two.
            Row(
              children: [
                IconButton(
                  icon: _cancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.arrow_back_ios),
                  padding: EdgeInsets.zero,
                  onPressed: (loading || _cancelling)
                      ? null
                      : () => _cancelRegistration(context),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 36,
              ),
            ),

            const SizedBox(height: 16),
            Text('Almost there!', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 6),
            Text(
              'Complete your profile to get started.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            _FieldLabel('Full Name *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Kofi Mensah',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Name is required';
                }
                if (v.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _FieldLabel('Phone Number'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    color: AppColors.textHint,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.phoneNumber,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.lock_outlined,
                    color: AppColors.textHint,
                    size: 14,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _FieldLabel('Email (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'your@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v != null && v.isNotEmpty && !v.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            _FieldLabel('Date of Birth *'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDob,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                  border: Border.all(
                    color: _selectedDob == null
                        ? AppColors.border
                        : AppColors.primary,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cake_outlined,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedDob == null
                            ? 'Select date of birth'
                            : DateFormat('dd MMMM yyyy').format(_selectedDob!),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _selectedDob == null
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (_selectedDob != null && _age != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusFull,
                          ),
                        ),
                        child: Text(
                          'Age: $_age',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                  ],
                ),
              ),
            ),

            if (_selectedDob == null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  '⚠️ Cannot be changed after registration',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            _FieldLabel('City (optional)'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              hint: const Text('Select your city'),
              onChanged: (v) => setState(() => _selectedCity = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              items: _cities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
            ),

            const SizedBox(height: 16),

            _FieldLabel('Blood Type (optional)'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedBloodType,
              hint: const Text('Select blood type'),
              onChanged: (v) => setState(() => _selectedBloodType = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.water_drop_outlined),
              ),
              items: _bloodTypes
                  .map((bt) => DropdownMenuItem(value: bt, child: Text(bt)))
                  .toList(),
            ),

            const SizedBox(height: 16),

            _FieldLabel('Emergency Contact (optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emergencyCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '+233 XX XXX XXXX',
                prefixIcon: Icon(Icons.emergency_outlined),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Contact to reach in case of emergency',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),

            const SizedBox(height: 24),

            _TermsCheckbox(
              accepted: _termsAccepted,
              onChanged: (v) => setState(() => _termsAccepted = v ?? false),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (loading || _cancelling || !_termsAccepted)
                    ? null
                    : () => _submit(context),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Get Started', style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Terms Checkbox Widget
// ─────────────────────────────────────────────
