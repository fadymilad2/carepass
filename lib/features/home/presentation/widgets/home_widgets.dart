import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/home_entities.dart';

// ─────────────────────────────────────────────
//  Home Header Widget
// ─────────────────────────────────────────────
class HomeHeader extends StatelessWidget {
  final UserSummary user;
  final VoidCallback onNotificationTap;

  const HomeHeader({
    super.key,
    required this.user,
    required this.onNotificationTap,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingMD,
        vertical: AppDimens.paddingSM,
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primarySurface,
            backgroundImage: user.photoUrl != null
                ? CachedNetworkImageProvider(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? Text(
                    user.firstName.isNotEmpty
                        ? user.firstName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting, style: AppTextStyles.bodySmall),
                Text(
                  user.firstName,
                  style: AppTextStyles.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Notification bell
          IconButton(
            onPressed: onNotificationTap,
            icon: const Icon(Icons.notifications_outlined),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Banner Carousel
// ─────────────────────────────────────────────
class HomeBannerCarousel extends StatefulWidget {
  final List<HomeBanner> banners;
  final bool isLoading;
  final bool isSubscribed;
  final VoidCallback onSubscribeTap;

  const HomeBannerCarousel({
    super.key,
    required this.banners,
    this.isLoading = false,
    required this.isSubscribed,
    required this.onSubscribeTap,
  });

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return const _BannerShimmer();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return _BannerCard(
                banner: banner,
                isSubscribed: widget.isSubscribed,
                onSubscribeTap: widget.onSubscribeTap,
              );
            },
          ),
        ),
        // Dots indicator
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentPage ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final HomeBanner banner;
  final bool isSubscribed;
  final VoidCallback onSubscribeTap;

  const _BannerCard({
    required this.banner,
    required this.isSubscribed,
    required this.onSubscribeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image or gradient
            banner.imageUrl.startsWith('assets/')
                ? Image.asset(banner.imageUrl, fit: BoxFit.cover)
                : CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _BannerPlaceholderGradient(),
                    errorWidget: (_, _, _) =>
                        const _BannerPlaceholderGradient(),
                  ),

            // Dark overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.black.withOpacity(0.65),
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Discount badge (for provider banners)
                  if (banner.discountPercent != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusFull,
                        ),
                      ),
                      child: Text(
                        'Up to ${banner.discountPercent}% off',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Text(
                    banner.title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: Colors.white,
                    ),
                    maxLines: 2,
                  ),
                  if (banner.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      banner.subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                    ),
                  ],
                  // CTA for non-subscribed
                  if (!isSubscribed) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: onSubscribeTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusFull,
                          ),
                        ),
                        child: Text(
                          'Subscribe Now',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerPlaceholderGradient extends StatelessWidget {
  const _BannerPlaceholderGradient();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _BannerShimmer extends StatelessWidget {
  const _BannerShimmer();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMD),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusLG),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Feature Tiles (Discounted, Trusted, etc.)
//  Shown only for non-subscribed users
// ─────────────────────────────────────────────
class HomeFeatureTiles extends StatelessWidget {
  const HomeFeatureTiles({super.key});

  static const _features = [
    (
      Icons.local_offer_outlined,
      'Discounted Services',
      'Save up to 50% on medical services',
    ),
    (
      Icons.verified_outlined,
      'Trusted Providers',
      'Wide network of clinics and hospitals',
    ),
    (
      Icons.credit_card_outlined,
      'Easy Subscription',
      'Simple plans, cancel anytime',
    ),
    (
      Icons.favorite_border_rounded,
      'Your Health, Our Priority',
      'Healthcare made affordable',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMD),
      child: Column(
        children: _features.map((f) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.paddingSM),
            child: Container(
              padding: const EdgeInsets.all(AppDimens.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                    ),
                    child: Icon(f.$1, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.$2, style: AppTextStyles.titleMedium),
                        const SizedBox(height: 2),
                        Text(f.$3, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Quick Stats Row (for subscribed users)
// ─────────────────────────────────────────────
class HomeQuickStatsRow extends StatelessWidget {
  final HomeQuickStat stats;

  const HomeQuickStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMD),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.location_on_outlined,
            value: '${stats.nearbyProviders}',
            label: 'Nearby\nProviders',
            color: AppColors.primary,
          ),
          const SizedBox(width: AppDimens.paddingSM),
          _StatCard(
            icon: Icons.medical_services_outlined,
            value: '${stats.availableServices}',
            label: 'Available\nServices',
            color: AppColors.info,
          ),
          const SizedBox(width: AppDimens.paddingSM),
          _StatCard(
            icon: Icons.monitor_heart_outlined,
            value: '${stats.checkupsRemaining}',
            label: 'Checkups\nLeft',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTextStyles.headlineMedium.copyWith(color: color),
            ),
            Text(
              label,
              style: AppTextStyles.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  AI Assistant FAB
// ─────────────────────────────────────────────
class AiAssistantFab extends StatefulWidget {
  final VoidCallback onTap;

  const AiAssistantFab({super.key, required this.onTap});

  @override
  State<AiAssistantFab> createState() => _AiAssistantFabState();
}

class _AiAssistantFabState extends State<AiAssistantFab> {
  bool _isExpanded = false;

  void _toggleExpand(bool expand) {
    if (_isExpanded != expand) {
      setState(() => _isExpanded = expand);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // للتحكم في التمدد عند مرور الماوس (Hover)
      onEnter: (_) => _toggleExpand(true),
      onExit: (_) => _toggleExpand(false),
      child: GestureDetector(
        onTap: widget.onTap,
        // للتحكم في التمدد عند الضغط المطول في شاشات اللمس (الموبايل)
        onLongPressDown: (_) => _toggleExpand(true),
        onLongPressUp: () => _toggleExpand(false),
        onLongPressCancel: () => _toggleExpand(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: _isExpanded ? 20 : 16,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.cardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.medical_information_outlined,
                color: Colors.white,
                size: 24,
              ),
              ClipRRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            Text(
                              'AI Health Assistant',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
