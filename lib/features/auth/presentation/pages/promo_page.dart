import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class PromoPage extends StatefulWidget {
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  static const _pages = [
    _PromoData(
      icon: Icons.local_hospital_outlined,
      color: AppColors.primary,
      title: 'Quality Healthcare\nfor Less',
      subtitle:
          'Access top clinics and hospitals across Ghana with exclusive member discounts.',
    ),
    _PromoData(
      icon: Icons.verified_outlined,
      color: Color(0xFF3182CE),
      title: 'Trusted Provider\nNetwork',
      subtitle:
          'Over 200+ verified clinics, hospitals, and pharmacies in your area.',
    ),
    _PromoData(
      icon: Icons.credit_card_outlined,
      color: Color(0xFF38A169),
      title: 'Your Digital\nHealth Card',
      subtitle:
          'One card. All your discounts. Show it at any partner provider instantly.',
    ),
    _PromoData(
      icon: Icons.phone_android_outlined,
      color: Color(0xFFD69E2E),
      title: 'Pay with\nMobile Money',
      subtitle:
          'Subscribe easily with MTN Mobile Money. Cancel anytime, no hidden fees.',
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [

            // ── Skip button ──────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(
                  'Skip',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            // ── Pages ────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _PromoSlide(data: _pages[i]),
              ),
            ),

            // ── Dots ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── CTA Button ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingLG),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(
                  _currentPage == _pages.length - 1
                      ? 'Get Started'
                      : 'Next',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Already have account ─────────────────────
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.bodyMedium,
                  children: [
                    TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Slide Widget
// ─────────────────────────────────────────────
class _PromoSlide extends StatelessWidget {
  final _PromoData data;
  const _PromoSlide({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingXL, vertical: AppDimens.paddingLG),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Icon circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 64, color: data.color),
          ),

          const SizedBox(height: 48),

          Text(
            data.title,
            style: AppTextStyles.displayMedium.copyWith(height: 1.2),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            data.subtitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PromoData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _PromoData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}