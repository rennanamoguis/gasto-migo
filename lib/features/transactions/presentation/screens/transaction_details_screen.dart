import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../repositories/transaction_repository.dart';
import 'edit_transaction_screen.dart';
import '../../../../core/utils/app_format_utils.dart';
import '../../../../models/app_preferences.dart';
import '../../../../features/settings/data/settings_repository.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final int transactionId;
  final VoidCallback? onChanged;

  const TransactionDetailsScreen({
    super.key,
    required this.transactionId,
    this.onChanged,
  });

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final transactionRepository = TransactionRepository();
  final settingsRepository = SettingsRepository();

  AppPreferences preferences = AppPreferences.defaults();

  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? transaction;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    loadDetails();
  }

  Future<void> loadDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedPreferences = await settingsRepository.getPreferences();
      final loadedTransaction =
      await transactionRepository.getTransactionById(widget.transactionId);
      final loadedItems = await transactionRepository.getItemsByTransactionId(
        widget.transactionId,
      );

      if (!mounted) return;

      setState(() {
        transaction = loadedTransaction;
        preferences = loadedPreferences;
        items = loadedItems;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction?'),
          content: const Text(
            'This transaction will be removed from your list. This action can be synced later as a soft delete.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await transactionRepository.softDeleteTransaction(widget.transactionId);

      widget.onChanged?.call();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction deleted.')));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> openEditScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditTransactionScreen(transactionId: widget.transactionId),
      ),
    );

    if (result == true) {
      widget.onChanged?.call();
      await loadDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Transaction Details')),
        body: LoadingView(message: 'Loading transaction...'),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Details')),
        body: EmptyStateView(
          icon: Icons.error_outline_rounded,
          title: 'Unable to load transaction',
          message: errorMessage!,
          actionLabel: 'Try Again',
          onActionPressed: loadDetails,
        ),
      );
    }

    if (transaction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Details')),
        body: const EmptyStateView(
          icon: Icons.receipt_long_rounded,
          title: 'Transaction not found',
          message: 'This transaction may have been deleted.',
        ),
      );
    }

    final title = _getTransactionTitle(transaction!);
    final date = transaction!['transaction_date']?.toString() ?? '';
    final time = transaction!['transaction_time']?.toString() ?? '';
    final formattedDateTime = AppFormatUtils.formatDateTime(
      date: date,
      time: time,
      dateFormat: preferences.dateFormat,
      timeFormat: preferences.timeFormat,
    );
    final paymentMethod = transaction!['payment_method_name']?.toString() ?? '';
    final account = transaction!['account_name']?.toString() ?? '';
    final notes = transaction!['notes']?.toString();

    final subtotal = _readInt(transaction!['subtotal_amount']);
    final discount = _readInt(transaction!['discount_amount']);
    final tax = _readInt(transaction!['tax_amount']);
    final extra = _readInt(transaction!['extra_amount']);
    final total = _readInt(transaction!['total_amount']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            onPressed: openEditScreen,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: confirmDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.error,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadDetails,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedDateTime,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    MoneyUtils.formatAmount(
                      total,
                      currencySymbol: preferences.currencySymbol,
                    ),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            AppCard(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.payment_rounded,
                    label: 'Payment Method',
                    value: paymentMethod.isEmpty ? 'Not set' : paymentMethod,
                  ),
                  const Divider(height: 22),
                  _InfoRow(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Account',
                    value: account.isEmpty ? 'Not set' : account,
                  ),
                  if (notes != null && notes.trim().isNotEmpty) ...[
                    const Divider(height: 22),
                    _InfoRow(
                      icon: Icons.notes_rounded,
                      label: 'Notes',
                      value: notes,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Items',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 10),

            if (items.isEmpty)
              const AppCard(
                child: Text(
                  'No items found for this transaction.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else
              AppCard(
                child: Column(
                  children: [
                    for (int index = 0; index < items.length; index++) ...[
                      _ItemDetailsRow(
                        item: items[index],
                        currencySymbol: preferences.currencySymbol,
                      ),
                      if (index != items.length - 1) const Divider(height: 22),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 18),

            AppCard(
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Subtotal',
                    amount: MoneyUtils.formatAmount(
                      subtotal,
                      currencySymbol: preferences.currencySymbol,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Discount',
                    amount: MoneyUtils.formatAmount(
                      discount,
                      currencySymbol: preferences.currencySymbol,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Tax',
                    amount: MoneyUtils.formatAmount(
                      tax,
                      currencySymbol: preferences.currencySymbol,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Extra',
                    amount: MoneyUtils.formatAmount(
                      extra,
                      currencySymbol: preferences.currencySymbol,
                    ),
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Total',
                    amount: MoneyUtils.formatAmount(
                      total,
                      currencySymbol: preferences.currencySymbol,
                    ),
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTransactionTitle(Map<String, dynamic> transaction) {
    final merchantName = transaction['merchant_name'];
    final title = transaction['title'];

    if (merchantName != null && merchantName.toString().trim().isNotEmpty) {
      return merchantName.toString();
    }

    return title?.toString() ?? 'Untitled Transaction';
  }

  int _readInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemDetailsRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final String currencySymbol;

  const _ItemDetailsRow({required this.item,required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final name = item['item_name']?.toString() ?? 'Unnamed Item';
    final category = item['category_name']?.toString();
    final quantity = item['quantity']?.toString() ?? '1';
    final unit = item['unit']?.toString() ?? '';
    final unitPrice = _readInt(item['unit_price_amount']);
    final subtotal = _readInt(item['subtotal_amount']);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.shopping_bag_outlined,
            color: AppTheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 3),
              Text(
                '$quantity $unit x ${MoneyUtils.formatAmount(
                  unitPrice,
                  currencySymbol: currencySymbol,
                )}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (category != null && category.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  category,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          MoneyUtils.formatAmount(
            subtotal,
            currencySymbol: currencySymbol,
          ),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  int _readInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
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
