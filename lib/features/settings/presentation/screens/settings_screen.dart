import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../auth/presentation/screens/get_started_screen.dart';
import '../../data/settings_repository.dart';

import 'about_screen.dart';
import 'accounts_screen.dart';
import 'backup_restore_screen.dart';
import 'categories_screen.dart';
import 'change_pin_screen.dart';
import 'currency_screen.dart';
import 'merchants_screen.dart';
import 'payment_methods_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const SettingsScreen({
    super.key,
    this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final settingsRepository = SettingsRepository();
  final storage = SecureStorageService();

  String currencyCode = 'PHP';
  String currencySymbol = '₱';

  String fullName = 'GastoMigo User';
  String email = 'No email available';

  @override
  void initState() {
    super.initState();
    loadSettingsSummary();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final storedFullName = await storage.getFullName();
    final storedEmail = await storage.getEmail();

    if (!mounted) return;

    setState(() {
      fullName = storedFullName?.isNotEmpty == true
          ? storedFullName!
          : 'GastoMigo User';

      email = storedEmail?.isNotEmpty == true
          ? storedEmail!
          : 'No email available';
    });
  }

  Future<void> loadSettingsSummary() async {
    final preferences = await settingsRepository.getPreferences();

    if (!mounted) return;

    setState(() {
      currencyCode = preferences.currencyCode;
      currencySymbol = preferences.currencySymbol;
    });
  }

  Future<void> resetAppLogin(BuildContext context) async {
    await storage.clearAll();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const GetStartedScreen()),
          (route) => false,
    );
  }

  Future<void> confirmResetAppLogin(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset App Login?'),
          content: const Text(
            'This will clear your local account session and PIN. Your local expenses will remain on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      await resetAppLogin(context);
    }
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty || fullName == 'GastoMigo User') {
      return 'G';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Widget _buildUserInfoCard() {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          const Icon(
            Icons.verified_user_rounded,
            color: AppTheme.primary,
            size: 24,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          _buildUserInfoCard(),

          const SizedBox(height: 22),

          const _SectionLabel('Manage'),

          const SizedBox(height: 8),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.category_rounded,
                  title: 'Categories',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoriesScreen(),
                      ),
                    );

                    widget.onSettingsChanged?.call();
                  },
                ),

                const Divider(height: 1),

                _SettingsTile(
                  icon: Icons.payment_rounded,
                  title: 'Payment Methods',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PaymentMethodsScreen(),
                      ),
                    );

                    widget.onSettingsChanged?.call();
                  },
                ),

                const Divider(height: 1),

                _SettingsTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Accounts',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountsScreen(),
                      ),
                    );

                    widget.onSettingsChanged?.call();
                  },
                ),

                const Divider(height: 1),

                _SettingsTile(
                  icon: Icons.storefront_rounded,
                  title: 'Merchants',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MerchantsScreen(),
                      ),
                    );

                    widget.onSettingsChanged?.call();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const _SectionLabel('Preferences'),

          const SizedBox(height: 8),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.attach_money_rounded,
                  title: 'Currency',
                  trailingText: '$currencySymbol $currencyCode',
                  onTap: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CurrencyScreen(),
                      ),
                    );

                    if (result == true) {
                      await loadSettingsSummary();
                      widget.onSettingsChanged?.call();
                    }
                  },
                ),

                const Divider(height: 1),

                const _SettingsTile(
                  icon: Icons.calendar_today_rounded,
                  title: 'Date Format',
                  trailingText: 'May 20, 2025',
                ),

                const Divider(height: 1),

                const _SettingsTile(
                  icon: Icons.access_time_rounded,
                  title: 'Time Format',
                  trailingText: '12-hour',
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const _SectionLabel('About'),

          const SizedBox(height: 8),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About GastoMigo',
                  trailingText: 'v1.0.0',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(),
                      ),
                    );
                  },
                ),

                const Divider(height: 1),

                _SettingsTile(
                  icon: Icons.backup_rounded,
                  title: 'Backup & Restore',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BackupRestoreScreen(),
                      ),
                    );
                  },
                ),

                const Divider(height: 1),

                _SettingsTile(
                  icon: Icons.lock_reset_rounded,
                  title: 'Change PIN',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePinScreen(),
                      ),
                    );
                  },
                ),

                const Divider(height: 1),

                _SettingsTile(
                  icon: Icons.restart_alt_rounded,
                  title: 'Reset App Login',
                  trailingText: 'Clear',
                  onTap: () => confirmResetAppLogin(context),
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
      minVerticalPadding: 14,
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
          if (trailingText != null) ...[
            Text(
              trailingText!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
          ],
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