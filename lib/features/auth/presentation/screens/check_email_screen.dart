import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../repositories/auth_repository.dart';
import 'enroll_pin_screen.dart';

class CheckEmailScreen extends StatefulWidget {
  final String fullName;
  final String email;

  const CheckEmailScreen({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  final linkController = TextEditingController();

  final authRepository = AuthRepository();
  final storage = SecureStorageService();

  bool isLoading = false;
  bool isResending = false;

  Future<void> completeVerification() async {
    final link = linkController.text.trim();

    if (link.isEmpty) {
      showMessage('Please paste the verification link from your email.');
      return;
    }

    if (!authRepository.isSignInWithEmailLink(link)) {
      showMessage('Invalid Firebase verification link.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = await authRepository.completeEmailLinkSignIn(
        email: widget.email,
        emailLink: link,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('Unable to sign in with Firebase.');
      }

      final result = await authRepository.saveVerifiedProfile(
        fullName: widget.fullName,
      );

      final user = result['user'];

      await storage.saveUser(
        firebaseUid: user['firebase_uid'],
        fullName: user['full_name'],
        email: user['email'],
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EnrollPinScreen(
            firebaseUid: user['firebase_uid'],
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

  Future<void> resendLink() async {
    setState(() => isResending = true);

    try {
      await authRepository.sendEmailVerificationLink(email: widget.email);

      showMessage('Verification link sent again.');
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
    linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Check Your Email')),
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
            'Verification link sent',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'We sent a Firebase verification link to ${widget.email}. Open the email, copy the full link, then paste it below.',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          TextField(
            controller: linkController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Paste verification link',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 70),
                child: Icon(Icons.link_rounded),
              ),
            ),
          ),

          const SizedBox(height: 24),

          FilledButton(
            onPressed: isLoading ? null : completeVerification,
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Continue'),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: isResending ? null : resendLink,
            child: Text(
              isResending ? 'Sending...' : 'Resend Verification Link',
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'For this MVP, paste-link verification is used first. App Links / Universal Links can be added later so tapping the email link opens the app automatically.',
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
