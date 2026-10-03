part of '../../pages/providers_page.dart';

class _ProvidersHeader extends StatelessWidget {
  final String area;
  final VoidCallback onLocationTap;

  const _ProvidersHeader({required this.area, required this.onLocationTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.go('/home'),
            padding: EdgeInsets.zero,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  area.isEmpty ? 'All Providers' : 'Providers in $area',
                  style: AppTextStyles.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                GestureDetector(
                  onTap: onLocationTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_location_alt_outlined,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        area.isEmpty ? 'Select area to filter' : 'Change area',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.location_on, color: AppColors.primary),
            onPressed: onLocationTap,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Area Picker ✅ With GPS-outside-network warning
// ─────────────────────────────────────────────
