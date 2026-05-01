import 'package:flutter/material.dart';

import '../../../../app/app_shell.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/pin_utils.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final pinController = TextEditingController();
  final storage = SecureStorageService();

  String fullName = '';

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final name = await storage.getFullName();

    if (!mounted) return;

    setState(() {
      fullName = name ?? '';
    });
  }

  Future<void> login() async {
    final enteredPin = pinController.text.trim();

    if (!PinUtils.isValidPin(enteredPin)) {
      showMessage('Please enter your 6-digit PIN.');
      return;
    }

    final savedHash = await storage.getPinHash();
    final savedSalt = await storage.getPinSalt();

    if (savedHash == null || savedSalt == null) {
      showMessage('No PIN enrolled.');
      return;
    }

    final isValid = PinUtils.verifyPin(
      enteredPin: enteredPin,
      savedHash: savedHash,
      savedSalt: savedSalt,
    );

    if (!isValid) {
      showMessage('Incorrect PIN.');
      return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final greeting = fullName.isEmpty ? 'Welcome back' : 'Hello, $fullName';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),

            Container(
              height: 88,
              width: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),

            const SizedBox(height: 28),

            Text(
              greeting,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Enter your 6-digit PIN to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 32),

            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                labelText: 'PIN',
                counterText: '',
              ),
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: login,
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}