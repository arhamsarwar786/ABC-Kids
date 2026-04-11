import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import '../core/utils/app_colors.dart';

class AbcKidsApp extends StatelessWidget {
  const AbcKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: AppColors.transparent,
        systemNavigationBarDividerColor: AppColors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        title: 'ABC Kids Learning',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
