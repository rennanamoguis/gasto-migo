import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../repositories/auth_repository.dart';
import 'reset_pin_screen.dart';

class ForgotPinOtpScreen extends StatefulWidget {
  final String email;

  const ForgotPinOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<ForgotPinOtpScreen> createState() => _ForgotPinOtpScreenState();
}

class _ForgotPinOtpScreenState extends State<ForgotPinOtpScreen> {
  final otpController = TextEditingController();

  final authRepository = AuthRepository();
  final storage = SecureStorageService();

  bool isLoading = false;
  bool isResending = false;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    setState(() => isResending = true);

    try {
      await authRepository.requestForgotPinOtp(
        email: widget.email,
      );

      showMessage('PIN reset code sent to your email.');
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => isResending = false);
      }
    }
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      showMessage('Please enter the 6-digit verification code.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await authRepository.verifyForgotPinOtp(
        email: widget.email,
        otp: otp,
      );

      final user = result['user'];

      await storage.saveUser(
        firebaseUid: user['id'].toString(),
        fullName: user['full_name'],
        email: user['email'],
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPinScreen(
            userId: user['id'].toString(),
            fullName: user['full_name'],
            email: user['email'],
          ),
        ),
      );
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Forgot PIN')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.lock_reset_rounded,
            color: AppTheme.primary,
            size: 72,
          ),

          const SizedBox(height: 24),

          const Text(
            'Verify your email',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'We sent a 6-digit PIN reset code to ${widget.email}.',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
            ),
            decoration: const InputDecoration(
              labelText: '6-digit code',
              counterText: '',
              prefixIcon: Icon(Icons.password_rounded),
            ),
          ),

          const SizedBox(height: 24),

          FilledButton(
            onPressed: isLoading ? null : verifyOtp,
            child: isLoading
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Verify and Reset PIN'),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: isResending ? null : _sendOtp,
            child: Text(
              isResending ? 'Sending...' : 'Resend Code',
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'The verification code expires after 10 minutes.',
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