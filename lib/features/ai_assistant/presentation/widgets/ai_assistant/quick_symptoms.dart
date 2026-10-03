part of '../../pages/ai_assistant_page.dart';

class _QuickSymptoms extends StatelessWidget {
  final ValueChanged<String> onSelect;
  const _QuickSymptoms({required this.onSelect});

  static const _symptoms = [
    'Headache and fever',
    'Chest pain',
    'Stomach pain',
    'Sore throat',
    'Back pain',
    'Skin rash',
    'Shortness of breath',
    'Joint pain',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _symptoms.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onSelect(_symptoms[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(_symptoms[i], style: AppTextStyles.bodySmall),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Input Bar
// ─────────────────────────────────────────────
