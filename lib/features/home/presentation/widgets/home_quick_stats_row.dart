import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/home_entities.dart';

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
