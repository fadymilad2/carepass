part of '../../pages/home_page.dart';

class _HomeContent extends StatelessWidget {
  final HomeLoaded state;
  const _HomeContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final isSubscribed = state.user.isSubscribed;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => context.read<HomeBloc>().add(HomeLoadRequested()),
      child: CustomScrollView(
        slivers: [
          // ── AppBar + Greeting + Banner ──────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeAppBar(isSubscribed: isSubscribed),
                const SizedBox(height: AppDimens.paddingMD),
                HomeHeader(
                  user: state.user,
                  onNotificationTap: () =>
                      context.push(AppRoutes.notifications),
                ),
                const SizedBox(height: AppDimens.paddingMD),
                HomeBannerCarousel(
                  banners: state.banners,
                  isLoading: state.isBannersLoading,
                  isSubscribed: isSubscribed,
                  onSubscribeTap: () => context.push(AppRoutes.payment),
                ),
                const SizedBox(height: AppDimens.paddingLG),
              ],
            ),
          ),

          // ── Popular Services (للجميع) ────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                HomePopularServices(
                  services: state.services,
                  onSeeMore: () => context.go(AppRoutes.services),
                ),
                const SizedBox(height: AppDimens.paddingLG),
              ],
            ),
          ),

          // ── Nearby Providers (للجميع) ────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                HomeNearbyProviders(
                  providers: state.providers,
                  hasError: state.hasProvidersError,
                  isLoading: state.isProvidersLoading,
                  onRetry: () =>
                      context.read<HomeBloc>().add(HomeLoadRequested()),
                  onSeeMore: () => context.go(AppRoutes.providers),
                ),
                const SizedBox(height: AppDimens.paddingLG),
              ],
            ),
          ),

          // ── Quick Actions (للمشتركين فقط) ────────
          if (isSubscribed)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingMD,
                    ),
                    child: Text(
                      'Quick Actions',
                      style: AppTextStyles.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: AppDimens.paddingSM),
                  _QuickActionsGrid(),
                  const SizedBox(height: AppDimens.paddingMD),
                ],
              ),
            ),

          // ── Feature Tiles (لغير المشتركين) ──────
          if (!isSubscribed)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingMD,
                    ),
                    child: Text(
                      'What you get with CarePass',
                      style: AppTextStyles.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: AppDimens.paddingSM),
                  const HomeFeatureTiles(),
                  const SizedBox(height: AppDimens.paddingMD),
                ],
              ),
            ),

          // ── Get Started (لغير المشتركين) ────────
          if (!isSubscribed)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingMD),
                child: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.payment),
                  child: Text(
                    'Get Started',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ),

          // ── Bottom spacing ──────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  App Bar with dynamic logo from Firestore
// ─────────────────────────────────────────────
