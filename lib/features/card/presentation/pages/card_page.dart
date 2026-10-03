import 'package:carepass/core/utils/screen_security.dart';
import 'package:carepass/features/payment/presentation/pages/family_members_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/pages/terms_page.dart';
import '../../../auth/presentation/widgets/auth_gate.dart';
import '../bloc/card_bloc.dart';
import '../../domain/entities/card_entities.dart';
import '../widgets/health_checks_section.dart';

part '../widgets/card/terms_point.dart';
part '../widgets/card/card_content.dart';
part '../widgets/card/family_or_upgrade_section.dart';
part '../widgets/card/digital_card.dart';
part '../widgets/card/card_status_section.dart';
part '../widgets/card/subscribe_c_t_a.dart';
part '../widgets/card/quick_actions_section.dart';
part '../widgets/card/quick_action.dart';

class CardPage extends StatefulWidget {
  const CardPage({super.key});
  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  bool _checkingTerms = true;

  @override
  void initState() {
    super.initState();
    ScreenSecurity.enable();
    // ❌ We no longer request the card here.
    // This was causing a race condition where the card was requested
    // BEFORE the AuthGate could confirm the user was fully logged in.
    // ✅ Instead, we'll trigger the load from the BlocBuilder below.
    _checkTermsAccepted();
  }

  @override
  void dispose() {
    ScreenSecurity.disable();
    super.dispose();
  }

  // ✅ Check if user has already accepted T&C
  Future<void> _checkTermsAccepted() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _checkingTerms = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!mounted) return;

      final accepted = doc.data()?['termsAccepted'] as bool? ?? false;
      setState(() {
        _checkingTerms = false;
      });

      // Show T&C if not accepted (after frame renders)
      if (!accepted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showTermsForCard();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkingTerms = false);
    }
  }

  // ✅ T&C Dialog for card page — summary points match the
  // official Lakeside terms exactly (no AI mention, since the
  // AI feature isn't linked/active anywhere in the app anymore)
  void _showTermsForCard() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CarePass Terms & Conditions',
                    style: AppTextStyles.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please read and accept our terms before\naccessing your CarePass card.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // T&C Summary
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TermsPoint(
                      icon: Icons.health_and_safety_outlined,
                      title: 'What CarePass Is',
                      body:
                          'CarePass is a discount platform, NOT '
                          'health insurance. It connects you to '
                          'discounted medical services — it does not '
                          'cover or pay for treatment costs.',
                    ),
                    _TermsPoint(
                      icon: Icons.payments_outlined,
                      title: 'Direct & Immediate Payment',
                      body:
                          'You pay the provider directly after the '
                          'discount is applied — in cash or any method '
                          'they accept. No deferred payment or '
                          'installments are offered.',
                    ),
                    _TermsPoint(
                      icon: Icons.percent,
                      title: 'Percentage Discounts Only',
                      body:
                          'Prices vary by provider, so CarePass shows '
                          'discount percentages only — not fixed '
                          'prices. The discount applies to the '
                          'provider\'s standard listed price at time '
                          'of service.',
                    ),
                    _TermsPoint(
                      icon: Icons.verified_outlined,
                      title: 'Card Verification Required',
                      body:
                          'No discount applies unless your CarePass '
                          'card is verified by the provider. Misuse or '
                          'forgery results in suspension and possible '
                          'legal action.',
                    ),
                    _TermsPoint(
                      icon: Icons.event_repeat_outlined,
                      title: 'Free Monthly Services',
                      body:
                          'Free checks (e.g. blood pressure, glucose) '
                          'are available once per month from one '
                          'participating provider only.',
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(sheetCtx);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TermsPage()),
                        );
                        if (mounted) _showTermsForCard();
                      },
                      child: const Text('Read Full Terms & Conditions →'),
                    ),
                  ],
                ),
              ),
            ),

            // Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(sheetCtx);
                          await _acceptTerms();
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('I Accept the Terms'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          if (mounted) context.go(AppRoutes.home);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: const Text('Decline — Go Back'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Accept terms and save to Firestore
  Future<void> _acceptTerms() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'termsAccepted': true,
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AuthGate(
      message: 'Sign in to view your CarePass card',
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: _checkingTerms
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : BlocBuilder<CardBloc, CardState>(
                  builder: (context, state) {
                    // ✅ This is the new, correct place to trigger the load.
                    // The AuthGate widget ensures this code only runs *after*
                    // authentication is confirmed. If the card is in its
                    // initial state, we request the load and show a spinner.
                    if (state is CardInitial) {
                      context.read<CardBloc>().add(CardLoadRequested());
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (state is CardLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    if (state is CardError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => context.read<CardBloc>().add(
                                CardLoadRequested(),
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state is CardLoaded) {
                      return _CardContent(card: state.card);
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
//  Terms Point Widget
// ─────────────────────────────────────────────
