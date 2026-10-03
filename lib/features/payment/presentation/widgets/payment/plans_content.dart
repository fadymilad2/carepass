part of '../../pages/payment_page.dart';

class _PlansContent extends StatefulWidget {
  final PaymentPlansLoaded state;
  const _PlansContent({required this.state});

  @override
  State<_PlansContent> createState() => _PlansContentState();
}

class _PlansContentState extends State<_PlansContent> {
  final _codeCtrl = TextEditingController();
  bool _codeVisible = false;

  // Family members state
  List<FamilyMember> _familyMembers = [];
  bool _loadingMembers = false;

  // Upgrade detection & pricing state
  bool _loadingCurrentSub = true;
  bool _hasActiveIndividualSub = false;
  bool _currentIsAnnual = false;
  String? _currentPlanName;
  double _currentPlanPrice = 0;
  int _currentPlanDurationDays = 30;
  DateTime? _currentExpiryDate;

  @override
  void initState() {
    super.initState();
    _loadExistingFamilyMembers();
    _loadCurrentSubscriptionInfo();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  SubscriptionPlan get _selected =>
      widget.state.selected ?? widget.state.plans.first;

  DiscountCode? get _discount => widget.state.appliedDiscount;

  bool get _isFamilyPlan => _selected.isFamilyPlan;

  bool get _isUpgradingToFamily =>
      _hasActiveIndividualSub && _selected.isFamilyPlan;

  bool get _upgradeBlocked => _isUpgradingToFamily && _currentIsAnnual;

  int get _daysElapsedInCurrentPlan {
    if (_currentExpiryDate == null) return 0;
    final remaining = _currentExpiryDate!
        .difference(DateTime.now())
        .inDays
        .clamp(0, _currentPlanDurationDays);
    return (_currentPlanDurationDays - remaining).clamp(
      0,
      _currentPlanDurationDays,
    );
  }

  bool get _isEarlyUpgradeWindow => _daysElapsedInCurrentPlan <= 15;

  double get _upgradeBaseAmount {
    if (!_isUpgradingToFamily) return _selected.price;
    if (_upgradeBlocked) return _selected.price;
    if (_isEarlyUpgradeWindow) {
      final diff = _selected.price - _currentPlanPrice;
      return diff > 0 ? diff : 0;
    }
    return _selected.price;
  }

  double get _finalTotal {
    final base = _upgradeBaseAmount;
    if (_discount != null) {
      final discounted = base - _discount!.discountAmount(base);
      return discounted * 1.20;
    }
    return base * 1.20;
  }

  Future<void> _loadCurrentSubscriptionInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingCurrentSub = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        if (mounted) setState(() => _loadingCurrentSub = false);
        return;
      }

      final data = userDoc.data()!;
      final status = data['subscriptionStatus'] as String? ?? 'none';
      final type = (data['subscriptionType'] as String? ?? 'individual')
          .toLowerCase();
      final planId = data['planName'] as String?;
      final expiryStr = data['cardExpiryDate'] as String?;

      if (status == 'active' &&
          DateTime.tryParse(expiryStr ?? '')?.isAfter(DateTime.now()) == true &&
          type != 'family' &&
          planId != null &&
          expiryStr != null) {
        final planDoc = await FirebaseFirestore.instance
            .collection('subscription_plans')
            .doc(planId)
            .get();

        if (planDoc.exists && planDoc.data() != null) {
          final pdata = planDoc.data()!;
          final duration = pdata['durationDays'] as int? ?? 30;

          if (mounted) {
            setState(() {
              _hasActiveIndividualSub = true;
              _currentIsAnnual = duration >= 365;
              _currentPlanName = pdata['name'] as String?;
              _currentPlanPrice = (pdata['price'] as num? ?? 0).toDouble();
              _currentPlanDurationDays = duration;
              _currentExpiryDate = DateTime.tryParse(expiryStr);
            });
          }
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _loadingCurrentSub = false);
  }

  Future<void> _loadExistingFamilyMembers() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loadingMembers = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final raw = doc.data()!['familyMembers'] as List<dynamic>?;
        if (raw != null) {
          setState(() {
            _familyMembers = raw
                .map(
                  (m) =>
                      FamilyMember.fromMap(Map<String, dynamic>.from(m as Map)),
                )
                .toList();
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingMembers = false);
  }

  Future<void> _saveFamilyMembers() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'familyMembers': _familyMembers.map((m) => m.toMap()).toList(),
      });
    } catch (_) {}
  }

  void _showAddMemberDialog() {
    final maxMembers = _selected.maxFamilyMembers;
    if (_familyMembers.length >= maxMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum $maxMembers family members allowed for this plan',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dc) => AddFamilyMemberDialog(
        onAdd: (member) {
          setState(() => _familyMembers.add(member));
          _saveFamilyMembers();
        },
      ),
    );
  }

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@carepassghana.com',
      query: 'subject=${Uri.encodeComponent('Upgrade to Family Plan Request')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingMD),
      child: Column(
        children: [
          Text(
            'Quality Care for Less',
            style: AppTextStyles.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the plan that works for you',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // ── Plan Cards ─────────────────────────
          ...widget.state.plans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanCard(
                plan: plan,
                isSelected: plan.id == _selected.id,
                onSelect: () =>
                    context.read<PaymentBloc>().add(PaymentPlanSelected(plan)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Upgrade context banner ──────────────
          if (_loadingCurrentSub && _isFamilyPlan) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_isUpgradingToFamily) ...[
            _UpgradeNoticeCard(
              blocked: _upgradeBlocked,
              earlyWindow: _isEarlyUpgradeWindow,
              daysElapsed: _daysElapsedInCurrentPlan,
              currentPlanName: _currentPlanName ?? 'your current plan',
              onContactSupport: _contactSupport,
            ),
            const SizedBox(height: 16),
          ],

          // ── Family Members Section — only for family plan ──
          if (_isFamilyPlan) ...[
            _FamilyMembersSection(
              members: _familyMembers,
              maxMembers: _selected.maxFamilyMembers,
              loading: _loadingMembers,
              onAdd: _showAddMemberDialog,
              onRemove: (id) {
                setState(() => _familyMembers.removeWhere((m) => m.id == id));
                _saveFamilyMembers();
              },
            ),
            const SizedBox(height: 16),
          ],

          // ✅ Blocked annual→family upgrade
          if (_upgradeBlocked) ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _contactSupport,
                icon: const Icon(Icons.support_agent_outlined),
                label: const Text('Contact Customer Support'),
              ),
            ),
            const SizedBox(height: 32),
          ] else ...[
            // ── Discount Code Section ───────────────
            _DiscountSection(
              state: widget.state,
              codeCtrl: _codeCtrl,
              isVisible: _codeVisible,
              onToggle: () => setState(() => _codeVisible = !_codeVisible),
              onApply: () {
                if (_codeCtrl.text.trim().isEmpty) return;
                context.read<PaymentBloc>().add(
                  PaymentDiscountCodeApplied(_codeCtrl.text.trim()),
                );
              },
              onRemove: () {
                _codeCtrl.clear();
                context.read<PaymentBloc>().add(PaymentDiscountCodeRemoved());
              },
            ),

            const SizedBox(height: 16),

            // ── Order Summary ───────────────────────
            _OrderSummary(
              plan: _selected,
              discount: _discount,
              isUpgrade: _isUpgradingToFamily,
              isEarlyUpgradeWindow: _isEarlyUpgradeWindow,
              currentPlanName: _currentPlanName,
              currentPlanPrice: _currentPlanPrice,
              upgradeBaseAmount: _upgradeBaseAmount,
            ),

            const SizedBox(height: 16),

            // ── Pay Button ─────────────────────────
            BlocBuilder<PaymentBloc, PaymentState>(
              builder: (context, state) {
                final loading = state is PaymentLoading;
                return SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: loading ? null : () => _pay(context),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Pay ${_selected.currency} '
                            '${_finalTotal.toStringAsFixed(2)}',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text('Secured by Paystack', style: AppTextStyles.bodySmall),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  void _pay(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go(AppRoutes.login);
      return;
    }

    final String secureEmail =
        (user.email != null && user.email!.trim().isNotEmpty)
        ? user.email!
        : '${user.uid}@carepass.app';

    context.read<PaymentBloc>().add(
      PaymentInitRequested(
        plan: _selected,
        email: secureEmail,
        overrideBaseAmount: _isUpgradingToFamily ? _upgradeBaseAmount : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Upgrade Notice Card
// ─────────────────────────────────────────────
