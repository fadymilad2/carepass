part of '../../pages/home_page.dart';

class _DefaultLogoIcon extends StatelessWidget {
  const _DefaultLogoIcon();
  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.favorite, color: Colors.white, size: 20),
  );
}

// ─────────────────────────────────────────────
//  Quick Actions Grid ✅ "Checkups" removed
// ─────────────────────────────────────────────
