import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

enum BadgeVariant { success, warning, danger, info }

class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.variant,
    this.icon,
  });

  Color get _color {
    switch (variant) {
      case BadgeVariant.success:
        return AppColors.accentTeal;
      case BadgeVariant.warning:
        return AppColors.accentAmber;
      case BadgeVariant.danger:
        return AppColors.accentRose;
      case BadgeVariant.info:
        return AppColors.accentBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: _color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
