import 'package:flutter/material.dart';
import 'package:gastomigo/features/auth/presentation/screens/splash_screen.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import 'app_shell.dart';

class GastoMigoApp extends StatelessWidget {
  const GastoMigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}