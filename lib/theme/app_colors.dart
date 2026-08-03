import 'package:flutter/material.dart';

/// Shared color tokens for the redesigned UI (see 다운로드/tweenplan.png).
///
/// Every token below is a brightness-aware getter, not a compile-time
/// constant -- [syncBrightness] must be called once per frame (see
/// [TwinplaneApp]'s `builder`) before any of these are read, so widgets
/// that reference e.g. `AppColors.primary` automatically pick up the
/// right light/dark value without needing `BuildContext` threaded through
/// every call site.
class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.light;

  /// Called once per frame from [TwinplaneApp]'s MaterialApp `builder`,
  /// which always runs before this frame's widget subtree builds -- so by
  /// the time any screen reads e.g. `AppColors.primary`, it already
  /// reflects the resolved theme (including `ThemeMode.system`).
  static void syncBrightness(Brightness brightness) => _brightness = brightness;

  static bool get isDark => _brightness == Brightness.dark;

  static Color _pick(Color light, Color dark) => isDark ? dark : light;

  static Color get primary => _pick(const Color(0xFF7C5CFC), const Color(0xFF9C87FF));
  static Color get primaryLight => _pick(const Color(0xFFEEE9FF), const Color(0xFF2A2340));

  /// Page/scaffold background.
  static Color get background => _pick(const Color(0xFFF6F4FE), const Color(0xFF121018));

  /// Card/sheet background -- replaces literal `Colors.white`.
  static Color get surface => _pick(const Color(0xFFFFFFFF), const Color(0xFF1E1B27));

  /// Slightly recessed surface for fixed/non-interactive tiles -- replaces
  /// literal `Color(0xFFF7F7FA)`.
  static Color get surfaceMuted => _pick(const Color(0xFFF7F7FA), const Color(0xFF211E2B));

  /// Neutral border/stroke -- replaces literal `Color(0xFFD9D9E3)`.
  static Color get outline => _pick(const Color(0xFFD9D9E3), const Color(0xFF3A3745));

  /// Faint separator lines (timeline connector, dividers) -- replaces
  /// literal `Color(0xFFE4E1F0)`.
  static Color get divider => _pick(const Color(0xFFE4E1F0), const Color(0xFF2A2733));

  /// Default body/heading text -- replaces literal `Colors.black87`.
  static Color get textPrimary => _pick(const Color(0xFF1A1A1F), const Color(0xFFF2F1F7));

  /// Muted secondary text -- replaces literal `Colors.black54`.
  static Color get textMuted => _pick(const Color(0xFF5B5B66), const Color(0xFFB8B5C4));

  /// Card drop-shadow tint -- replaces literal `Colors.black` in `BoxShadow`.
  static Color get shadow => _pick(const Color(0xFF000000), const Color(0xFF000000));

  static Color get green => _pick(const Color(0xFF22C55E), const Color(0xFF34D399));
  static Color get greenBg => _pick(const Color(0xFFE6F8EC), const Color(0xFF163024));
  static Color get greenText => _pick(const Color(0xFF1B8A5A), const Color(0xFF4ADE80));

  static Color get orange => _pick(const Color(0xFFF97316), const Color(0xFFFB923C));
  static Color get orangeBg => _pick(const Color(0xFFFFF1E0), const Color(0xFF3A2712));

  static Color get coral => _pick(const Color(0xFFEF6C61), const Color(0xFFF2867C));
  static Color get coralBg => _pick(const Color(0xFFFDE9E7), const Color(0xFF3A2220));

  static Color get blue => _pick(const Color(0xFF3B82F6), const Color(0xFF60A5FA));
  static Color get blueBg => _pick(const Color(0xFFE8F1FE), const Color(0xFF1B2A40));

  static Color get teal => _pick(const Color(0xFF14B8A6), const Color(0xFF2DD4BF));
  static Color get tealBg => _pick(const Color(0xFFE1F5F1), const Color(0xFF103330));

  static Color get gray => _pick(const Color(0xFF6B7280), const Color(0xFF9CA3AF));
  static Color get grayBg => _pick(const Color(0xFFF0F0F3), const Color(0xFF26232E));
}

class BadgeStyle {
  final Color background;
  final Color foreground;
  const BadgeStyle(this.background, this.foreground);
}
