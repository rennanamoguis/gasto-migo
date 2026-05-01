import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GastoMigo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Good morning!',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Here’s your overview',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AmountBlock(
                  label: 'Today',
                  amount: '₱560.75',
                  large: true,
                ),
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: const [
              Expanded(
                child: AppCard(
                  child: _AmountBlock(
                    label: 'This Week',
                    amount: '₱2,345.10',
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  child: _AmountBlock(
                    label: 'This Month',
                    amount: '₱9,870.50',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'View all',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const _TransactionPreviewTile(
            icon: Icons.storefront_rounded,
            title: 'Alturas Grocery',
            subtitle: 'Today, 8:45 AM',
            amount: '₱560.75',
            color: AppTheme.primary,
          ),
          const _TransactionPreviewTile(
            icon: Icons.local_convenience_store_rounded,
            title: '7-Eleven',
            subtitle: 'Yesterday, 6:20 PM',
            amount: '₱145.00',
            color: AppTheme.secondary,
          ),
          const _TransactionPreviewTile(
            icon: Icons.local_pharmacy_rounded,
            title: 'Mercury Drug',
            subtitle: 'May 18, 2025',
            amount: '₱320.50',
            color: AppTheme.info,
          ),
          const _TransactionPreviewTile(
            icon: Icons.fastfood_rounded,
            title: 'Jollibee',
            subtitle: 'May 18, 2025',
            amount: '₱235.00',
            color: AppTheme.error,
          ),
        ],
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  final String label;
  final String amount;
  final bool large;

  const _AmountBlock({
    required this.label,
    required this.amount,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: large ? 26 : 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TransactionPreviewTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color color;

  const _TransactionPreviewTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}