import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDecorations {
  /// Standard glass card decoration
  static BoxDecoration glassDecoration({
    double borderRadius = 20,
    Color? borderColor,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColors.glassBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppColors.glassBorder,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Gradient button decoration
  static BoxDecoration gradientDecoration({
    double borderRadius = 16,
    LinearGradient? gradient,
  }) {
    return BoxDecoration(
      gradient: gradient ?? AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: AppColors.accentOrange.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  /// Input field decoration
  static BoxDecoration inputDecoration({
    double borderRadius = 16,
    bool isFocused = false,
  }) {
    return BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isFocused ? AppColors.accentOrange : AppColors.glassBorder,
        width: isFocused ? 1.5 : 1,
      ),
    );
  }

  /// Card with colored accent stripe on the left
  static BoxDecoration accentStripeDecoration({
    required Color accentColor,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      color: AppColors.glassBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.glassBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  /// Circular gradient for avatars / icons
  static BoxDecoration circularGradient({
    required LinearGradient gradient,
    double size = 48,
  }) {
    return BoxDecoration(
      gradient: gradient,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: gradient.colors.first.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
