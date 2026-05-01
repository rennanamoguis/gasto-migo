import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../auth/presentation/screens/get_started_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> resetAppLogin(BuildContext context) async {
    final storage = SecureStorageService();

    await storage.clearAll();
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const GetStartedScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel('Manage'),
          SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.category_rounded,
                  title: 'Categories',
                ),
                Divider(),
                _SettingsTile(
                  icon: Icons.payment_rounded,
                  title: 'Payment Methods',
                ),
                Divider(),
                _SettingsTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Accounts',
                ),
                Divider(),
                _SettingsTile(
                  icon: Icons.storefront_rounded,
                  title: 'Merchants',
                ),
              ],
            ),
          ),

          SizedBox(height: 22),

          _SectionLabel('Preferences'),
          SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.attach_money_rounded,
                  title: 'Currency',
                  trailingText: 'PHP (₱)',
                ),
                Divider(),
                _SettingsTile(
                  icon: Icons.calendar_today_rounded,
                  title: 'Date Format',
                  trailingText: 'May 20, 2025',
                ),
                Divider(),
                _SettingsTile(
                  icon: Icons.access_time_rounded,
                  title: 'Time Format',
                  trailingText: '12-hour',
                ),
              ],
            ),
          ),

          SizedBox(height: 22),

          _SectionLabel('About'),
          SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About GastoMigo',
                  trailingText: 'v1.0.0',
                ),
                Divider(),
                _SettingsTile(
                  icon: Icons.backup_rounded,
                  title: 'Backup & Restore',
                ),
                Divider(),
                _SettingsTile(
                  icon: Icons.restart_alt_rounded,
                  title: 'Reset App Login',
                  trailingText: 'Clear',
                  onTap: () => resetAppLogin(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primary,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}