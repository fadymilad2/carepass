import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/card_bloc.dart';
import '../../domain/entities/card_entities.dart';

class CardPage extends StatefulWidget {
  const CardPage({super.key});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  @override
  void initState() {
    super.initState();
    context.read<CardBloc>().add(CardLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Card')),
      body: BlocBuilder<CardBloc, CardState>(
        builder: (context, state) {
          if (state is CardLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is CardError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(state.message,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context
                        .read<CardBloc>()
                        .add(CardLoadRequested()),
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
    );
  }
}

class _CardContent extends StatelessWidget {
  final HealthCard card;
  const _CardContent({required this.card});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Digital Card ──────────────────────
          _DigitalCard(card: card),

          const SizedBox(height: 24),

          // ── Card Status ───────────────────────
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingMD),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusLG),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('Card Status',
                        style: AppTextStyles.titleMedium),
                    const Spacer(),
                    _StatusBadge(status: card.status),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Valid Until',
                            style: AppTextStyles.bodySmall),
                        const SizedBox(height: 4),
                        Text(card.validUntilFormatted,
                            style: AppTextStyles.headlineSmall),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusMD),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Show this card to enjoy your discounts',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Benefits ──────────────────────────
          if (card.benefits.isNotEmpty) ...[
            ...card.benefits.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BenefitCard(benefit: b),
                )),
          ],

          const SizedBox(height: 16),

          // ── Quick Actions ─────────────────────
          Text('Quick Actions', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.grid_view_outlined,
                  label: 'View Services',
                  onTap: () => context.go('/services'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.location_on_outlined,
                  label: 'Find Providers',
                  onTap: () => context.go('/providers'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Digital Card Widget
// ─────────────────────────────────────────────
class _DigitalCard extends StatelessWidget {
  final HealthCard card;
  const _DigitalCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background heart ECG decoration
          Positioned(
            right: -20, top: -20,
            child: Icon(
              Icons.monitor_heart_outlined,
              size: 180,
              color: Colors.white.withOpacity(0.08),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo row
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text('CarePass',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: Colors.white,
                          letterSpacing: 0.5,
                        )),
                  ],
                ),

                const Spacer(),

                // Member Name
                Text('Member Name',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white60,
                    )),
                const SizedBox(height: 2),
                Text(
                  card.memberName.isEmpty ? 'Member' : card.memberName,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // Member ID + Valid Thru
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Member ID',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white60,
                            )),
                        const SizedBox(height: 2),
                        Text(card.memberId,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              letterSpacing: 1,
                            )),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Valid Thru',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white60,
                            )),
                        const SizedBox(height: 2),
                        Text(card.validThruFormatted,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                            )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Status Badge
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final CardStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case CardStatus.active:    return AppColors.success;
      case CardStatus.expired:   return AppColors.error;
      case CardStatus.pending:   return AppColors.warning;
      case CardStatus.suspended: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: _color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Benefit Card
// ─────────────────────────────────────────────
class _BenefitCard extends StatelessWidget {
  final CardBenefit benefit;
  const _BenefitCard({required this.benefit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        border: Border.all(
          color: benefit.hasRemaining
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimens.radiusSM),
            ),
            child: const Icon(Icons.monitor_heart_outlined,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(benefit.title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(benefit.description,
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.circle,
                        size: 8, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('You have ',
                        style: AppTextStyles.bodySmall),
                    Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${benefit.remaining}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('check remaining',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Quick Action
// ─────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.labelLarge),
          ],
        ),
      ),
    );
  }
}