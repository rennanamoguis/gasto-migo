import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../repositories/transaction_repository.dart';

class TransactionsScreen extends StatefulWidget {
  final VoidCallback? onAddTransaction;

  const TransactionsScreen({
    super.key,
    this.onAddTransaction,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final transactionRepository = TransactionRepository();
  final searchController = TextEditingController();

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];

  String selectedFilter = 'All';

  final filters = const [
    'All',
    'Today',
    'This Week',
    'This Month',
  ];

  @override
  void initState() {
    super.initState();
    searchController.addListener(applyFilters);
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await transactionRepository.getTransactions();

      if (!mounted) return;

      setState(() {
        transactions = result;
        isLoading = false;
      });

      applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  void applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    final monthPrefix =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );

    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final startWeekText = startOfWeek.toIso8601String().substring(0, 10);
    final endWeekText = endOfWeek.toIso8601String().substring(0, 10);

    List<Map<String, dynamic>> result = [...transactions];

    if (selectedFilter == 'Today') {
      result = result.where((transaction) {
        return transaction['transaction_date'] == today;
      }).toList();
    }

    if (selectedFilter == 'This Week') {
      result = result.where((transaction) {
        final date = transaction['transaction_date']?.toString() ?? '';
        return date.compareTo(startWeekText) >= 0 &&
            date.compareTo(endWeekText) <= 0;
      }).toList();
    }

    if (selectedFilter == 'This Month') {
      result = result.where((transaction) {
        final date = transaction['transaction_date']?.toString() ?? '';
        return date.startsWith(monthPrefix);
      }).toList();
    }

    if (query.isNotEmpty) {
      result = result.where((transaction) {
        final title = transaction['title']?.toString().toLowerCase() ?? '';
        final merchant =
            transaction['merchant_name']?.toString().toLowerCase() ?? '';
        final payment =
            transaction['payment_method_name']?.toString().toLowerCase() ?? '';

        return title.contains(query) ||
            merchant.contains(query) ||
            payment.contains(query);
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      filteredTransactions = result;
    });
  }

  void selectFilter(String filter) {
    setState(() {
      selectedFilter = filter;
    });

    applyFilters();
  }

  @override
  void dispose() {
    searchController.removeListener(applyFilters);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Transactions'),
        ),
        body: LoadingView(message: 'Loading transactions...'),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transactions'),
        ),
        body: EmptyStateView(
          icon: Icons.error_outline_rounded,
          title: 'Unable to load transactions',
          message: errorMessage!,
          actionLabel: 'Try Again',
          onActionPressed: loadTransactions,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: RefreshIndicator(
        onRefresh: loadTransactions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search transactions',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = selectedFilter == filter;

                  return GestureDetector(
                    onTap: () => selectFilter(filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color:
                          isSelected ? Colors.white : AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedFilter,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${filteredTransactions.length} transaction${filteredTransactions.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (filteredTransactions.isEmpty)
              EmptyStateView(
                icon: Icons.receipt_long_rounded,
                title: 'No transactions found',
                message: transactions.isEmpty
                    ? 'You have not recorded any expense yet.'
                    : 'No transactions match your current search or filter.',
                actionLabel:
                transactions.isEmpty ? 'Add Transaction' : null,
                onActionPressed:
                transactions.isEmpty ? widget.onAddTransaction : null,
              )
            else
              ...filteredTransactions.map(
                    (transaction) => _TransactionListItem(
                  title: _getTransactionTitle(transaction),
                  subtitle: _getTransactionSubtitle(transaction),
                  amount: MoneyUtils.centavosToPesoText(
                    _readInt(transaction['total_amount']),
                  ),
                  itemCount: _readInt(transaction['item_count']),
                  paymentMethod:
                  transaction['payment_method_name']?.toString(),
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

class _TransactionListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final int itemCount;
  final String? paymentMethod;

  const _TransactionListItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.itemCount,
    this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final paymentText =
    paymentMethod == null || paymentMethod!.isEmpty ? '' : ' • $paymentMethod';

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
                    '$subtitle$paymentText',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$itemCount item${itemCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}