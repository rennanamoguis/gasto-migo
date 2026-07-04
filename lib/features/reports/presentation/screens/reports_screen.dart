import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_ui_utils.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../features/settings/data/settings_repository.dart';
import '../../../../models/app_preferences.dart';
import '../../../../repositories/transaction_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const Color _pageBackground = Color(0xFFF7F8FA);

  static const Color _blue = Color(0xFF1769D2);
  static const Color _orange = Color(0xFFF57C00);
  static const Color _yellow = Color(0xFFE9A23B);

  final transactionRepository = TransactionRepository();
  final settingsRepository = SettingsRepository();

  AppPreferences preferences = AppPreferences.defaults();

  bool isInitialLoading = true;
  bool isPeriodLoading = false;
  String? errorMessage;

  late DateTimeRange selectedRange;

  int totalExpenses = 0;
  int transactionCount = 0;
  int dailyAverage = 0;

  int previousTotalExpenses = 0;
  int previousTransactionCount = 0;
  int previousDailyAverage = 0;

  List<_DailyExpensePoint> dailyExpensePoints = [];
  List<_CategoryReportItem> categoryReportItems = [];

  int _loadRequestId = 0;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    selectedRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );

    loadReport(initialLoad: true);
  }

  Future<void> loadReport({
    bool initialLoad = false,
  }) async {
    final requestId = ++_loadRequestId;
    final requestedRange = DateTimeRange(
      start: selectedRange.start,
      end: selectedRange.end,
    );

    if (initialLoad) {
      setState(() {
        isInitialLoading = true;
        errorMessage = null;
      });
    } else {
      setState(() {
        isPeriodLoading = true;
      });
    }

    try {
      final transactionsFuture =
      transactionRepository.getTransactions();

      final preferencesFuture =
      settingsRepository.getPreferences();

      final allTransactions = await transactionsFuture;
      final loadedPreferences = await preferencesFuture;

      final currentTransactions = allTransactions.where((transaction) {
        final date = _parseTransactionDate(transaction);

        if (date == null) {
          return false;
        }

        return _isWithinRange(
          date,
          requestedRange.start,
          requestedRange.end,
        );
      }).toList();

      final previousRange = _getPreviousRangeFor(
        requestedRange,
      );

      final previousTransactions =
      allTransactions.where((transaction) {
        final date = _parseTransactionDate(transaction);

        if (date == null) {
          return false;
        }

        return _isWithinRange(
          date,
          previousRange.start,
          previousRange.end,
        );
      }).toList();

      final currentTotal = currentTransactions.fold<int>(
        0,
            (sum, transaction) {
          return sum + _readInt(transaction['total_amount']);
        },
      );

      final previousTotal = previousTransactions.fold<int>(
        0,
            (sum, transaction) {
          return sum + _readInt(transaction['total_amount']);
        },
      );

      final currentDayCount =
          requestedRange.end.difference(requestedRange.start).inDays + 1;

      final previousDayCount =
          previousRange.end.difference(previousRange.start).inDays + 1;

      final currentDailyAverage = currentDayCount <= 0
          ? 0
          : (currentTotal / currentDayCount).round();

      final oldDailyAverage = previousDayCount <= 0
          ? 0
          : (previousTotal / previousDayCount).round();

      final loadedDailyPoints = _buildDailyExpensePoints(
        currentTransactions,
        requestedRange,
      );

      final loadedCategoryItems =
      await _loadCategoryReportItems(currentTransactions);

      if (!mounted || requestId != _loadRequestId) return;

      setState(() {
        preferences = loadedPreferences;

        totalExpenses = currentTotal;
        transactionCount = currentTransactions.length;
        dailyAverage = currentDailyAverage;

        previousTotalExpenses = previousTotal;
        previousTransactionCount = previousTransactions.length;
        previousDailyAverage = oldDailyAverage;

        dailyExpensePoints = loadedDailyPoints;
        categoryReportItems = loadedCategoryItems;

        isInitialLoading = false;
        isPeriodLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted || requestId != _loadRequestId) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      if (initialLoad) {
        setState(() {
          errorMessage = message;
          isInitialLoading = false;
          isPeriodLoading = false;
        });
      } else {
        setState(() {
          isPeriodLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  Future<List<_CategoryReportItem>> _loadCategoryReportItems(
      List<Map<String, dynamic>> transactions,
      ) async {
    if (transactions.isEmpty) {
      return [];
    }

    final itemGroups = await Future.wait(
      transactions.map((transaction) {
        final transactionId = _readInt(transaction['id']);

        return transactionRepository.getItemsByTransactionId(
          transactionId,
        );
      }),
    );

    final totals = <String, _MutableCategoryTotal>{};

    for (final items in itemGroups) {
      for (final item in items) {
        final categoryId = item['category_id'];
        final rawName =
        item['category_name']?.toString().trim();

        final categoryName =
        rawName == null || rawName.isEmpty
            ? 'Uncategorized'
            : rawName;

        final key = categoryId == null
            ? 'uncategorized'
            : 'category_$categoryId';

        final amount = _readInt(item['subtotal_amount']);

        if (amount <= 0) {
          continue;
        }

        final existing = totals[key];

        if (existing == null) {
          totals[key] = _MutableCategoryTotal(
            name: categoryName,
            amount: amount,
            rawColor: item['category_color'],
            rawIcon: item['category_icon'],
          );
        } else {
          existing.amount += amount;
        }
      }
    }

    final sortedTotals = totals.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return List.generate(
      sortedTotals.length,
          (index) {
        final item = sortedTotals[index];

        return _CategoryReportItem(
          name: item.name,
          amount: item.amount,
          color: CategoryUiUtils.resolveColor(
            item.rawColor,
            fallbackIndex: index,
          ),
          icon: CategoryUiUtils.resolveIcon(
            item.rawIcon,
            item.name,
          ),
        );
      },
    );
  }

  List<_DailyExpensePoint> _buildDailyExpensePoints(
      List<Map<String, dynamic>> transactions,
      DateTimeRange range,
      ) {
    final dailyTotals = <String, int>{};

    for (final transaction in transactions) {
      final date = _parseTransactionDate(transaction);

      if (date == null) {
        continue;
      }

      final key = _dateKey(date);

      dailyTotals[key] =
          (dailyTotals[key] ?? 0) +
              _readInt(transaction['total_amount']);
    }

    final numberOfDays =
        range.end.difference(range.start).inDays + 1;

    return List.generate(numberOfDays, (index) {
      final date = DateUtils.dateOnly(
        range.start.add(Duration(days: index)),
      );

      return _DailyExpensePoint(
        date: date,
        amount: dailyTotals[_dateKey(date)] ?? 0,
      );
    });
  }

  Future<void> openDateRangePicker() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: selectedRange,
      helpText: 'Select report period',
      saveText: 'Apply',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      selectedRange = DateTimeRange(
        start: DateUtils.dateOnly(selected.start),
        end: DateUtils.dateOnly(selected.end),
      );
    });

    await loadReport();
  }

  Future<void> moveReportPeriod(int direction) async {
    final newRange = _shiftRange(
      selectedRange,
      direction,
    );

    setState(() {
      selectedRange = newRange;
    });

    await loadReport();
  }

  DateTimeRange _shiftRange(
      DateTimeRange range,
      int direction,
      ) {
    if (_isFullCalendarMonth(range)) {
      final shiftedStart = DateTime(
        range.start.year,
        range.start.month + direction,
        1,
      );

      final shiftedEnd = DateTime(
        shiftedStart.year,
        shiftedStart.month + 1,
        0,
      );

      return DateTimeRange(
        start: shiftedStart,
        end: shiftedEnd,
      );
    }

    final dayCount =
        range.end.difference(range.start).inDays + 1;

    final offset = Duration(
      days: dayCount * direction,
    );

    return DateTimeRange(
      start: range.start.add(offset),
      end: range.end.add(offset),
    );
  }

  DateTimeRange _getPreviousRange() {
    return _getPreviousRangeFor(selectedRange);
  }

  DateTimeRange _getPreviousRangeFor(
      DateTimeRange range,
      ) {
    if (_isFullCalendarMonth(range)) {
      final previousStart = DateTime(
        range.start.year,
        range.start.month - 1,
        1,
      );

      final previousEnd = DateTime(
        previousStart.year,
        previousStart.month + 1,
        0,
      );

      return DateTimeRange(
        start: previousStart,
        end: previousEnd,
      );
    }

    final dayCount =
        range.end.difference(range.start).inDays + 1;

    final previousEnd = range.start.subtract(
      const Duration(days: 1),
    );

    final previousStart = previousEnd.subtract(
      Duration(days: dayCount - 1),
    );

    return DateTimeRange(
      start: previousStart,
      end: previousEnd,
    );
  }

  bool _isFullCalendarMonth(DateTimeRange range) {
    final firstDay = DateTime(
      range.start.year,
      range.start.month,
      1,
    );

    final lastDay = DateTime(
      range.start.year,
      range.start.month + 1,
      0,
    );

    return DateUtils.isSameDay(range.start, firstDay) &&
        DateUtils.isSameDay(range.end, lastDay);
  }

  @override
  Widget build(BuildContext context) {
    if (isInitialLoading) {
      return const Scaffold(
        backgroundColor: _pageBackground,
        body: SafeArea(
          child: LoadingView(
            message: 'Loading reports...',
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
            title: 'Unable to load reports',
            message: errorMessage!,
            actionLabel: 'Try Again',
            onActionPressed: () {
              loadReport(initialLoad: true);
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
          onRefresh: loadReport,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
            children: [
              const Text(
                'Reports',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 18),
              _buildDateRangeSelector(),
              const SizedBox(height: 16),
              _buildReportDependentContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportDependentContent() {
    return Stack(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isPeriodLoading ? 0.45 : 1,
          child: IgnorePointer(
            ignoring: isPeriodLoading,
            child: Column(
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildExpenseTrendCard(),
                const SizedBox(height: 16),
                _buildCategoryBreakdownCard(),
                const SizedBox(height: 16),
                _buildTopCategoriesCard(),
                const SizedBox(height: 14),
                _buildComparisonInsight(),
              ],
            ),
          ),
        ),
        if (isPeriodLoading)
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

  Widget _buildDateRangeSelector() {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous period',
            onPressed: () => moveReportPeriod(-1),
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppTheme.primary,
              size: 28,
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: openDateRangePicker,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _formatDateRange(selectedRange),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
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
            tooltip: 'Next period',
            onPressed: () => moveReportPeriod(1),
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final expenseChange = _percentageChange(
      totalExpenses,
      previousTotalExpenses,
    );

    final transactionChange = _percentageChange(
      transactionCount,
      previousTransactionCount,
    );

    final dailyAverageChange = _percentageChange(
      dailyAverage,
      previousDailyAverage,
    );

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Summary',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  'vs ${_formatShortDateRange(_getPreviousRange())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Total Expenses',
                  value: MoneyUtils.formatAmount(
                    totalExpenses,
                    currencySymbol: preferences.currencySymbol,
                  ),
                  accentColor: AppTheme.primary,
                  percentageChange: expenseChange,
                ),
              ),
              const _SummaryDivider(),
              Expanded(
                child: _SummaryMetric(
                  label: 'Transactions',
                  value: '$transactionCount',
                  accentColor: _blue,
                  percentageChange: transactionChange,
                ),
              ),
              const _SummaryDivider(),
              Expanded(
                child: _SummaryMetric(
                  label: 'Daily Average',
                  value: MoneyUtils.formatAmount(
                    dailyAverage,
                    currencySymbol: preferences.currencySymbol,
                  ),
                  accentColor: _orange,
                  percentageChange: dailyAverageChange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTrendCard() {
    final hasExpenses = dailyExpensePoints.any(
          (point) => point.amount > 0,
    );

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expenses Over Time',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          if (!hasExpenses)
            const _ReportEmptyContent(
              icon: Icons.show_chart_rounded,
              title: 'No spending trend yet',
              message:
              'Expense activity for this period will appear here.',
            )
          else
            _DailyExpenseLineChart(
              points: dailyExpensePoints,
              currencySymbol: preferences.currencySymbol,
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard() {
    final visibleCategories = _getVisibleCategories();

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expenses by Category',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          if (visibleCategories.isEmpty)
            const _ReportEmptyContent(
              icon: Icons.pie_chart_outline_rounded,
              title: 'No category data',
              message:
              'Category spending for this period will appear here.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final useVerticalLayout =
                    constraints.maxWidth < 330;

                if (useVerticalLayout) {
                  return Column(
                    children: [
                      _CategoryDonutChart(
                        categories: visibleCategories,
                        totalExpenses: totalExpenses,
                        currencySymbol: preferences.currencySymbol,
                      ),
                      const SizedBox(height: 18),
                      _CategoryReportLegend(
                        categories: visibleCategories,
                        currencySymbol: preferences.currencySymbol,
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 145,
                      child: _CategoryDonutChart(
                        categories: visibleCategories,
                        totalExpenses: totalExpenses,
                        currencySymbol: preferences.currencySymbol,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _CategoryReportLegend(
                        categories: visibleCategories,
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

  Widget _buildTopCategoriesCard() {
    final visibleCategories =
    categoryReportItems.take(5).toList();

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Spending Categories',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          if (visibleCategories.isEmpty)
            const _ReportEmptyContent(
              icon: Icons.category_outlined,
              title: 'No top categories',
              message:
              'Your most-used spending categories will appear here.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  visibleCategories.length,
                      (index) {
                    final category =
                    visibleCategories[index];

                    final percentage = _categoryPercentage(
                      category.amount,
                    );

                    return Padding(
                      padding: EdgeInsets.only(
                        right: index ==
                            visibleCategories.length - 1
                            ? 0
                            : 10,
                      ),
                      child: _TopCategoryCard(
                        category: category,
                        amountText: MoneyUtils.formatAmount(
                          category.amount,
                          currencySymbol:
                          preferences.currencySymbol,
                        ),
                        percentage: percentage,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonInsight() {
    final change = _percentageChange(
      totalExpenses,
      previousTotalExpenses,
    );

    String message;
    IconData icon;

    if (change == null) {
      message =
      'No previous-period spending is available for comparison.';
      icon = Icons.insights_rounded;
    } else if (change > 0) {
      message =
      'You spent ${change.abs().toStringAsFixed(1)}% more '
          'than the previous period.';
      icon = Icons.trending_up_rounded;
    } else if (change < 0) {
      message =
      'You spent ${change.abs().toStringAsFixed(1)}% less '
          'than the previous period.';
      icon = Icons.trending_down_rounded;
    } else {
      message =
      'Your spending is unchanged from the previous period.';
      icon = Icons.trending_flat_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_CategoryReportItem> _getVisibleCategories() {
    if (categoryReportItems.length <= 5) {
      return categoryReportItems;
    }

    final topCategories =
    categoryReportItems.take(4).toList();

    final otherAmount = categoryReportItems.skip(4).fold<int>(
      0,
          (sum, category) => sum + category.amount,
    );

    return [
      ...topCategories,
      _CategoryReportItem(
        name: 'Others',
        amount: otherAmount,
        color: _yellow,
        icon: Icons.more_horiz_rounded,
      ),
    ];
  }

  double _categoryPercentage(int amount) {
    final categoryTotal = categoryReportItems.fold<int>(
      0,
          (sum, category) => sum + category.amount,
    );

    if (categoryTotal <= 0) {
      return 0;
    }

    return amount / categoryTotal * 100;
  }

  double? _percentageChange(
      int current,
      int previous,
      ) {
    if (previous == 0) {
      if (current == 0) {
        return 0;
      }

      return null;
    }

    return ((current - previous) / previous) * 100;
  }

  DateTime? _parseTransactionDate(
      Map<String, dynamic> transaction,
      ) {
    final rawDate =
    transaction['transaction_date']?.toString();

    if (rawDate == null || rawDate.trim().isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(rawDate.trim());

    if (parsed == null) {
      return null;
    }

    return DateUtils.dateOnly(parsed);
  }

  bool _isWithinRange(
      DateTime date,
      DateTime start,
      DateTime end,
      ) {
    final normalizedDate = DateUtils.dateOnly(date);
    final normalizedStart = DateUtils.dateOnly(start);
    final normalizedEnd = DateUtils.dateOnly(end);

    return !normalizedDate.isBefore(normalizedStart) &&
        !normalizedDate.isAfter(normalizedEnd);
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  int _readInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? 0;
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final double? percentageChange;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.percentageChange,
  });

  @override
  Widget build(BuildContext context) {
    final change = percentageChange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (change == null)
          const Text(
            'No comparison',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  change > 0
                      ? Icons.arrow_upward_rounded
                      : change < 0
                      ? Icons.arrow_downward_rounded
                      : Icons.remove_rounded,
                  color: AppTheme.primary,
                  size: 11,
                ),
                const SizedBox(width: 2),
                Text(
                  '${change.abs().toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 74,
      margin: const EdgeInsets.symmetric(horizontal: 9),
      color: const Color(0xFFEAECF0),
    );
  }
}

class _DailyExpenseLineChart extends StatelessWidget {
  final List<_DailyExpensePoint> points;
  final String currencySymbol;

  const _DailyExpenseLineChart({
    required this.points,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final highestAmount = points.fold<int>(
      0,
          (highest, point) {
        return math.max(highest, point.amount);
      },
    );

    final maximumY = math.max(
      10000.0,
      highestAmount * 1.25,
    );

    final horizontalInterval = maximumY / 4;

    final labelStep = math.max(
      1,
      (points.length / 4).ceil(),
    );

    final chartSpots = List.generate(
      points.length,
          (index) => FlSpot(
        index.toDouble(),
        points[index].amount.toDouble(),
      ),
    );

    final maximumX = points.length <= 1
        ? 1.0
        : (points.length - 1).toDouble();

    return SizedBox(
      height: 235,
      child: LineChart(
        LineChartData(
          minX: -0.15,
          maxX: maximumX + 0.15,
          minY: 0,
          maxY: maximumY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: horizontalInterval,
            getDrawingHorizontalLine: (_) {
              return const FlLine(
                color: Color(0xFFEAECF0),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                interval: horizontalInterval,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(
                      _formatCompactAmount(
                        value.round(),
                        currencySymbol,
                      ),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();

                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }

                  final shouldShow =
                      index == 0 ||
                          index == points.length - 1 ||
                          index % labelStep == 0;

                  if (!shouldShow) {
                    return const SizedBox.shrink();
                  }

                  return SideTitleWidget(
                    meta: meta,
                    space: 9,
                    child: Text(
                      '${_shortMonthName(points[index].date.month)} '
                          '${points[index].date.day}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => AppTheme.primary,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.round();

                  if (index < 0 || index >= points.length) {
                    return null;
                  }

                  final point = points[index];

                  return LineTooltipItem(
                    '${_shortMonthName(point.date.month)} '
                        '${point.date.day}, ${point.date.year}\n'
                        '${MoneyUtils.formatAmount(
                      point.amount,
                      currencySymbol: currencySymbol,
                    )}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: chartSpots,
              isCurved: points.length > 2,
              curveSmoothness: 0.22,
              color: AppTheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: points.length <= 31,
                getDotPainter: (
                    spot,
                    percent,
                    barData,
                    index,
                    ) {
                  return FlDotCirclePainter(
                    radius: 3.5,
                    color: AppTheme.primary,
                    strokeColor: Colors.white,
                    strokeWidth: 1.5,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.20),
                    AppTheme.primary.withValues(alpha: 0.01),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class _CategoryDonutChart extends StatelessWidget {
  final List<_CategoryReportItem> categories;
  final int totalExpenses;
  final String currencySymbol;

  const _CategoryDonutChart({
    required this.categories,
    required this.totalExpenses,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final categoryTotal = categories.fold<int>(
      0,
          (sum, category) => sum + category.amount,
    );

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              centerSpaceRadius: 46,
              sectionsSpace: 3,
              startDegreeOffset: -90,
              sections: categories.map((category) {
                final percentage = categoryTotal <= 0
                    ? 0.0
                    : category.amount / categoryTotal * 100;

                return PieChartSectionData(
                  color: category.color,
                  value: category.amount.toDouble(),
                  radius: 38,
                  showTitle: percentage >= 9,
                  title: '${percentage.toStringAsFixed(0)}%',
                  titlePositionPercentageOffset: 0.56,
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
            width: 86,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    MoneyUtils.formatAmount(
                      totalExpenses,
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

class _CategoryReportLegend extends StatelessWidget {
  final List<_CategoryReportItem> categories;
  final String currencySymbol;

  const _CategoryReportLegend({
    required this.categories,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final categoryTotal = categories.fold<int>(
      0,
          (sum, category) => sum + category.amount,
    );

    return Column(
      children: categories.map((category) {
        final percentage = categoryTotal <= 0
            ? 0.0
            : category.amount / categoryTotal * 100;

        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 17,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MoneyUtils.formatAmount(
                        category.amount,
                        currencySymbol: currencySymbol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: category.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TopCategoryCard extends StatelessWidget {
  final _CategoryReportItem category;
  final String amountText;
  final double percentage;

  const _TopCategoryCard({
    required this.category,
    required this.amountText,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: category.color.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 20,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amountText,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                color: category.color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportEmptyContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ReportEmptyContent({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppTheme.primary,
                size: 27,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyExpensePoint {
  final DateTime date;
  final int amount;

  const _DailyExpensePoint({
    required this.date,
    required this.amount,
  });
}

class _MutableCategoryTotal {
  final String name;
  int amount;
  final dynamic rawColor;
  final dynamic rawIcon;

  _MutableCategoryTotal({
    required this.name,
    required this.amount,
    required this.rawColor,
    required this.rawIcon,
  });
}

class _CategoryReportItem {
  final String name;
  final int amount;
  final Color color;
  final IconData icon;

  const _CategoryReportItem({
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
  });
}

String _formatDateRange(DateTimeRange range) {
  if (range.start.year == range.end.year &&
      range.start.month == range.end.month) {
    return '${_fullMonthName(range.start.month)} '
        '${range.start.day} – ${range.end.day}, '
        '${range.end.year}';
  }

  if (range.start.year == range.end.year) {
    return '${_shortMonthName(range.start.month)} '
        '${range.start.day} – '
        '${_shortMonthName(range.end.month)} '
        '${range.end.day}, ${range.end.year}';
  }

  return '${_shortMonthName(range.start.month)} '
      '${range.start.day}, ${range.start.year} – '
      '${_shortMonthName(range.end.month)} '
      '${range.end.day}, ${range.end.year}';
}

String _formatShortDateRange(DateTimeRange range) {
  if (range.start.year == range.end.year &&
      range.start.month == range.end.month) {
    return '${_shortMonthName(range.start.month)} '
        '${range.start.day}–${range.end.day}, '
        '${range.end.year}';
  }

  return '${_shortMonthName(range.start.month)} '
      '${range.start.day} – '
      '${_shortMonthName(range.end.month)} '
      '${range.end.day}';
}

String _formatCompactAmount(
    int centavos,
    String currencySymbol,
    ) {
  final amount = centavos / 100;

  if (amount >= 1000000) {
    return '$currencySymbol'
        '${(amount / 1000000).toStringAsFixed(1)}M';
  }

  if (amount >= 1000) {
    return '$currencySymbol'
        '${(amount / 1000).toStringAsFixed(1)}K';
  }

  return '$currencySymbol${amount.toStringAsFixed(0)}';
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
