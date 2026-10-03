import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

part '../widgets/terms/section.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.cardGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'CarePass Subscriber\nTerms and Conditions',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Operated by Lakeside University Hospital LTD',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      'Welcome to the CarePass platform. Please read these '
                      'Terms and Conditions carefully before completing '
                      'your registration and subscription. Your acceptance '
                      'of these terms constitutes a legally binding '
                      'agreement.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _Section(
                    number: '1',
                    title: 'Service Definition',
                    body:
                        'CarePass is a digital intermediary platform that '
                        'enables subscribers holding valid CarePass cards '
                        'to access medical discounts and benefits through '
                        'a network of partner healthcare providers '
                        '(hospitals, clinics, pharmacies, and laboratories).',
                  ),

                  _Section(
                    number: '2',
                    title: 'Subscription Fees and Card Usage',
                    body:
                        'The user agrees to pay the applicable subscription '
                        'fee through the application to activate membership '
                        'and issue a CarePass card (digital or physical).\n\n'
                        'The subscription is personal and exclusive to the '
                        'cardholder and may not be transferred or used by '
                        'any third party.',
                  ),

                  _Section(
                    number: '3',
                    title: 'Payment to Medical Providers',
                    body:
                        'Direct Payment:\n'
                        'The subscriber must pay the cost of medical '
                        'services (after applying the discount) directly to '
                        'the healthcare provider, either in cash or via any '
                        'payment methods accepted by the provider.\n\n'
                        'Immediate Payment (No Deferral):\n'
                        'Payment must be made immediately upon receiving '
                        'the service. Neither the platform nor the '
                        'healthcare providers offer deferred payment or '
                        'installment options (monthly or weekly).\n\n'
                        'Financial Liability Disclaimer:\n'
                        'CarePass does not act as a financial intermediary '
                        'and bears no responsibility for any financial '
                        'transactions between the patient and the '
                        'healthcare provider.',
                  ),

                  _Section(
                    number: '4',
                    title: 'Card Verification',
                    body:
                        'To benefit from discounts, the subscriber must '
                        'provide valid proof of their CarePass card through '
                        'approved verification channels (physical card, '
                        'application, or website).\n\n'
                        'No discount or subsidized service will be applied '
                        'unless verification is successfully completed by '
                        'the healthcare provider.\n\n'
                        'Any attempt to forge or misuse the card will '
                        'result in immediate account suspension and '
                        'potential legal action.',
                  ),

                  _Section(
                    number: '5',
                    title: 'Periodic Free Services',
                    body:
                        'Subscribers are entitled to receive specific free '
                        'services (such as blood pressure measurement and '
                        'random blood glucose testing) once per month only, '
                        'from any one participating service provider.\n\n'
                        'If free services are unavailable at a specific '
                        'provider, the provider may refer the subscriber to '
                        'another provider where the service is available, '
                        'or direct the subscriber to customer support to '
                        'assist in locating the nearest available provider.',
                  ),

                  _Section(
                    number: '6',
                    title: 'Discount Display and Calculation',
                    body:
                        'Percentage-Based Discounts Only:\n'
                        'Please note that base prices for medical services '
                        'vary between healthcare providers. Accordingly, '
                        'the CarePass platform displays only the discount '
                        'percentages within the application, not the '
                        'actual service prices.\n\n'
                        'Calculation Method:\n'
                        'The displayed discount percentage is applied to '
                        'the provider\'s standard listed price at the time '
                        'of service.',
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warningSurface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'By accepting these terms, you acknowledge that '
                            'you have read, understood, and agree to be '
                            'bound by these Terms & Conditions.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Accept Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('I Understand & Accept'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Section Widget
// ─────────────────────────────────────────────
