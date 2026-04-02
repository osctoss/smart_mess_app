import 'package:flutter/material.dart';

class AppColors {
  // ── Primary Backgrounds ──
  static const Color scaffoldDark = Color(0xFF0F0F1A);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252540);

  // ── Accent Colors ──
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentAmber = Color(0xFFFFB347);
  static const Color accentTeal = Color(0xFF00D9A6);
  static const Color accentRose = Color(0xFFFF4D6D);
  static const Color accentBlue = Color(0xFF4DA8FF);

  // ── Text Colors ──
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFF9090A7);
  static const Color textMuted = Color(0xFF5A5A72);

  // ── Semantic Colors ──
  static const Color success = accentTeal;
  static const Color danger = accentRose;
  static const Color warning = accentAmber;
  static const Color info = accentBlue;

  // ── Glass Effect ──
  static Color glassBackground = Colors.white.withValues(alpha: 0.05);
  static Color glassBorder = Colors.white.withValues(alpha: 0.10);
  static Color glassHighlight = Colors.white.withValues(alpha: 0.08);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentOrange, accentRose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [accentTeal, Color(0xFF00B4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [accentBlue, Color(0xFF6C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [accentAmber, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scaffoldGradient = LinearGradient(
    colors: [scaffoldDark, Color(0xFF16162A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Legacy Aliases (backward compat) ──
  static const Color primary = accentOrange;
  static const Color primaryVariant = Color(0xFFE55A2B);
  static const Color secondary = accentTeal;
  static const Color background = scaffoldDark;
  static const Color surface = surfaceDark;
  static const Color error = accentRose;
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = textPrimary;
  static const Color onSurface = textPrimary;
  static const Color onError = Colors.white;
}
