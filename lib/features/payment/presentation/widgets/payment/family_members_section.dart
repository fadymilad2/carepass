part of '../../pages/payment_page.dart';

class _FamilyMembersSection extends StatelessWidget {
  final List<FamilyMember> members;
  final int maxMembers;
  final bool loading;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const _FamilyMembersSection({
    required this.members,
    required this.maxMembers,
    required this.loading,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLG),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.group_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Family Members', style: AppTextStyles.titleMedium),
              const Spacer(),
              Text(
                '${members.length}/$maxMembers',
                style: AppTextStyles.bodySmall.copyWith(
                  color: members.length >= maxMembers
                      ? AppColors.warning
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            'Add up to $maxMembers family members to your plan.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 12),

          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (members.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimens.radiusMD),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    color: AppColors.textHint,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No family members added yet.\n'
                      'Tap "Add Member" to include your family.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // ✅ Uses the shared tile from family_member_widgets.dart
            ...members.map(
              (m) =>
                  FamilyMemberTile(member: m, onRemove: () => onRemove(m.id)),
            ),

          const SizedBox(height: 12),

          if (members.length < maxMembers)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Member'),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Discount Section
// ─────────────────────────────────────────────
