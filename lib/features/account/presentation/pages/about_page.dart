import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';

part '../widgets/about/stat_tile.dart';
part '../widgets/about/contact_row.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  // ✅ Default content
  static const _defaultText =
      'CarePass is a digital healthcare platform designed to make '
      'quality medical services more accessible and affordable. '
      'Through a simple digital health card, CarePass connects you '
      'to a trusted network of clinics, hospitals, pharmacies, and '
      'laboratories, giving you exclusive discounts on a wide range '
      'of healthcare services.\n\n'
      'Our goal is to help you save more while receiving better care. '
      'With CarePass, you can easily find healthcare providers, access '
      'discounted services, and pay directly with full transparency — '
      'no hidden fees, no complicated processes.\n\n'
      'Everything is built around convenience and simplicity. From '
      'browsing providers to using your digital card, CarePass ensures '
      'a smooth experience so you can focus on what matters most, '
      'your health.\n\n'
      'CarePass is not insurance. It\'s a smarter, easier way to '
      'access healthcare at reduced costs whenever you need it.';

  String _aboutText = _defaultText;
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
        final about = data['about'] as Map<String, dynamic>?;
        if (about != null) {
          final text = about['text'] as String?;
          if (text != null && text.isNotEmpty) {
            _aboutText = text;
          }
        }
      }
    } catch (_) {
      // Use default content
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About CarePass'),
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
                  // ── Logo + Brand ───────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.cardGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'CarePass',
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your health, our priority.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusFull,
                            ),
                          ),
                          child: Text(
                            'Version 1.0.0',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── About Text ─────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _aboutText,
                      style: AppTextStyles.bodyMedium.copyWith(
                        height: 1.7,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Quick Stats ────────────────────
                  Row(
                    children: const [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.local_hospital_outlined,
                          value: '200+',
                          label: 'Providers',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.medical_services_outlined,
                          value: '50%',
                          label: 'Max Discount',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.location_on_outlined,
                          value: 'Ghana',
                          label: 'Serving',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Contact Info ───────────────────
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
                        Text('Contact Us', style: AppTextStyles.titleMedium),
                        const SizedBox(height: 16),

                        _ContactRow(
                          icon: Icons.language_outlined,
                          label: 'Website',
                          value: 'carepassghana.com',
                          onTap: () async {
                            final uri = Uri.parse('https://carepassghana.com');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _ContactRow(
                          icon: Icons.email_outlined,
                          label: 'Support',
                          value: 'support@carepassghana.com',
                          onTap: () async {
                            final uri = Uri.parse(
                              'mailto:support@carepassghana.com'
                              '?subject=CarePass Support Request',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
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
//  Stat Tile
// ─────────────────────────────────────────────
