part of '../../pages/services_page.dart';

class _ServiceGroupListItem extends StatefulWidget {
  final ServiceGroup group;
  const _ServiceGroupListItem({required this.group});

  @override
  State<_ServiceGroupListItem> createState() => _ServiceGroupListItemState();
}

class _ServiceGroupListItemState extends State<_ServiceGroupListItem> {
  bool _isLoading = false;
  double? _nearestDistance;
  bool _hasLoadedDistance = false;

  static final Map<String, Future<double?>> _cache = {};

  @override
  void initState() {
    super.initState();
    _fetchNearestDistance();
  }

  @override
  void didUpdateWidget(covariant _ServiceGroupListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.group.offerings.map((o) => o.providerId).toSet();
    final newIds = widget.group.offerings.map((o) => o.providerId).toSet();
    if (oldIds.length != newIds.length || !oldIds.containsAll(newIds)) {
      _hasLoadedDistance = false;
      _nearestDistance = null;
      _fetchNearestDistance();
    }
  }

  // ✅ Distance to the NEAREST provider among all offering this service
  Future<void> _fetchNearestDistance() async {
    try {
      final futures = widget.group.offerings.map((o) {
        final pid = o.providerId;
        _cache[pid] ??= _fromFirestore(pid);
        return _cache[pid]!;
      });

      final results = await Future.wait(futures);
      final valid = results.whereType<double>().toList();

      if (mounted) {
        setState(() {
          _nearestDistance = valid.isEmpty
              ? null
              : valid.reduce((a, b) => a < b ? a : b);
          _hasLoadedDistance = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasLoadedDistance = true);
    }
  }

  static Future<double?> _fromFirestore(String pid) async {
    final doc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(pid)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['latitude'] == null || data['longitude'] == null) return null;
    const uLat = 5.6037, uLng = -0.1870;
    return Geolocator.distanceBetween(
          uLat,
          uLng,
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        ) /
        1000;
  }

  Future<void> _handleTap() async {
    final offerings = widget.group.offerings;

    // ✅ Only one provider offers this — go straight to their page
    if (offerings.length == 1) {
      setState(() => _isLoading = true);
      try {
        final doc = await FirebaseFirestore.instance
            .collection('providers')
            .doc(offerings.first.providerId)
            .get();
        if (!mounted) return;
        setState(() => _isLoading = false);
        if (doc.exists) {
          final provider = MedicalProviderModel.fromFirestore(
            doc.data()!,
            doc.id,
          );
          context.push('/providers/detail', extra: provider);
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    // ✅ Multiple providers — show comparison sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceProvidersSheet(group: widget.group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.radiusMD),
          onTap: _isLoading ? null : _handleTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSM),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : group.hasImage
                      ? CachedNetworkImage(
                          imageUrl: group.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Icon(
                            group.categoryIcon,
                            color: AppColors.primary,
                            size: 26,
                          ),
                          errorWidget: (_, _, _) => Icon(
                            group.categoryIcon,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        )
                      : Icon(
                          group.categoryIcon,
                          color: AppColors.primary,
                          size: 26,
                        ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Up to ${group.maxDiscountPercent}% off',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          if (group.hasMultipleProviders) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusFull,
                                ),
                              ),
                              child: Text(
                                '${group.providerCount} providers',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ] else
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(
                                  'at ${group.offerings.first.providerName}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      !_hasLoadedDistance
                          ? '...'
                          : (_nearestDistance != null
                                ? '${_nearestDistance!.toStringAsFixed(1)} km'
                                : '-- km'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textHint,
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

// ─────────────────────────────────────────────
//  Compare-providers bottom sheet (multi-provider only)
// ─────────────────────────────────────────────
