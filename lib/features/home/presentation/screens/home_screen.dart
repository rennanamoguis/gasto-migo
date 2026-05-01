import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../repositories/transaction_repository.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onViewAllTransactions;
  final VoidCallback? onAddTransaction;

  const HomeScreen({
    super.key,
    this.onViewAllTransactions,
    this.onAddTransaction,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final transactionRepository = TransactionRepository();

  bool isLoading = true;
  String? errorMessage;

  int todayTotal = 0;
  int weekTotal = 0;
  int monthTotal = 0;
  List<Map<String, dynamic>> recentTransactions = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final today = await transactionRepository.getTodayTotal();
      final week = await transactionRepository.getWeekTotal();
      final month = await transactionRepository.getMonthTotal();
      final recent = await transactionRepository.getRecentTransactions(limit: 5);

      if (!mounted) return;

      setState(() {
        todayTotal = today;
        weekTotal = week;
        monthTotal = month;
        recentTransactions = recent;
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('GastoMigo'),
        ),
        body: const LoadingView(message: 'Loading dashboard...'),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('GastoMigo'),
        ),
        body: EmptyStateView(
          icon: Icons.error_outline_rounded,
          title: 'Unable to load dashboard',
          message: errorMessage!,
          actionLabel: 'Try Again',
          onActionPressed: loadDashboard,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('GastoMigo'),
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: ListView(
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
              'Here’s your spending overview',
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
                    amount: MoneyUtils.centavosToPesoText(todayTotal),
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
              children: [
                Expanded(
                  child: AppCard(
                    child: _AmountBlock(
                      label: 'This Week',
                      amount: MoneyUtils.centavosToPesoText(weekTotal),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    child: _AmountBlock(
                      label: 'This Month',
                      amount: MoneyUtils.centavosToPesoText(monthTotal),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton(
                  onPressed: widget.onViewAllTransactions,
                  child: const Text('View all'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (recentTransactions.isEmpty)
              AppCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: AppTheme.primary,
                      size: 46,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No transactions yet',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Add your first expense transaction to see it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (widget.onAddTransaction != null) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: widget.onAddTransaction,
                        child: const Text('Add Transaction'),
                      ),
                    ],
                  ],
                ),
              )
            else
              ...recentTransactions.map(
                    (transaction) => _TransactionPreviewTile(
                  title: _getTransactionTitle(transaction),
                  subtitle: _getTransactionSubtitle(transaction),
                  amount: MoneyUtils.centavosToPesoText(
                    _readInt(transaction['total_amount']),
                  ),
                  itemCount: _readInt(transaction['item_count']),
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

  String _getTransactionSubtitle(Map<String, dynamic> transaction) {
    final date = transaction['transaction_date']?.toString() ?? '';
    final time = transaction['transaction_time']?.toString();

    if (time == null || time.isEmpty) {
      return date;
    }

    return '$date, $time';
  }

  int _readInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
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
  final String title;
  final String subtitle;
  final String amount;
  final int itemCount;

  const _TransactionPreviewTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storefront_rounded,
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
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$subtitle • $itemCount item${itemCount == 1 ? '' : 's'}',
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
      ),
    );
  }
}