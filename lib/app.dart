import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/theme_mode_controller.dart';
import 'theme/app_colors.dart';

/// The single themed MaterialApp shell, reused for every state AuthGate can
/// be in (login, error, loading, or the fully-authenticated app) via [home]
/// -- there is exactly one MaterialApp/Navigator instance active at a time,
/// never nested, so whichever provider tree wraps this (see
/// screens/twinplane_root.dart) is always an ancestor of this app's
/// Navigator/Overlay. That matters: showModalBottomSheet/showDialog insert
/// into the Overlay, which only inherits from providers *above* the
/// Navigator, not from providers declared inside one specific route.
///
/// Owns [ThemeModeController] itself (rather than requiring it from an
/// ancestor) so light/dark/system works even pre-login, on the screens
/// AuthGate renders directly without TwinplaneRoot's provider tree. It's
/// exposed to [home] via [ChangeNotifierProvider] so the 마이 tab's toggle
/// can reach it with `context.read`.
class TwinplaneApp extends StatefulWidget {
  const TwinplaneApp({super.key, required this.home});

  final Widget home;

  @override
  State<TwinplaneApp> createState() => _TwinplaneAppState();
}

class _TwinplaneAppState extends State<TwinplaneApp> {
  final ThemeModeController _themeModeController = ThemeModeController();

  @override
  void initState() {
    super.initState();
    _themeModeController.load();
  }

  ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C5CFC), brightness: brightness),
      scaffoldBackgroundColor: isDark ? const Color(0xFF121018) : const Color(0xFFF6F4FE),
      cardColor: isDark ? const Color(0xFF1E1B27) : Colors.white,
      fontFamily: 'NotoSansKR',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeModeController>.value(
      value: _themeModeController,
      child: Consumer<ThemeModeController>(
        builder: (context, controller, _) {
          return MaterialApp(
            title: 'AI Teacher',
            debugShowCheckedModeBanner: false,
            locale: const Locale('ko', 'KR'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ko', 'KR')],
            themeMode: controller.mode,
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            builder: (context, child) {
              // Keeps AppColors' static getters in sync with the *resolved*
              // brightness (respects ThemeMode.system) before this frame's
              // subtree builds -- see AppColors.syncBrightness's doc comment.
              AppColors.syncBrightness(Theme.of(context).brightness);
              return child!;
            },
            home: widget.home,
          );
        },
      ),
    );
  }
}
