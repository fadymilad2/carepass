part of '../../pages/home_page.dart';

class _HomeLoadingSkeleton extends StatelessWidget {
  const _HomeLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppDimens.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 200, height: 24),
          SizedBox(height: 8),
          _SkeletonBox(width: 140, height: 16),
          SizedBox(height: 24),
          _SkeletonBox(width: double.infinity, height: 200),
          SizedBox(height: 24),
          _SkeletonBox(width: 160, height: 20),
          SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 72),
          SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 72),
        ],
      ),
    );
  }
}
