import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage_service.dart';
import 'get_started_screen.dart';
import 'pin_login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final storage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    checkAuthState();
  }

  Future<void> checkAuthState() async {
    final hasPin = await storage.hasPinEnrolled();

    if (!mounted) return;

    if (hasPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PinLoginScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GetStartedScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
