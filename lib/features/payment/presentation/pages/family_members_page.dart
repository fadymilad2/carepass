import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../payment/domain/entities/payment_entities.dart';
import '../../../payment/presentation/widgets/family_member_widgets.dart';

part '../widgets/family_members/not_family_plan_view.dart';

class FamilyMembersPage extends StatefulWidget {
  const FamilyMembersPage({super.key});

  @override
  State<FamilyMembersPage> createState() => _FamilyMembersPageState();
}

class _FamilyMembersPageState extends State<FamilyMembersPage> {
  bool _loading = true;
  bool _isFamilyPlan = false;
  String? _planName;
  int _maxMembers = 4;
  List<FamilyMember> _members = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final data = userDoc.data()!;
      final subscriptionType =
          (data['subscriptionType'] as String? ?? 'individual').toLowerCase();
      final planName = data['planName'] as String?;
      final rawMembers = data['familyMembers'] as List<dynamic>? ?? [];

      int maxMembers = 4;
      if (planName != null) {
        final planDoc = await FirebaseFirestore.instance
            .collection('subscription_plans')
            .doc(planName)
            .get();
        if (planDoc.exists && planDoc.data() != null) {
          maxMembers = planDoc.data()!['maxFamilyMembers'] as int? ?? 4;
        }
      }

      if (mounted) {
        setState(() {
          _isFamilyPlan = subscriptionType == 'family';
          _planName = planName;
          _maxMembers = maxMembers;
          _members = rawMembers
              .map(
                (m) =>
                    FamilyMember.fromMap(Map<String, dynamic>.from(m as Map)),
              )
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'familyMembers': _members.map((m) => m.toMap()).toList(),
      });
    } catch (_) {}
  }

  void _showAddDialog() {
    if (_members.length >= _maxMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum $_maxMembers family members allowed for this plan',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AddFamilyMemberDialog(
        onAdd: (m) {
          setState(() => _members.add(m));
          _save();
        },
      ),
    );
  }

  void _removeMember(String id) {
    setState(() => _members.removeWhere((m) => m.id == id));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Family Members')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : !_isFamilyPlan
          ? const _NotFamilyPlanView()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimens.paddingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.cardGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.group_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_planName ?? 'Family'} Plan',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${_members.length}/$_maxMembers members added',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text('Members', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 10),

                    if (_members.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMD,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.people_outline,
                              color: AppColors.textHint,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No family members yet',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._members.map(
                        (m) => FamilyMemberTile(
                          member: m,
                          onRemove: () => _removeMember(m.id),
                        ),
                      ),

                    const SizedBox(height: 16),

                    if (_members.length < _maxMembers)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Member'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
