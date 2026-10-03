import 'package:carepass/core/router/app_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../services/presentation/bloc/services_bloc.dart';
import '../../domain/entities/provider_entities.dart';

part '../widgets/provider_detail/badge.dart';
part '../widgets/provider_detail/action_button.dart';
part '../widgets/provider_detail/info_section.dart';

class ProviderDetailPage extends StatefulWidget {
  final MedicalProvider provider;
  const ProviderDetailPage({super.key, required this.provider});

  @override
  State<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends State<ProviderDetailPage> {
  bool _isFavorite = false;

  Future<void> _launchPhone() async {
    final uri = Uri.parse('tel:${widget.provider.phoneNumber}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchMaps() async {
    final lat = widget.provider.latitude ?? 5.6037;
    final lng = widget.provider.longitude ?? -0.1870;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchWebsite() async {
    if (widget.provider.website == null) return;
    final uri = Uri.parse(widget.provider.website!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _onBookNow(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.push(AppRoutes.login);
      return;
    }
    context.push(AppRoutes.bookNow, extra: widget.provider);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero Image + AppBar ────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: _isFavorite
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                ),
                onPressed: () => setState(() => _isFavorite = !_isFavorite),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: p.imageUrl.isNotEmpty
                  ? Image.network(p.imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.primarySurface,
                      child: const Icon(
                        Icons.local_hospital,
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),

          // ── Content ───────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + Name
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.local_hospital,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: AppTextStyles.headlineSmall),
                              Text(p.typeLabel, style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Rating + Distance
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${p.rating} (${p.reviewCount} reviews)',
                          style: AppTextStyles.bodySmall,
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(p.distanceLabel, style: AppTextStyles.bodySmall),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Badges
                    Row(
                      children: [
                        _Badge(
                          label: p.discountLabel,
                          color: AppColors.primary,
                        ),
                        if (p.isInNetwork) ...[
                          const SizedBox(width: 8),
                          const _Badge(
                            label: 'In Network',
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.phone_outlined,
                            label: 'Call',
                            subtitle: p.phoneNumber,
                            onTap: _launchPhone,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.directions_outlined,
                            label: 'Directions',
                            subtitle: p.distanceLabel,
                            onTap: _launchMaps,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.language_outlined,
                            label: 'Website',
                            subtitle: 'Visit site',
                            onTap: _launchWebsite,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Address ───────────────────────────
          SliverToBoxAdapter(
            child: _InfoSection(
              title: 'Address',
              icon: Icons.location_on_outlined,
              child: Text(p.address, style: AppTextStyles.bodyMedium),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Working Hours ─────────────────────
          SliverToBoxAdapter(
            child: _InfoSection(
              title: 'Working Hours',
              icon: Icons.access_time_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.workingHours.weekdays.isNotEmpty)
                    Text(
                      p.workingHours.weekdays,
                      style: AppTextStyles.bodyMedium,
                    ),
                  if (p.workingHours.friday.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      p.workingHours.friday,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Services Offered ──────────────────
          SliverToBoxAdapter(
            child: _InfoSection(
              title: 'Services Offered',
              icon: Icons.medical_services_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: p.services
                        .take(6)
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusFull,
                              ),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(s, style: AppTextStyles.bodySmall),
                          ),
                        )
                        .toList(),
                  ),
                  if (p.totalServices > 6) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      child: Text(
                        'View all (${p.totalServices})',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Services Section ─────────────────────────────
          SliverToBoxAdapter(
            child: BlocProvider(
              create: (context) =>
                  sl<ServicesBloc>()..add(ServicesLoadByProvider(p.id)),
              child: BlocBuilder<ServicesBloc, ServicesState>(
                builder: (context, state) {
                  if (state is ServicesLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }

                  if (state is! ServicesLoaded || state.all.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimens.paddingMD,
                          8,
                          AppDimens.paddingMD,
                          8,
                        ),
                        child: Text(
                          'Available Services',
                          style: AppTextStyles.headlineSmall,
                        ),
                      ),

                      ...state.all.map(
                        (service) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingMD,
                            vertical: 4,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusMD,
                              ),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusSM,
                                    ),
                                  ),
                                  child: Icon(
                                    service.categoryIcon,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.name,
                                        style: AppTextStyles.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        service.categoryLabel,
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusFull,
                                    ),
                                  ),
                                  child: Text(
                                    '${service.discountPercent}% off',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppDimens.paddingMD),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── Book Now button spacing ────────────
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // ── Book Now ──────────────────────────────
      // ابحث عن الـ bottomNavigationBar وبدّله بالكامل:
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: ElevatedButton.icon(
          onPressed: () => _onBookNow(context),
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: const Text('Book Now'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Badge
// ─────────────────────────────────────────────
