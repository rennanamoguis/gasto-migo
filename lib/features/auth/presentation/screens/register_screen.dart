import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../repositories/auth_repository.dart';
import 'check_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();

  final authRepository = AuthRepository();

  bool isLoading = false;

  Future<void> sendLink() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim().toLowerCase();

    if (fullName.isEmpty || email.isEmpty) {
      showMessage('Please enter your full name and email.');
      return;
    }

    if (!email.contains('@')) {
      showMessage('Please enter a valid email address.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await authRepository.sendEmailVerificationLink(email: email);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckEmailScreen(
            fullName: fullName,
            email: email,
          ),
        ),
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
    fullNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Register your account',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Enter your full name and email. We will send a Firebase verification link to your email.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          TextField(
            controller: fullNameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),

          const SizedBox(height: 28),

          FilledButton(
            onPressed: isLoading ? null : sendLink,
            child: isLoading
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Send Verification Link'),
          ),

          const SizedBox(height: 16),

          const Text(
            'You must verify your email before enrolling your offline PIN.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}