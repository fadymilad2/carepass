import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class HealthChecksSection extends StatefulWidget {
  const HealthChecksSection({super.key});

  @override
  State<HealthChecksSection> createState() => _HealthChecksSectionState();
}

class _HealthChecksSectionState extends State<HealthChecksSection> {
  final _db = FirebaseFirestore.instance;
  bool _loading = true;

  int _bpLimit = 1;
  int _sugarLimit = 1;
  int _bpUsed = 0;
  int _sugarUsed = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final results = await Future.wait([
        _db.collection('settings').doc('app_config').get(),
        _db.collection('users').doc(uid).get(),
      ]);

      final settings = results[0].data() ?? {};
      final userData = results[1].data() ?? {};

      if (!mounted) return;
      setState(() {
        _bpLimit = settings['bloodPressureChecksPerMonth'] ?? 1;
        _sugarLimit = settings['bloodSugarChecksPerMonth'] ?? 1;

        final currentMonth = DateFormat(
          'yyyy-MM',
        ).format(DateTime.now().toUtc());
        final storedMonth = userData['checksResetMonth'] ?? '';

        if (storedMonth != currentMonth) {
          _bpUsed = 0;
          _sugarUsed = 0;
        } else {
          _bpUsed = userData['bpChecksUsedThisMonth'] ?? 0;
          _sugarUsed = userData['sugarChecksUsedThisMonth'] ?? 0;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _bpRemaining => (_bpLimit - _bpUsed).clamp(0, _bpLimit);
  int get _sugarRemaining => (_sugarLimit - _sugarUsed).clamp(0, _sugarLimit);

  Future<void> _onCheckTap(BuildContext context, String type) async {
    final remaining = type == 'blood_pressure' ? _bpRemaining : _sugarRemaining;

    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have used all your checks for this month.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isBloodPressure = type == 'blood_pressure';

    // ── Confirmation Dialog ──────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isBloodPressure
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isBloodPressure
                      ? Icons.favorite_outlined
                      : Icons.water_drop_outlined,
                  color: isBloodPressure ? AppColors.error : AppColors.warning,
                  size: 32,
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                isBloodPressure ? 'Blood Pressure Check' : 'Blood Sugar Check',
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Warning box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Important Notice',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This card will be shown once only. '
                      'This check will be counted as used.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Only tap "Continue" when you are at the healthcare provider.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Continue
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _recordUsage(type);
    } on FirebaseFunctionsException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Unable to record this check.')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    context.push(AppRoutes.healthCheck, extra: type);

    await _loadData();
  }

  Future<void> _recordUsage(String type) async {
    await FirebaseFunctions.instance
        .httpsCallable('recordHealthCheck')
        .call<void>({'type': type});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Free Health Checks', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Resets monthly — use at any partner provider',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          _HealthCheckTile(
            icon: Icons.favorite_outlined,
            label: 'Blood Pressure',
            sublabel: 'قياس الضغط',
            color: AppColors.error,
            remaining: _bpRemaining,
            total: _bpLimit,
            onTap: () => _onCheckTap(context, 'blood_pressure'),
          ),

          const SizedBox(height: 10),

          _HealthCheckTile(
            icon: Icons.water_drop_outlined,
            label: 'Blood Sugar',
            sublabel: 'قياس السكر',
            color: AppColors.warning,
            remaining: _sugarRemaining,
            total: _sugarLimit,
            onTap: () => _onCheckTap(context, 'blood_sugar'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Health Check Tile
// ─────────────────────────────────────────────
class _HealthCheckTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final int remaining;
  final int total;
  final VoidCallback onTap;

  const _HealthCheckTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.remaining,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasRemaining = remaining > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        child: InkWell(
          onTap: hasRemaining ? onTap : null,
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
          child: Padding(
            padding: const EdgeInsets.all(16),
            // ✅ كل حاجة مفرودة في Row واحد ومتسنترة في النص
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Icon Box ──
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),

                const SizedBox(width: 14),

                // ── Title ──
                // خد المساحة الفاضية كلها وزق الباقي يمين
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                // ── Dots ──
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    total,
                    (i) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: i < remaining
                            ? color
                            : color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // ── Badge (1/1 left) ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: hasRemaining
                        ? color.withValues(alpha: 0.1)
                        : AppColors.border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    '$remaining/$total left',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: hasRemaining ? color : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // ── Arrow ──
                Icon(
                  hasRemaining
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.lock_outline_rounded,
                  size: 14,
                  color: AppColors.textHint.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
