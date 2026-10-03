part of '../../pages/account_page.dart';

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: c)),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.textHint,
      ),
      onTap: onTap,
    );
  }
}
