import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_format_utils.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../features/settings/data/settings_repository.dart';
import '../../../../models/app_preferences.dart';
import '../../../../repositories/transaction_repository.dart';
import '../../../transactions/presentation/screens/transaction_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onViewAllTransactions;
  final VoidCallback? onAddTransaction;
  final VoidCallback? onChanged;

  /// Optional fallback when the authenticated user's display name
  /// is not available from Firebase.
  final String? firstName;

  const HomeScreen({
    super.key,
    this.onViewAllTransactions,
    this.onAddTransaction,
    this.onChanged,
    this.firstName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _pageBackground = Color(0xFFF7F8FA);

  static const Color _blueAccent = Color(0xFF1769D2);
  static const Color _blueBackground = Color(0xFFF2F6FF);

  static const Color _orangeAccent = Color(0xFFF57C00);
  static const Color _orangeBackground = Color(0xFFFFF7EA);

  static const Color _greenBackground = Color(0xFFF1FAF5);

  final transactionRepository = TransactionRepository();
  final settingsRepository = SettingsRepository();

  AppPreferences preferences = AppPreferences.defaults();

  bool isLoading = true;
  String? errorMessage;

  int todayTotal = 0;
  int weekTotal = 0;
  int monthTotal = 0;

  int todayCount = 0;
  int weekCount = 0;
  int monthCount = 0;

  List<Map<String, dynamic>> recentTransactions = [];
  List<_MonthlyExpensePoint> monthlyTrend = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> openDetails(int transactionId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailsScreen(
          transactionId: transactionId,
          onChanged: loadDashboard,
        ),
      ),
    );

    if (result == true) {
      widget.onChanged?.call();
      await loadDashboard();
    }
  }

  Future<void> loadDashboard({
    bool showLoadingIndicator = true,
  }) async {
    if (showLoadingIndicator) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    } else {
      setState(() {
        errorMessage = null;
      });
    }

    try {
      final todayTotalFuture =
      transactionRepository.getTodayTotal();

      final weekTotalFuture =
      transactionRepository.getWeekTotal();

      final monthTotalFuture =
      transactionRepository.getMonthTotal();

      final todayCountFuture =
      transactionRepository.getTodayTransactionCount();

      final weekCountFuture =
      transactionRepository.getWeekTransactionCount();

      final monthCountFuture =
      transactionRepository.getMonthTransactionCount();

      final preferencesFuture =
      settingsRepository.getPreferences();

      final recentFuture =
      transactionRepository.getRecentTransactions(limit: 5);

      final trendFuture =
      transactionRepository.getMonthlyExpenseTrend(
        monthCount: 6,
      );

      final today = await todayTotalFuture;
      final week = await weekTotalFuture;
      final month = await monthTotalFuture;

      final loadedTodayCount = await todayCountFuture;
      final loadedWeekCount = await weekCountFuture;
      final loadedMonthCount = await monthCountFuture;

      final loadedPreferences = await preferencesFuture;
      final recent = await recentFuture;
      final trendRows = await trendFuture;

      if (!mounted) return;

      setState(() {
        todayTotal = today;
        weekTotal = week;
        monthTotal = month;

        todayCount = loadedTodayCount;
        weekCount = loadedWeekCount;
        monthCount = loadedMonthCount;

        preferences = loadedPreferences;
        recentTransactions = recent;

        monthlyTrend = _normalizeMonthlyTrend(
          trendRows,
          monthCount: 6,
        );

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: _pageBackground,
        body: SafeArea(
          child: LoadingView(
            message: 'Loading dashboard...',
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
            title: 'Unable to load dashboard',
            message: errorMessage!,
            actionLabel: 'Try Again',
            onActionPressed: loadDashboard,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () {
            return loadDashboard(
              showLoadingIndicator: false,
            );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              120,
            ),
            children: [
              _buildHeader(),

              const SizedBox(height: 22),

              _buildOverviewCards(),

              const SizedBox(height: 18),

              _buildMonthlyTrendCard(),

              const SizedBox(height: 24),

              _buildRecentTransactionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 2,
              bottom: 10,
            ),
            child: SizedBox(
              height: 82,
              width: 82,
              child: Image.asset(
                'assets/images/gasto_migo_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        Text(
          _getGreeting(),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'Here’s your expense overview',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    return SizedBox(
      height: 242,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ExpenseOverviewCard(
              label: 'Today',
              amount: MoneyUtils.formatAmount(
                todayTotal,
                currencySymbol: preferences.currencySymbol,
              ),
              transactionCount: todayCount,
              accentColor: AppTheme.primary,
              backgroundColor: _greenBackground,
              large: true,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _ExpenseOverviewCard(
                    label: 'This Week',
                    amount: MoneyUtils.formatAmount(
                      weekTotal,
                      currencySymbol:
                      preferences.currencySymbol,
                    ),
                    transactionCount: weekCount,
                    accentColor: _blueAccent,
                    backgroundColor: _blueBackground,
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: _ExpenseOverviewCard(
                    label: 'This Month',
                    amount: MoneyUtils.formatAmount(
                      monthTotal,
                      currencySymbol:
                      preferences.currencySymbol,
                    ),
                    transactionCount: monthCount,
                    accentColor: _orangeAccent,
                    backgroundColor: _orangeBackground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendCard() {
    final currentMonthAmount = monthlyTrend.isNotEmpty
        ? monthlyTrend.last.amount
        : monthTotal;

    final previousMonthAmount = monthlyTrend.length >= 2
        ? monthlyTrend[monthlyTrend.length - 2].amount
        : 0;

    final comparison = _calculatePercentageChange(
      currentMonthAmount,
      previousMonthAmount,
    );

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Monthly Spending Trend',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              SizedBox(width: 12),

              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Last 6 Months',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            _currentMonthLabel(),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            MoneyUtils.formatAmount(
              currentMonthAmount,
              currencySymbol: preferences.currencySymbol,
            ),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          _buildComparisonRow(comparison),

          const SizedBox(height: 18),

          _MonthlyTrendChart(
            points: monthlyTrend,
            currencySymbol: preferences.currencySymbol,
          ),

          const SizedBox(height: 16),

          _buildMonthlyInsight(comparison),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(double? comparison) {
    if (comparison == null) {
      return const Text(
        'No previous-month comparison',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
        ),
      );
    }

    final isIncrease = comparison > 0;
    final isDecrease = comparison < 0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isIncrease
                    ? Icons.arrow_upward_rounded
                    : isDecrease
                    ? Icons.arrow_downward_rounded
                    : Icons.remove_rounded,
                color: AppTheme.primary,
                size: 14,
              ),
              const SizedBox(width: 3),
              Text(
                '${comparison.abs().toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        const Text(
          'vs last month',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyInsight(double? comparison) {
    String message;

    if (comparison == null) {
      message =
      'No previous-month spending is available for comparison.';
    } else if (comparison > 0) {
      message =
      'You’ve spent ${comparison.abs().toStringAsFixed(1)}% '
          'more than last month.';
    } else if (comparison < 0) {
      message =
      'You’ve spent ${comparison.abs().toStringAsFixed(1)}% '
          'less than last month.';
    } else {
      message =
      'Your spending is unchanged from last month.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(
                alpha: 0.11,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: AppTheme.primary,
              size: 19,
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

  Widget _buildRecentTransactionsSection() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Transactions',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            TextButton(
              onPressed: widget.onViewAllTransactions,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See all'),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        if (recentTransactions.isEmpty)
          _buildEmptyTransactions()
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: List.generate(
                recentTransactions.length,
                    (index) {
                  final transaction =
                  recentTransactions[index];

                  final categoryName =
                  _getPrimaryCategoryName(transaction);

                  final categoryColor =
                  _resolveCategoryColor(
                    transaction[
                    'primary_category_color'],
                    index,
                  );

                  final categoryIcon =
                  _resolveCategoryIcon(
                    transaction[
                    'primary_category_icon'],
                    categoryName,
                  );

                  return Column(
                    children: [
                      _TransactionPreviewTile(
                        title:
                        _getTransactionTitle(transaction),
                        categoryName: categoryName,
                        categoryColor: categoryColor,
                        categoryIcon: categoryIcon,
                        subtitle:
                        _getTransactionSubtitle(transaction),
                        amount: MoneyUtils.formatAmount(
                          _readInt(
                            transaction['total_amount'],
                          ),
                          currencySymbol:
                          preferences.currencySymbol,
                        ),
                        itemCount: _readInt(
                          transaction['item_count'],
                        ),
                        onTap: () => openDetails(
                          _readInt(transaction['id']),
                        ),
                      ),

                      if (index <
                          recentTransactions.length - 1)
                        const Divider(
                          height: 1,
                          indent: 68,
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
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppTheme.primary,
              size: 28,
            ),
          ),

          const SizedBox(height: 14),

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

  List<_MonthlyExpensePoint> _normalizeMonthlyTrend(
      List<Map<String, dynamic>> rows, {
        required int monthCount,
      }) {
    final totalsByMonth = <String, int>{};

    for (final row in rows) {
      final key = row['month_key']?.toString();

      if (key == null || key.trim().isEmpty) {
        continue;
      }

      totalsByMonth[key] =
          _readInt(row['total_amount']);
    }

    final now = DateTime.now();

    return List.generate(monthCount, (index) {
      final monthsAgo = monthCount - index - 1;

      final month = DateTime(
        now.year,
        now.month - monthsAgo,
        1,
      );

      final key =
          '${month.year.toString().padLeft(4, '0')}-'
          '${month.month.toString().padLeft(2, '0')}';

      return _MonthlyExpensePoint(
        month: month,
        amount: totalsByMonth[key] ?? 0,
      );
    });
  }

  double? _calculatePercentageChange(
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

  String _getGreeting() {
    final hour = DateTime.now().hour;

    String greeting;

    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 18) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    final firstName = _resolveFirstName();

    if (firstName.isEmpty) {
      return '$greeting!';
    }

    return '$greeting, $firstName!';
  }

  String _resolveFirstName() {
    final suppliedName = widget.firstName?.trim();

    if (suppliedName != null && suppliedName.isNotEmpty) {
      return _capitalizeFirstName(
        suppliedName.split(RegExp(r'\s+')).first,
      );
    }

    final firebaseDisplayName =
    FirebaseAuth.instance.currentUser?.displayName?.trim();

    if (firebaseDisplayName != null &&
        firebaseDisplayName.isNotEmpty) {
      return _capitalizeFirstName(
        firebaseDisplayName
            .split(RegExp(r'\s+'))
            .first,
      );
    }

    return '';
  }

  String _capitalizeFirstName(String name) {
    final cleaned = name.trim();

    if (cleaned.isEmpty) {
      return '';
    }

    if (cleaned.length == 1) {
      return cleaned.toUpperCase();
    }

    return cleaned[0].toUpperCase() +
        cleaned.substring(1);
  }

  String _currentMonthLabel() {
    final now = DateTime.now();

    return '${_fullMonthName(now.month)} ${now.year}';
  }

  String _getTransactionTitle(
      Map<String, dynamic> transaction,
      ) {
    final merchantName =
    transaction['merchant_name'];

    final title = transaction['title'];

    if (merchantName != null &&
        merchantName.toString().trim().isNotEmpty) {
      return merchantName.toString().trim();
    }

    if (title != null &&
        title.toString().trim().isNotEmpty) {
      return title.toString().trim();
    }

    return 'Untitled Transaction';
  }

  String _getPrimaryCategoryName(
      Map<String, dynamic> transaction,
      ) {
    final category = transaction[
    'primary_category_name']
        ?.toString()
        .trim();

    if (category == null || category.isEmpty) {
      return 'Uncategorized';
    }

    return category;
  }

  String _getTransactionSubtitle(
      Map<String, dynamic> transaction,
      ) {
    final date =
        transaction['transaction_date']
            ?.toString() ??
            '';

    final time =
    transaction['transaction_time']
        ?.toString();

    return AppFormatUtils.formatDateTime(
      date: date,
      time: time,
      dateFormat: preferences.dateFormat,
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

class _ExpenseOverviewCard extends StatelessWidget {
  final String label;
  final String amount;
  final int transactionCount;
  final Color accentColor;
  final Color backgroundColor;
  final bool large;

  const _ExpenseOverviewCard({
    required this.label,
    required this.amount,
    required this.transactionCount,
    required this.accentColor,
    required this.backgroundColor,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            !large || constraints.maxHeight < 150;

        final padding = compact ? 11.0 : 18.0;
        final iconSize = compact ? 17.0 : 21.0;
        final iconContainerSize =
        compact ? 30.0 : 40.0;
        final labelSize = compact ? 13.0 : 17.0;
        final amountSize = compact ? 19.0 : 29.0;
        final countSize = compact ? 10.0 : 13.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D101828),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: labelSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  SizedBox(
                    height: iconContainerSize,
                    width: iconContainerSize,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accentColor.withValues(
                          alpha: 0.10,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: accentColor,
                        size: iconSize,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    maxLines: 1,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: amountSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              SizedBox(height: compact ? 2 : 7),

              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$transactionCount '
                        '${transactionCount == 1 ? 'transaction' : 'transactions'}',
                    maxLines: 1,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: countSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthlyExpensePoint {
  final DateTime month;
  final int amount;

  const _MonthlyExpensePoint({
    required this.month,
    required this.amount,
  });
}

class _MonthlyTrendChart extends StatelessWidget {
  final List<_MonthlyExpensePoint> points;
  final String currencySymbol;

  const _MonthlyTrendChart({
    required this.points,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 225,
        child: Center(
          child: Text(
            'No monthly spending data yet.',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    final highestAmount = points.fold<int>(
      0,
          (highest, point) {
        return math.max(
          highest,
          point.amount,
        );
      },
    );

    final maximumY = highestAmount <= 0
        ? 10000.0
        : highestAmount * 1.25;

    /*
     * A small negative Y-axis margin moves the zero baseline upward.
     * This keeps all zero-value circles fully visible.
     */
    final bottomMargin = maximumY * 0.10;

    final horizontalInterval = maximumY / 4;

    final chartSpots = List.generate(
      points.length,
          (index) => FlSpot(
        index.toDouble(),
        points[index].amount.toDouble(),
      ),
    );

    return SizedBox(
      height: 225,
      child: LineChart(
        LineChartData(
          /*
           * Extra horizontal margin prevents the first and last circles
           * from being clipped by the chart boundary.
           */
          minX: -0.18,
          maxX: points.length - 1 + 0.18,
          minY: -bottomMargin,
          maxY: maximumY,

          clipData: const FlClipData.all(),

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: horizontalInterval,
            getDrawingHorizontalLine: (value) {
              if (value < 0) {
                return const FlLine(
                  color: Colors.transparent,
                  strokeWidth: 0,
                );
              }

              return const FlLine(
                color: Color(0xFFEAECF0),
                strokeWidth: 1,
              );
            },
          ),

          borderData: FlBorderData(show: false),

          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 58,
                interval: horizontalInterval,
                getTitlesWidget: (value, meta) {
                  if (value < 0) {
                    return const SizedBox.shrink();
                  }

                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(
                      _formatCompactChartAmount(
                        value.round(),
                        currencySymbol,
                      ),
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final roundedIndex =
                  value.round();

                  if ((value - roundedIndex).abs() >
                      0.05 ||
                      roundedIndex < 0 ||
                      roundedIndex >= points.length) {
                    return const SizedBox.shrink();
                  }

                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      _shortMonthName(
                        points[roundedIndex]
                            .month
                            .month,
                      ),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
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
            touchTooltipData:
            LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) =>
              AppTheme.primary,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.round();

                  if (index < 0 ||
                      index >= points.length) {
                    return null;
                  }

                  final point = points[index];

                  return LineTooltipItem(
                    '${_shortMonthName(point.month.month)} '
                        '${point.month.year}\n'
                        '${MoneyUtils.formatAmount(
                      point.amount,
                      currencySymbol: currencySymbol,
                    )}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList();
              },
            ),
          ),

          lineBarsData: [
            LineChartBarData(
              spots: chartSpots,
              isCurved: true,
              curveSmoothness: 0.20,
              color: AppTheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,

              dotData: FlDotData(
                show: true,
                getDotPainter: (
                    spot,
                    percent,
                    barData,
                    index,
                    ) {
                  final isLast =
                      index == chartSpots.length - 1;

                  return FlDotCirclePainter(
                    radius: isLast ? 5.5 : 4,
                    color: spot.y == 0
                        ? Colors.white
                        : AppTheme.primary,
                    strokeColor: AppTheme.primary,
                    strokeWidth:
                    spot.y == 0 ? 2.5 : 1.5,
                  );
                },
              ),

              belowBarData: BarAreaData(
                show: true,
                cutOffY: 0,
                applyCutOffY: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary.withValues(
                      alpha: 0.18,
                    ),
                    AppTheme.primary.withValues(
                      alpha: 0.01,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(
          milliseconds: 450,
        ),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class _TransactionPreviewTile extends StatelessWidget {
  final String title;
  final String categoryName;
  final Color categoryColor;
  final IconData categoryIcon;
  final String subtitle;
  final String amount;
  final int itemCount;
  final VoidCallback? onTap;

  const _TransactionPreviewTile({
    required this.title,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.subtitle,
    required this.amount,
    required this.itemCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: categoryColor.withValues(
                  alpha: 0.12,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                categoryIcon,
                color: categoryColor,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
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
                    '$categoryName • $subtitle • '
                        '$itemCount '
                        'item${itemCount == 1 ? '' : 's'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Text(
              amount,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(width: 4),

            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

Color _resolveCategoryColor(
    dynamic rawColor,
    int index,
    ) {
  const fallbackColors = [
    Color(0xFF078C44),
    Color(0xFFF57C00),
    Color(0xFF7047EB),
    Color(0xFF1769D2),
    Color(0xFFE9A23B),
    Color(0xFFDC4C64),
    Color(0xFF00897B),
  ];

  final fallback =
  fallbackColors[index % fallbackColors.length];

  if (rawColor == null) {
    return fallback;
  }

  if (rawColor is int) {
    final value = rawColor <= 0xFFFFFF
        ? rawColor | 0xFF000000
        : rawColor;

    return Color(value);
  }

  final text =
  rawColor.toString().trim().toLowerCase();

  const namedColors = {
    'green': Color(0xFF078C44),
    'orange': Color(0xFFF57C00),
    'purple': Color(0xFF7047EB),
    'blue': Color(0xFF1769D2),
    'yellow': Color(0xFFE9A23B),
    'red': Color(0xFFDC4C64),
    'teal': Color(0xFF00897B),
  };

  if (namedColors.containsKey(text)) {
    return namedColors[text]!;
  }

  var hex = text
      .replaceFirst('#', '')
      .replaceFirst('0x', '');

  if (hex.length == 6) {
    hex = 'FF$hex';
  }

  if (hex.length == 8) {
    final parsed = int.tryParse(
      hex,
      radix: 16,
    );

    if (parsed != null) {
      return Color(parsed);
    }
  }

  return fallback;
}

IconData _resolveCategoryIcon(
    dynamic rawIcon,
    String categoryName,
    ) {
  if (rawIcon is int) {
    return IconData(
      rawIcon,
      fontFamily: 'MaterialIcons',
    );
  }

  final rawText =
      rawIcon?.toString().trim().toLowerCase() ??
          '';

  final numericCodePoint = int.tryParse(rawText);

  if (numericCodePoint != null) {
    return IconData(
      numericCodePoint,
      fontFamily: 'MaterialIcons',
    );
  }

  final searchableText =
      '$rawText ${categoryName.toLowerCase()}';

  if (searchableText.contains('food') ||
      searchableText.contains('drink') ||
      searchableText.contains('restaurant') ||
      searchableText.contains('meal') ||
      searchableText.contains('dining')) {
    return Icons.restaurant_rounded;
  }

  if (searchableText.contains('shopping') ||
      searchableText.contains('shop') ||
      searchableText.contains('grocery') ||
      searchableText.contains('supermarket')) {
    return Icons.shopping_bag_rounded;
  }

  if (searchableText.contains('health') ||
      searchableText.contains('medical') ||
      searchableText.contains('medicine') ||
      searchableText.contains('pharmacy') ||
      searchableText.contains('hospital')) {
    return Icons.medical_services_rounded;
  }

  if (searchableText.contains('transport') ||
      searchableText.contains('car') ||
      searchableText.contains('bus') ||
      searchableText.contains('ride') ||
      searchableText.contains('travel')) {
    return Icons.directions_car_rounded;
  }

  if (searchableText.contains('bill') ||
      searchableText.contains('utility') ||
      searchableText.contains('electric') ||
      searchableText.contains('water')) {
    return Icons.receipt_long_rounded;
  }

  if (searchableText.contains('education') ||
      searchableText.contains('school')) {
    return Icons.school_rounded;
  }

  if (searchableText.contains('entertainment') ||
      searchableText.contains('movie') ||
      searchableText.contains('game')) {
    return Icons.movie_rounded;
  }

  if (searchableText.contains('home') ||
      searchableText.contains('house') ||
      searchableText.contains('rent')) {
    return Icons.home_rounded;
  }

  if (searchableText.contains('personal') ||
      searchableText.contains('care')) {
    return Icons.person_rounded;
  }

  if (searchableText.contains('gift')) {
    return Icons.card_giftcard_rounded;
  }

  return Icons.category_rounded;
}

String _formatCompactChartAmount(
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