part of '../../pages/home_page.dart';

class _HomeAppBar extends StatelessWidget {
  final bool isSubscribed;
  const _HomeAppBar({required this.isSubscribed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.paddingMD,
        AppDimens.paddingMD,
        AppDimens.paddingMD,
        0,
      ),
      child: Row(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('settings')
                .doc('app_config')
                .snapshots(),
            builder: (context, snap) {
              final data = snap.data?.data() as Map<String, dynamic>?;
              final logoUrl = data?['logoUrl'] as String?;

              if (logoUrl != null && logoUrl.isNotEmpty) {
                return Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl: logoUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const _DefaultLogoIcon(),
                      errorWidget: (_, _, _) => const _DefaultLogoIcon(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppConstants.appName,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );
              }

              return Text(
                AppConstants.appName,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),

          const Spacer(),

          if (isSubscribed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified,
                    color: AppColors.success,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Member',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
