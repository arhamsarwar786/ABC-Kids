import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../features/shared/widgets/ad_slot.dart';
import '../features/shared/widgets/kid_safe_banner.dart';
import '../features/shell/main_shell.dart';
import '../features/welcome/welcome_screen.dart';
import '../state/settings_store.dart';
import 'theme/app_theme.dart';

class AbcKidsApp extends StatefulWidget {
  const AbcKidsApp({super.key});

  @override
  State<AbcKidsApp> createState() => _AbcKidsAppState();
}

class _AbcKidsAppState extends State<AbcKidsApp> {
  final _adRoutes = AdRouteTracker();

  @override
  void dispose() {
    _adRoutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>().settings;
    return ChangeNotifierProvider<AdRouteTracker>.value(
      value: _adRoutes,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        title: 'ABC Kids',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorObservers: [_adRoutes],
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          // Respect system text size; "larger text" adds 20% on top, capped.
          final scaler = settings.largerText
              ? TextScaler.linear((mq.textScaler.scale(1) * 1.2).clamp(1.0, 2.2))
              : mq.textScaler.clamp(maxScaleFactor: 2.0);
          return MediaQuery(
            data: mq.copyWith(textScaler: scaler, disableAnimations: mq.disableAnimations || settings.reduceMotion),
            child: AdFrame(child: child!),
          );
        },
        home: settings.firstRunComplete ? const MainShell() : const WelcomeScreen(),
      ),
    ));
  }
}
