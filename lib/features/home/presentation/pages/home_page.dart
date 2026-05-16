import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/home_bloc.dart';
import '../widgets/home_widgets.dart';
import '../../domain/entities/home_entities.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) return const _HomeLoadingSkeleton();
            if (state is HomeError)  return _HomeErrorView(message: state.message);
            if (state is HomeLoaded) return _HomeContent(state: state);
            return const SizedBox.shrink();
          },
        ),
      ),

      // AI Assistant floating button
      floatingActionButton: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is! HomeLoaded) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.paddingSM),
            child: AiAssistantFab(
              onTap: () => context.push(AppRoutes.aiAssistant),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ─────────────────────────────────────────────
//  Loaded Content
// ─────────────────────────────────────────────
class _HomeContent extends StatelessWidget {
  final HomeLoaded state;
  const _HomeContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final isSubscribed = state.user.isSubscribed;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<HomeBloc>().add(HomeLoadRequested());
      },
      child: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo + Notification
                _HomeAppBar(isSubscribed: isSubscribed),

                const SizedBox(height: AppDimens.paddingMD),

                // Greeting
                HomeHeader(
                  user: state.user,
                  onNotificationTap: () =>
                      context.push(AppRoutes.notifications),
                ),

                const SizedBox(height: AppDimens.paddingMD),

                // Banner Carousel
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

          // ── Subscribed: Quick Stats ───────────────
          if (isSubscribed && state.stats != null)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingMD),
                    child: Text('Quick Overview',
                        style: AppTextStyles.headlineSmall),
                  ),
                  const SizedBox(height: AppDimens.paddingSM),
                  HomeQuickStatsRow(stats: state.stats!),
                  const SizedBox(height: AppDimens.paddingLG),
                ],
              ),
            ),

          // ── Not Subscribed: Feature Tiles ─────────
          if (!isSubscribed)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingMD),
                    child: Text('What you get with CarePass',
                        style: AppTextStyles.headlineSmall),
                  ),
                  const SizedBox(height: AppDimens.paddingSM),
                  const HomeFeatureTiles(),
                  const SizedBox(height: AppDimens.paddingMD),
                ],
              ),
            ),

          // ── Subscribed: Quick Actions ─────────────
          if (isSubscribed)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingMD),
                    child: Text('Quick Actions',
                        style: AppTextStyles.headlineSmall),
                  ),
                  const SizedBox(height: AppDimens.paddingSM),
                  _QuickActionsGrid(),
                  const SizedBox(height: AppDimens.paddingMD),
                ],
              ),
            ),

          // ── Get Started Button (not subscribed) ───
          if (!isSubscribed)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingMD),
                child: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.payment),
                  child: const Text('Get Started'),
                ),
              ),
            ),

          // Bottom spacing for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Top App Bar
// ─────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget {
  final bool isSubscribed;
  const _HomeAppBar({required this.isSubscribed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.paddingMD, AppDimens.paddingMD, AppDimens.paddingMD, 0),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              Text(AppConstants.appName,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.primary,
                  )),
            ],
          ),
          const Spacer(),
          // Subscription badge
          if (isSubscribed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AppColors.success, size: 14),
                  const SizedBox(width: 4),
                  Text('Member',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Quick Actions Grid (subscribed users only)
// ─────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.search_outlined,           'Find Doctor', AppColors.primary,  AppRoutes.providers),
      (Icons.medical_services_outlined, 'Services',    AppColors.info,     AppRoutes.services),
      (Icons.credit_card_outlined,      'My Card',     AppColors.success,  AppRoutes.card),
      (Icons.monitor_heart_outlined,    'Checkups',    AppColors.warning,  AppRoutes.account),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMD),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        children: actions.map((a) {
          return GestureDetector(
            onTap: () => context.go(a.$4),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (a.$3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                  ),
                  child: Icon(a.$1, color: a.$3, size: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  a.$2,
                  style: AppTextStyles.labelSmall,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Loading Skeleton
// ─────────────────────────────────────────────
class _HomeLoadingSkeleton extends StatelessWidget {
  const _HomeLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppDimens.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 200, height: 24),
          SizedBox(height: 8),
          _SkeletonBox(width: 140, height: 16),
          SizedBox(height: 24),
          _SkeletonBox(width: double.infinity, height: 200),
          SizedBox(height: 24),
          _SkeletonBox(width: 160, height: 20),
          SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 72),
          SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 72),
          SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 72),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Error View
// ─────────────────────────────────────────────
class _HomeErrorView extends StatelessWidget {
  final String message;
  const _HomeErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(message,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  context.read<HomeBloc>().add(HomeLoadRequested()),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
