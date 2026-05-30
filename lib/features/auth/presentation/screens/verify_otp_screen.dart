import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../repositories/auth_repository.dart';
import 'enroll_pin_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String fullName;
  final String email;

  const VerifyOtpScreen({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final otpController = TextEditingController();

  final authRepository = AuthRepository();
  final storage = SecureStorageService();

  bool isLoading = false;
  bool isResending = false;

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      showMessage('Please enter the 6-digit verification code.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await authRepository.verifyOtp(
        email: widget.email,
        otp: otp,
      );

      final user = result['user'];

      final userId = user['id'].toString();
      final fullName = user['full_name'];
      final email = user['email'];

      await storage.saveUser(
        firebaseUid: userId,
        fullName: fullName,
        email: email,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EnrollPinScreen(
            firebaseUid: userId,
            fullName: fullName,
            email: email,
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

  Future<void> resendOtp() async {
    setState(() => isResending = true);

    try {
      await authRepository.requestOtp(
        fullName: widget.fullName,
        email: widget.email,
      );

      showMessage('Verification code sent again.');
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => isResending = false);
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
      appBar: AppBar(title: const Text('Verify Email')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            height: 88,
            width: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: AppTheme.primary,
              size: 48,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Enter verification code',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'We sent a 6-digit verification code to ${widget.email}.',
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
                : const Text('Verify and Continue'),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: isResending ? null : resendOtp,
            child: Text(
              isResending ? 'Sending...' : 'Resend Verification Code',
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