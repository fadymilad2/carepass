import 'package:carepass/features/payment/presentation/widgets/family_member_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/payment_bloc.dart';
import '../../domain/entities/payment_entities.dart';
import 'expresspay_webview_page.dart';

part '../widgets/payment/plans_content.dart';
part '../widgets/payment/upgrade_notice_card.dart';
part '../widgets/payment/family_members_section.dart';
part '../widgets/payment/discount_section.dart';
part '../widgets/payment/order_summary.dart';
part '../widgets/payment/summary_row.dart';
part '../widgets/payment/plan_card.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(PaymentPlansRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentUrlReady) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<PaymentBloc>(),
                  child: ExpressPayWebViewPage(
                    url: state.url,
                    reference: state.reference,
                    plan: state.plan,
                  ),
                ),
              ),
            );
          }

          if (state is PaymentSuccess) {
            context.go(AppRoutes.paymentSuccess);
          }

          if (state is PaymentFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
            if (state.message != 'Payment cancelled') {
              Future.delayed(const Duration(seconds: 1), () {
                if (context.mounted) {
                  context.read<PaymentBloc>().add(PaymentPlansRequested());
                }
              });
            }
          }
        },
        builder: (context, state) {
          if (state is PaymentPending) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.isMonitoring)
                      const CircularProgressIndicator()
                    else
                      const Icon(
                        Icons.schedule,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      state.message ??
                          (state.isMonitoring
                              ? 'Waiting for payment confirmation. Complete any approval on your phone. We will check automatically and show the result. Please do not pay again.'
                              : 'Payment confirmation is taking longer than expected. Your payment is still pending. Check its status again or return to the same checkout. Please do not pay again.'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (!state.isMonitoring)
                      FilledButton(
                        onPressed: () => context.read<PaymentBloc>().add(
                          PaymentVerifyRequested(state.reference),
                        ),
                        child: const Text('Check payment status'),
                      ),
                    TextButton(
                      onPressed: () => context.read<PaymentBloc>().add(
                        PaymentCheckoutResumeRequested(),
                      ),
                      child: const Text('Return to checkout'),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: const Text('Return home'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is PaymentLoading || state is PaymentVerifying) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    state is PaymentVerifying
                        ? 'Verifying payment...'
                        : 'Loading...',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            );
          }

          if (state is PaymentPlansLoaded && state.plans.isEmpty) {
            return const Center(
              child: Text('No subscription plans are available.'),
            );
          }
          if (state is PaymentPlansLoaded) {
            return _PlansContent(state: state);
          }

          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Plans Content
// ─────────────────────────────────────────────
