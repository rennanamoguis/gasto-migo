import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About GastoMigo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          AppCard(
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppTheme.primary,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'GastoMigo',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Daily Expenses Tracker',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          AppCard(
            child: Text(
              'GastoMigo is a local-first mobile app for recording daily expenses with itemized transactions. It supports offline PIN login after account setup and stores expenses locally using SQLite.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}