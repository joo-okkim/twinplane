import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/app_colors.dart';

/// The single themed MaterialApp shell, reused for every state AuthGate can
/// be in (login, error, loading, or the fully-authenticated app) via [home]
/// -- there is exactly one MaterialApp/Navigator instance active at a time,
/// never nested, so whichever provider tree wraps this (see
/// screens/twinplane_root.dart) is always an ancestor of this app's
/// Navigator/Overlay. That matters: showModalBottomSheet/showDialog insert
/// into the Overlay, which only inherits from providers *above* the
/// Navigator, not from providers declared inside one specific route.
class TwinplaneApp extends StatelessWidget {
  const TwinplaneApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'NotoSansKR',
      ),
      home: home,
    );
  }
}
