part of '../../pages/home_page.dart';

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppDimens.radiusMD),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Error View
// ─────────────────────────────────────────────
