import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/pin_utils.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final currentPinController = TextEditingController();
  final newPinController = TextEditingController();
  final confirmPinController = TextEditingController();

  final storage = SecureStorageService();

  bool isLoading = false;

  bool isConfirmNewPin = true;
  bool isNewPin = true;
  bool isCurrentPin = true;

  Future<void> changePin() async {
    final currentPin = currentPinController.text.trim();
    final newPin = newPinController.text.trim();
    final confirmPin = confirmPinController.text.trim();

    if (!PinUtils.isValidPin(currentPin)) {
      showMessage('Please enter your current 6-digit PIN.');
      return;
    }

    if (!PinUtils.isValidPin(newPin)) {
      showMessage('New PIN must be exactly 6 digits.');
      return;
    }

    if (newPin != confirmPin) {
      showMessage('New PIN does not match.');
      return;
    }

    if (currentPin == newPin) {
      showMessage('New PIN must be different from current PIN.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final savedHash = await storage.getPinHash();
      final savedSalt = await storage.getPinSalt();

      if (savedHash == null || savedSalt == null) {
        throw Exception('No enrolled PIN found.');
      }

      final isCurrentPinValid = PinUtils.verifyPin(
        enteredPin: currentPin,
        savedHash: savedHash,
        savedSalt: savedSalt,
      );

      if (!isCurrentPinValid) {
        throw Exception('Current PIN is incorrect.');
      }

      final newSalt = PinUtils.generateSalt();
      final newHash = PinUtils.hashPin(
        pin: newPin,
        salt: newSalt,
      );

      await storage.savePin(
        pinHash: newHash,
        pinSalt: newSalt,
      );

      if (!mounted) return;

      showMessage('PIN changed successfully.');

      Navigator.pop(context);
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    currentPinController.dispose();
    newPinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change PIN'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.lock_reset_rounded,
            color: AppTheme.primary,
            size: 72,
          ),
          const SizedBox(height: 20),
          const Text(
            'Change your 6-digit PIN',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your raw PIN is not stored. Only the new PIN hash and salt will be saved locally.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: currentPinController,
            keyboardType: TextInputType.number,
            obscureText: isCurrentPin,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Current PIN',
              counterText: '',
              prefixIcon: Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  isCurrentPin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                ),
                onPressed: () {
                  setState(() {
                    isCurrentPin = !isCurrentPin;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: newPinController,
            keyboardType: TextInputType.number,
            obscureText: isNewPin,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'New PIN',
              counterText: '',
              prefixIcon: Icon(Icons.pin_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  isNewPin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                ),
                onPressed: () {
                  setState(() {
                    isNewPin = !isNewPin;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: confirmPinController,
            keyboardType: TextInputType.number,
            obscureText: isConfirmNewPin,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Confirm New PIN',
              counterText: '',
              prefixIcon: Icon(Icons.verified_user_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  isConfirmNewPin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                ),
                onPressed: () {
                  setState(() {
                    isConfirmNewPin = !isConfirmNewPin;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: isLoading ? null : changePin,
            child: isLoading
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Save New PIN'),
          ),
        ],
      ),
    );
  }
}