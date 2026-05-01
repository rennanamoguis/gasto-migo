import 'package:flutter/material.dart';

import '../../../../app/app_shell.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/pin_utils.dart';
import '../../../../repositories/auth_repository.dart';

class EnrollPinScreen extends StatefulWidget {
  final String firebaseUid;
  final String fullName;
  final String email;

  const EnrollPinScreen({
    super.key,
    required this.firebaseUid,
    required this.fullName,
    required this.email,
  });

  @override
  State<EnrollPinScreen> createState() => _EnrollPinScreenState();
}

class _EnrollPinScreenState extends State<EnrollPinScreen> {
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();

  final storage = SecureStorageService();
  final authRepository = AuthRepository();

  bool isLoading = false;

  Future<void> enrollPin() async {
    final pin = pinController.text.trim();
    final confirmPin = confirmPinController.text.trim();

    if (!PinUtils.isValidPin(pin)) {
      showMessage('PIN must be exactly 6 digits.');
      return;
    }

    if (pin != confirmPin) {
      showMessage('PIN does not match.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final salt = PinUtils.generateSalt();
      final hash = PinUtils.hashPin(
        pin: pin,
        salt: salt,
      );

      await storage.saveUser(
        firebaseUid: widget.firebaseUid,
        fullName: widget.fullName,
        email: widget.email,
      );

      await storage.savePin(
        pinHash: hash,
        pinSalt: salt,
      );

      /*
        Backend connection will be enabled in a later phase.

        await authRepository.completePinEnrollmentOnServer();
      */

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
            (route) => false,
      );
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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
    confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Create PIN'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Create your 6-digit PIN',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'You will use this PIN to open the app even when offline.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: '6-digit PIN',
              counterText: '',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: confirmPinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Confirm PIN',
              counterText: '',
              prefixIcon: Icon(Icons.verified_user_outlined),
            ),
          ),

          const SizedBox(height: 28),

          FilledButton(
            onPressed: isLoading ? null : enrollPin,
            child: isLoading
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Save PIN'),
          ),

          const SizedBox(height: 16),

          const Text(
            'Your raw PIN will not be saved. Only a secure PIN hash and salt are stored locally.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}