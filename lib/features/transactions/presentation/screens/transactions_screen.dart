import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_format_utils.dart';
import '../../../../core/utils/category_ui_utils.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../features/settings/data/settings_repository.dart';
import '../../../../models/app_preferences.dart';
import '../../../../repositories/transaction_repository.dart';
import 'transaction_details_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final VoidCallback? onAddTransaction;
  final VoidCallback? onChanged;

  const TransactionsScreen({
    super.key,
    this.onAddTransaction,
    this.onChanged,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const Color _pageBackground = Color(0xFFF7F8FA);

  final transactionRepository = TransactionRepository();
  final settingsRepository = SettingsRepository();

  AppPreferences preferences = AppPreferences.defaults();

  DateTime selectedDate = DateUtils.dateOnly(DateTime.now());

  bool isInitialLoading = true;
  bool isDateDataLoading = false;
  String? errorMessage;

  int selectedDateTotal = 0;
  int selectedDateTransactionCount = 0;

  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> categoryTotals = [];

  int _loadRequestId = 0;

  @override
  void initState() {
    super.initState();
    loadSelectedDate(initialLoad: true);
  }

  Future<void> loadSelectedDate({
    bool initialLoad = false,
  }) async {
    final requestId = ++_loadRequestId;
    final requestedDate = selectedDate;

    if (initialLoad) {
      setState(() {
        isInitialLoading = true;
        errorMessage = null;
      });
    } else {
      setState(() {
        isDateDataLoading = true;
      });
    }

    try {
      final transactionsFuture =
      transactionRepository.getTransactionsForDate(requestedDate);

      final totalFuture =
      transactionRepository.getTotalForDate(requestedDate);

      final transactionCountFuture =
      transactionRepository.getTransactionCountForDate(requestedDate);

      final categoryTotalsFuture =
      transactionRepository.getTotalsByCategoryForDate(requestedDate);

      final preferencesFuture = settingsRepository.getPreferences();

      final loadedTransactions = await transactionsFuture;
      final loadedTotal = await totalFuture;
      final loadedTransactionCount = await transactionCountFuture;
      final loadedCategoryTotals = await categoryTotalsFuture;
      final loadedPreferences = await preferencesFuture;

      if (!mounted || requestId != _loadRequestId) return;

      setState(() {
        transactions = loadedTransactions;
        selectedDateTotal = loadedTotal;
        selectedDateTransactionCount = loadedTransactionCount;
        categoryTotals = loadedCategoryTotals;
        preferences = loadedPreferences;

        isInitialLoading = false;
        isDateDataLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted || requestId != _loadRequestId) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      if (initialLoad) {
        setState(() {
          errorMessage = message;
          isInitialLoading = false;
          isDateDataLoading = false;
        });
      } else {
        setState(() {
          isDateDataLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  Future<void> openDetails(int transactionId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailsScreen(
          transactionId: transactionId,
          onChanged: loadSelectedDate,
        ),
      ),
    );

    if (result == true) {
      widget.onChanged?.call();
      await loadSelectedDate();
    }
  }

  Future<void> selectDate(DateTime date) async {
    final normalizedDate = DateUtils.dateOnly(date);

    if (DateUtils.isSameDay(normalizedDate, selectedDate)) {
      return;
    }

    setState(() {
      selectedDate = normalizedDate;
    });

    await loadSelectedDate();
  }

  Future<void> moveWeek(int weekOffset) async {
    setState(() {
      selectedDate = DateUtils.dateOnly(
        selectedDate.add(Duration(days: weekOffset * 7)),
      );
    });

    await loadSelectedDate();
  }

  Future<void> openDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select transaction date',
    );

    if (pickedDate == null) return;

    await selectDate(pickedDate);
  }

  @override
  Widget build(BuildContext context) {
    if (isInitialLoading) {
      return const Scaffold(
        backgroundColor: _pageBackground,
        body: SafeArea(
          child: LoadingView(
            message: 'Loading transactions...',
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: _pageBackground,
        body: SafeArea(
          child: EmptyStateView(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load transactions',
            message: errorMessage!,
            actionLabel: 'Try Again',
            onActionPressed: () {
              loadSelectedDate(initialLoad: true);
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: loadSelectedDate,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
            children: [
              const Text(
                'Transactions',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 18),
              _buildWeeklyCalendar(),
              const SizedBox(height: 16),
              _buildDateDependentContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateDependentContent() {
    return Stack(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isDateDataLoading ? 0.45 : 1,
          child: IgnorePointer(
            ignoring: isDateDataLoading,
            child: Column(
              children: [
                _buildDailyAnalytics(),
                const SizedBox(height: 24),
                _buildTransactionsSection(),
              ],
            ),
          ),
        ),
        if (isDateDataLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: AppTheme.primary,
                backgroundColor: Color(0xFFE7F5ED),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWeeklyCalendar() {
    final weekStart = _startOfWeek(selectedDate);

    final weekDates = List.generate(
      7,
          (index) => weekStart.add(Duration(days: index)),
    );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous week',
                onPressed: () => moveWeek(-1),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: openDatePicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: AppTheme.primary,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _formatMonthYear(selectedDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.textSecondary,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next week',
                onPressed: () => moveWeek(1),
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: weekDates.map((date) {
              return Expanded(
                child: _CalendarDayItem(
                  date: date,
                  isSelected: DateUtils.isSameDay(
                    date,
                    selectedDate,
                  ),
                  isToday: DateUtils.isSameDay(
                    date,
                    DateTime.now(),
                  ),
                  onTap: () => selectDate(date),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAnalytics() {
    final slices = _createCategorySlices();

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expenses on ${_formatLongDate(selectedDate)}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Expenses',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        MoneyUtils.formatAmount(
                          selectedDateTotal,
                          currencySymbol: preferences.currencySymbol,
                        ),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$selectedDateTransactionCount '
                      '${selectedDateTransactionCount == 1 ? 'transaction' : 'transactions'}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(
            height: 1,
            color: Color(0xFFEAECF0),
          ),
          const SizedBox(height: 18),
          if (slices.isEmpty)
            _buildEmptyAnalytics()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final useVerticalLayout = constraints.maxWidth < 330;

                if (useVerticalLayout) {
                  return Column(
                    children: [
                      _ExpenseDonutChart(
                        slices: slices,
                        totalAmount: selectedDateTotal,
                        currencySymbol: preferences.currencySymbol,
                      ),
                      const SizedBox(height: 20),
                      _CategoryLegend(
                        slices: slices,
                        currencySymbol: preferences.currencySymbol,
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _CategoryLegend(
                        slices: slices,
                        currencySymbol: preferences.currencySymbol,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 158,
                      child: _ExpenseDonutChart(
                        slices: slices,
                        totalAmount: selectedDateTotal,
                        currencySymbol: preferences.currencySymbol,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyAnalytics() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pie_chart_outline_rounded,
              color: AppTheme.primary,
              size: 29,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No category analytics',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Category spending will appear after expenses are recorded for this date.',
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

  Widget _buildTransactionsSection() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Transactions',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '$selectedDateTransactionCount '
                  '${selectedDateTransactionCount == 1 ? 'transaction' : 'transactions'}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (transactions.isEmpty)
          _buildEmptyTransactions()
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: List.generate(
                transactions.length,
                    (index) {
                  final transaction = transactions[index];

                  final categoryName =
                  _getPrimaryCategoryName(transaction);

                  final categoryColor = CategoryUiUtils.resolveColor(
                    transaction['primary_category_color'],
                    fallbackIndex: index,
                  );

                  final categoryIcon = CategoryUiUtils.resolveIcon(
                    transaction['primary_category_icon'],
                    categoryName,
                  );

                  return Column(
                    children: [
                      _TransactionListItem(
                        title: _getTransactionTitle(transaction),
                        categoryName: categoryName,
                        categoryColor: categoryColor,
                        categoryIcon: categoryIcon,
                        amount: MoneyUtils.formatAmount(
                          _readInt(transaction['total_amount']),
                          currencySymbol: preferences.currencySymbol,
                        ),
                        itemCount: _readInt(transaction['item_count']),
                        time: _getTransactionTime(transaction),
                        paymentMethod:
                        transaction['payment_method_name']?.toString(),
                        onTap: () => openDetails(
                          _readInt(transaction['id']),
                        ),
                      ),
                      if (index < transactions.length - 1)
                        const Divider(
                          height: 1,
                          indent: 66,
                          endIndent: 14,
                          color: Color(0xFFEAECF0),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return AppCard(
      child: Column(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppTheme.primary,
              size: 29,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No transactions for this date',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No expenses were recorded on '
                '${_formatLongDate(selectedDate)}.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (widget.onAddTransaction != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.onAddTransaction,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Transaction'),
            ),
          ],
        ],
      ),
    );
  }

  List<_CategorySlice> _createCategorySlices() {
    final validRows = categoryTotals.where((row) {
      return _readInt(row['total_amount']) > 0;
    }).toList();

    if (validRows.isEmpty) {
      return [];
    }

    if (validRows.length <= 5) {
      return List.generate(
        validRows.length,
            (index) {
          final row = validRows[index];

          final name =
              row['category_name']?.toString().trim() ?? '';

          final displayName =
          name.isEmpty ? 'Uncategorized' : name;

          return _CategorySlice(
            name: displayName,
            amount: _readInt(row['total_amount']),
            color: CategoryUiUtils.resolveColor(
              row['category_color'],
              fallbackIndex: index,
            ),
            icon: CategoryUiUtils.resolveIcon(
              row['category_icon'],
              displayName,
            ),
          );
        },
      );
    }

    final topRows = validRows.take(4).toList();
    final remainingRows = validRows.skip(4);

    final slices = List.generate(
      topRows.length,
          (index) {
        final row = topRows[index];

        final name =
            row['category_name']?.toString().trim() ?? '';

        final displayName =
        name.isEmpty ? 'Uncategorized' : name;

        return _CategorySlice(
          name: displayName,
          amount: _readInt(row['total_amount']),
          color: CategoryUiUtils.resolveColor(
            row['category_color'],
            fallbackIndex: index,
          ),
          icon: CategoryUiUtils.resolveIcon(
            row['category_icon'],
            displayName,
          ),
        );
      },
    );

    final othersTotal = remainingRows.fold<int>(
      0,
          (sum, row) => sum + _readInt(row['total_amount']),
    );

    if (othersTotal > 0) {
      slices.add(
        const _CategorySlice(
          name: 'Others',
          amount: 0,
          color: Color(0xFFE9A23B),
          icon: Icons.more_horiz_rounded,
        ).copyWith(
          amount: othersTotal,
        ),
      );
    }

    return slices;
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateUtils.dateOnly(date);

    return normalized.subtract(
      Duration(days: normalized.weekday - 1),
    );
  }

  String _getTransactionTitle(
      Map<String, dynamic> transaction,
      ) {
    final merchantName = transaction['merchant_name'];
    final title = transaction['title'];

    if (merchantName != null &&
        merchantName.toString().trim().isNotEmpty) {
      return merchantName.toString().trim();
    }

    if (title != null && title.toString().trim().isNotEmpty) {
      return title.toString().trim();
    }

    return 'Untitled Transaction';
  }

  String _getPrimaryCategoryName(
      Map<String, dynamic> transaction,
      ) {
    final category =
    transaction['primary_category_name']?.toString();

    if (category == null || category.trim().isEmpty) {
      return 'Uncategorized';
    }

    return category.trim();
  }

  String _getTransactionTime(
      Map<String, dynamic> transaction,
      ) {
    final time =
        transaction['transaction_time']?.toString() ?? '';

    if (time.trim().isEmpty) {
      return 'No time';
    }

    return AppFormatUtils.formatTime(
      time,
      timeFormat: preferences.timeFormat,
    );
  }

  int _readInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }
}

class _CalendarDayItem extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _CalendarDayItem({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 2,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: !isSelected && isToday
                ? Border.all(
              color: AppTheme.primary.withValues(
                alpha: 0.35,
              ),
            )
                : null,
          ),
          child: Column(
            children: [
              Text(
                _shortWeekday(date.weekday),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isToday
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${date.day}',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                height: 5,
                width: 5,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : isToday
                      ? AppTheme.primary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseDonutChart extends StatelessWidget {
  final List<_CategorySlice> slices;
  final int totalAmount;
  final String currencySymbol;

  const _ExpenseDonutChart({
    required this.slices,
    required this.totalAmount,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final categoryTotal = slices.fold<int>(
      0,
          (sum, slice) => sum + slice.amount,
    );

    return SizedBox(
      height: 178,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              centerSpaceRadius: 45,
              sectionsSpace: 3,
              startDegreeOffset: -90,
              sections: slices.map((slice) {
                final percentage = categoryTotal <= 0
                    ? 0.0
                    : slice.amount / categoryTotal * 100;

                return PieChartSectionData(
                  value: slice.amount.toDouble(),
                  color: slice.color,
                  radius: 37,
                  showTitle: percentage >= 9,
                  title: '${percentage.toStringAsFixed(0)}%',
                  titlePositionPercentageOffset: 0.55,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          ),
          SizedBox(
            width: 88,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    MoneyUtils.formatAmount(
                      totalAmount,
                      currencySymbol: currencySymbol,
                    ),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Total',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  final List<_CategorySlice> slices;
  final String currencySymbol;

  const _CategoryLegend({
    required this.slices,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<int>(
      0,
          (sum, slice) => sum + slice.amount,
    );

    return Column(
      children: slices.map((slice) {
        final percentage = total <= 0
            ? 0.0
            : slice.amount / total * 100;

        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: slice.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  slice.icon,
                  color: slice.color,
                  size: 17,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slice.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${MoneyUtils.formatAmount(
                        slice.amount,
                        currencySymbol: currencySymbol,
                      )} '
                          '(${percentage.toStringAsFixed(0)}%)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                height: 7,
                width: 7,
                decoration: BoxDecoration(
                  color: slice.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  final String title;
  final String categoryName;
  final Color categoryColor;
  final IconData categoryIcon;
  final String amount;
  final int itemCount;
  final String time;
  final String? paymentMethod;
  final VoidCallback? onTap;

  const _TransactionListItem({
    required this.title,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.amount,
    required this.itemCount,
    required this.time,
    this.paymentMethod,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final payment = paymentMethod?.trim() ?? '';

    final metaText = payment.isEmpty
        ? time
        : '$time • $payment';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        child: Row(
          children: [
            Container(
              height: 43,
              width: 43,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                categoryIcon,
                color: categoryColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$categoryName • $itemCount '
                        '${itemCount == 1 ? 'item' : 'items'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metaText,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySlice {
  final String name;
  final int amount;
  final Color color;
  final IconData icon;

  const _CategorySlice({
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
  });

  _CategorySlice copyWith({
    String? name,
    int? amount,
    Color? color,
    IconData? icon,
  }) {
    return _CategorySlice(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}

String _formatMonthYear(DateTime date) {
  return '${_fullMonthName(date.month)} ${date.year}';
}

String _formatLongDate(DateTime date) {
  return '${_shortWeekdayTitle(date.weekday)}, '
      '${_shortMonthName(date.month)} '
      '${date.day}, ${date.year}';
}

String _fullMonthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return months[month - 1];
}

String _shortMonthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return months[month - 1];
}

String _shortWeekday(int weekday) {
  const weekdays = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  return weekdays[weekday - 1];
}

String _shortWeekdayTitle(int weekday) {
  const weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  return weekdays[weekday - 1];
}
