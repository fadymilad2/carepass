part of '../../pages/services_page.dart';

class _ProviderOfferingTile extends StatefulWidget {
  final ServiceEntity service;
  final bool isBest;

  const _ProviderOfferingTile({required this.service, this.isBest = false});

  @override
  State<_ProviderOfferingTile> createState() => _ProviderOfferingTileState();
}

class _ProviderOfferingTileState extends State<_ProviderOfferingTile> {
  bool _loading = false;

  Future<void> _open(BuildContext context) async {
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(widget.service.providerId)
          .get();

      if (!context.mounted) return;
      setState(() => _loading = false);

      if (doc.exists) {
        final provider = MedicalProviderModel.fromFirestore(
          doc.data()!,
          doc.id,
        );
        Navigator.pop(context); // close sheet
        context.push('/providers/detail', extra: provider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider not found'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Text(
          widget.service.providerName.isNotEmpty
              ? widget.service.providerName[0].toUpperCase()
              : '?',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
        ),
      ),
      title: Text(widget.service.providerName, style: AppTextStyles.bodyMedium),
      subtitle: Row(
        children: [
          Text(
            'Up to ${widget.service.discountPercent}% off',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
          ),
          if (widget.isBest) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
              child: Text(
                'Best discount',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textHint,
            ),
      onTap: _loading ? null : () => _open(context),
    );
  }
}
