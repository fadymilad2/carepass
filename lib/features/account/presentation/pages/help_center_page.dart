import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';

part '../widgets/help_center/section_widget.dart';
part '../widgets/help_center/help_item_widget.dart';
part '../widgets/help_center/help_section.dart';
part '../widgets/help_center/help_item.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  // ✅ Default content — لو Firestore فاضي
  static const _defaultSections = [
    _HelpSection(
      title: 'Getting Started',
      icon: Icons.rocket_launch_outlined,
      items: [
        _HelpItem(
          question: 'How do I use CarePass?',
          answer:
              'Sign up and receive your digital CarePass card.\n'
              'Browse healthcare providers through the app.\n'
              'Visit any listed provider and present your CarePass to enjoy discounts.',
        ),
      ],
    ),
    _HelpSection(
      title: 'Payments & Discounts',
      icon: Icons.payments_outlined,
      items: [
        _HelpItem(
          question: 'How do I pay?',
          answer:
              'You pay the healthcare provider directly at the time of your visit.\n'
              'Your CarePass discount is applied instantly.',
        ),
        _HelpItem(
          question: 'Are there any hidden fees?',
          answer: 'No. You only pay the discounted price shown.',
        ),
      ],
    ),
    _HelpSection(
      title: 'Using Your Card',
      icon: Icons.credit_card_outlined,
      items: [
        _HelpItem(
          question: 'Where can I use CarePass?',
          answer: 'At any healthcare provider within the CarePass network.',
        ),
        _HelpItem(
          question: 'Do I need a physical card?',
          answer: 'No, your digital card is all you need.',
        ),
      ],
    ),
  ];

  List<_HelpSection> _sections = _defaultSections;
  String _contactEmail = 'support@carepassghana.com';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('app_content')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final helpCenter = data['helpCenter'] as Map<String, dynamic>?;

        if (helpCenter != null) {
          // ── Load contact email ─────────────────
          _contactEmail =
              helpCenter['contactEmail'] as String? ??
              'support@carepassghana.com';

          // ── Load sections ──────────────────────
          final rawSections = helpCenter['sections'] as List<dynamic>?;
          if (rawSections != null && rawSections.isNotEmpty) {
            _sections = rawSections.map((s) {
              final section = s as Map<String, dynamic>;
              final items = (section['items'] as List<dynamic>? ?? []).map((i) {
                final item = i as Map<String, dynamic>;
                return _HelpItem(
                  question: item['question'] as String? ?? '',
                  answer: item['answer'] as String? ?? '',
                );
              }).toList();

              return _HelpSection(
                title: section['title'] as String? ?? '',
                icon: Icons.help_outline,
                items: items,
              );
            }).toList();
          }
        }
      }
    } catch (e) {
      // Use default content on error
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────
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
                          Icons.headset_mic_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'How can we help you?',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find answers to common questions below',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Sections ───────────────────────
                  ..._sections.map(
                    (section) => _SectionWidget(section: section),
                  ),

                  const SizedBox(height: 20),

                  // ── Contact Section ────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.contact_support_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Need Help?',
                              style: AppTextStyles.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'For any questions or support, please contact '
                          'the CarePass team through our support Email:',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse(
                              'mailto:$_contactEmail'
                              '?subject=CarePass Support Request',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusMD,
                              ),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _contactEmail,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your health, our priority.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
//  Section Widget
// ─────────────────────────────────────────────
