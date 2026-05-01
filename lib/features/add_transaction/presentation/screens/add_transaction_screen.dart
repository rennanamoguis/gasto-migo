import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _FormRow(
            label: 'Date',
            value: 'May 20, 2025',
            icon: Icons.calendar_today_rounded,
          ),
          const _FormRow(
            label: 'Time',
            value: '9:30 AM',
            icon: Icons.access_time_rounded,
          ),
          const _FormRow(
            label: 'Merchant',
            value: 'Alturas Grocery',
            icon: Icons.chevron_right_rounded,
          ),
          const _FormRow(
            label: 'Payment Method',
            value: 'Cash',
            icon: Icons.chevron_right_rounded,
          ),
          const _FormRow(
            label: 'Account',
            value: 'Wallet',
            icon: Icons.chevron_right_rounded,
          ),

          const SizedBox(height: 12),

          TextField(
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Add notes here',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Item'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const AppCard(
            child: Column(
              children: [
                _ItemPreviewRow(
                  name: 'Rice',
                  detail: '1 kg x ₱120.00',
                  amount: '₱120.00',
                ),
                Divider(),
                _ItemPreviewRow(
                  name: 'Coffee',
                  detail: '1 pc x ₱250.00',
                  amount: '₱250.00',
                ),
                Divider(),
                _ItemPreviewRow(
                  name: 'Bread',
                  detail: '1 pc x ₱45.00',
                  amount: '₱45.00',
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          AppCard(
            child: Column(
              children: const [
                _SummaryRow(label: 'Subtotal', amount: '₱415.00'),
                SizedBox(height: 8),
                _SummaryRow(label: 'Discount', amount: '₱0.00'),
                SizedBox(height: 8),
                _SummaryRow(label: 'Tax', amount: '₱0.00'),
                SizedBox(height: 8),
                _SummaryRow(label: 'Extra', amount: '₱0.00'),
                Divider(height: 24),
                _SummaryRow(
                  label: 'Total (3 items)',
                  amount: '₱560.75',
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _FormRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            icon,
            size: 18,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _ItemPreviewRow extends StatelessWidget {
  final String name;
  final String detail;
  final String amount;

  const _ItemPreviewRow({
    required this.name,
    required this.detail,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.drag_handle_rounded,
          color: AppTheme.textSecondary,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
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
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}