import 'package:flutter/material.dart';

/// Shared color tokens for the redesigned UI (see 다운로드/tweenplan.png).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF7C5CFC);
  static const Color primaryLight = Color(0xFFEEE9FF);

  static const Color background = Color(0xFFF6F4FE);

  static const Color green = Color(0xFF22C55E);
  static const Color greenBg = Color(0xFFE6F8EC);
  static const Color greenText = Color(0xFF1B8A5A);

  static const Color orange = Color(0xFFF97316);
  static const Color orangeBg = Color(0xFFFFF1E0);

  static const Color coral = Color(0xFFEF6C61);
  static const Color coralBg = Color(0xFFFDE9E7);

  static const Color blue = Color(0xFF3B82F6);
  static const Color blueBg = Color(0xFFE8F1FE);

  static const Color teal = Color(0xFF14B8A6);
  static const Color tealBg = Color(0xFFE1F5F1);

  static const Color gray = Color(0xFF6B7280);
  static const Color grayBg = Color(0xFFF0F0F3);
}

class BadgeStyle {
  final Color background;
  final Color foreground;
  const BadgeStyle(this.background, this.foreground);
}
