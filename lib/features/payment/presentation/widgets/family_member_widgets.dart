import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/payment_entities.dart';

// ─────────────────────────────────────────────
//  ✅ Shared Family Member Tile
//  Used by both the Payment page (while choosing a Family
//  plan) and the dedicated Family Members page reachable
//  from the Card tab — one definition, no duplication.
// ─────────────────────────────────────────────
class FamilyMemberTile extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback? onRemove;

  const FamilyMemberTile({super.key, required this.member, this.onRemove});

  String _formatDob(String iso) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: AppTextStyles.bodyMedium),
                Row(
                  children: [
                    Text(
                      member.relationshipLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (member.dateOfBirth != null &&
                        member.dateOfBirth!.isNotEmpty) ...[
                      Text(
                        ' · ',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                      Text(
                        _formatDob(member.dateOfBirth!),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (member.phoneNumber != null &&
                    member.phoneNumber!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 11,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        member.phoneNumber!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.error,
                size: 20,
              ),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ✅ Shared Add Family Member Dialog
// ─────────────────────────────────────────────
class AddFamilyMemberDialog extends StatefulWidget {
  final ValueChanged<FamilyMember> onAdd;
  const AddFamilyMemberDialog({super.key, required this.onAdd});

  @override
  State<AddFamilyMemberDialog> createState() => _AddFamilyMemberDialogState();
}

class _AddFamilyMemberDialogState extends State<AddFamilyMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _relationship = 'spouse';
  DateTime? _dob;
  bool _dobError = false;

  static const _relationships = [
    {'value': 'spouse', 'label': 'Spouse'},
    {'value': 'child', 'label': 'Child'},
    {'value': 'parent', 'label': 'Parent'},
    {'value': 'sibling', 'label': 'Sibling'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _dobError = false;
      });
    }
  }

  void _handleAdd() {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      setState(() => _dobError = true);
      return;
    }
    final member = FamilyMember(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      relationship: _relationship,
      dateOfBirth: _dob!.toIso8601String().split('T')[0],
      phoneNumber: _phoneCtrl.text.trim().isEmpty
          ? null
          : _phoneCtrl.text.trim(),
    );
    widget.onAdd(member);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Family Member', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                Text('Relationship *', style: AppTextStyles.bodySmall),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _relationship,
                  onChanged: (v) =>
                      setState(() => _relationship = v ?? 'spouse'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                  items: _relationships
                      .map(
                        (r) => DropdownMenuItem(
                          value: r['value'],
                          child: Text(r['label']!),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Phone (optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _pickDob,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.cake_outlined,
                        color: _dobError ? AppColors.error : AppColors.textHint,
                      ),
                      errorText: _dobError ? 'Date of birth is required' : null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                        borderSide: BorderSide(
                          color: _dob == null
                              ? AppColors.border
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    child: Text(
                      _dob == null
                          ? 'Date of Birth *'
                          : DateFormat('dd MMM yyyy').format(_dob!),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _dob == null
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleAdd,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
