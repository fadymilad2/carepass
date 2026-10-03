part of '../../pages/payment_page.dart';

class _DiscountSection extends StatelessWidget {
  final PaymentPlansLoaded state;
  final TextEditingController codeCtrl;
  final bool isVisible;
  final VoidCallback onToggle;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  const _DiscountSection({
    required this.state,
    required this.codeCtrl,
    required this.isVisible,
    required this.onToggle,
    required this.onApply,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = state.appliedDiscount != null;
    final hasError = state.discountError != null;
    final loading = state.isValidatingCode;

    if (hasDiscount) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.successSurface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer, color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${state.appliedDiscount!.code} applied!',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    state.appliedDiscount!.type == 'percent'
                        ? '${state.appliedDiscount!.value.toInt()}% discount'
                        : 'GHS ${state.appliedDiscount!.value.toStringAsFixed(2)} off',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.close,
                color: AppColors.success,
                size: 18,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_offer_outlined,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isVisible ? 'Hide discount code' : 'Have a discount code?',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Icon(
                isVisible ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.primary,
                size: 16,
              ),
            ],
          ),
        ),

        if (isVisible) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Enter code (e.g. SAVE20)',
                    prefixIcon: const Icon(
                      Icons.confirmation_number_outlined,
                      size: 18,
                    ),
                    errorText: hasError ? state.discountError : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : onApply,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 0),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Order Summary
// ─────────────────────────────────────────────
