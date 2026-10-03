part of '../../pages/providers_page.dart';

class _ProvidersList extends StatelessWidget {
  final List<MedicalProvider> providers;
  final String area;

  const _ProvidersList({required this.providers, required this.area});

  Future<void> _openDirection(
    BuildContext context,
    MedicalProvider provider,
  ) async {
    Uri uri;

    if (provider.latitude != null && provider.longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${provider.latitude},${provider.longitude}'
        '&travelmode=driving',
      );
    } else if (provider.address.isNotEmpty) {
      final encoded = Uri.encodeComponent(
        '${provider.address}, ${provider.area}, Ghana',
      );
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encoded',
      );
    } else {
      final encoded = Uri.encodeComponent(
        '${provider.name}, ${provider.area}, Ghana',
      );
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encoded',
      );
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('No providers found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => context.read<ProvidersBloc>().add(
        ProvidersLoadRequested(ProvidersFilter(area: area)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${providers.length} providers found',
              style: AppTextStyles.bodySmall,
            ),
          ),
          ...providers.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProviderListTile(
                    provider: p,
                    onTap: () => context.push('/providers/detail', extra: p),
                    onFavoriteTap: () => context.read<ProvidersBloc>().add(
                      ProviderFavoriteToggled(p.id),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        left: BorderSide(color: AppColors.border),
                        right: BorderSide(color: AppColors.border),
                        bottom: BorderSide(color: AppColors.border),
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: TextButton.icon(
                      onPressed: () => _openDirection(context, p),
                      icon: const Icon(
                        Icons.directions_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        'Get Directions',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Sort Sheet
// ─────────────────────────────────────────────
