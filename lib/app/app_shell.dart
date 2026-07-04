import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/add_transaction/presentation/screens/add_transaction_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/transactions/presentation/screens/transactions_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Navigation indexes:
  /// 0 = Home
  /// 1 = Transactions
  /// 2 = Add
  /// 3 = Reports
  /// 4 = Settings
  int selectedIndex = 0;

  int refreshCounter = 0;

  void onTabSelected(int index) {
    if (selectedIndex == index) {
      return;
    }

    setState(() {
      selectedIndex = index;
    });
  }

  void refreshData({int? goToTab}) {
    setState(() {
      refreshCounter++;

      if (goToTab != null) {
        selectedIndex = goToTab;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(
        key: ValueKey('home-$refreshCounter'),
        onViewAllTransactions: () => onTabSelected(1),
        onAddTransaction: () => onTabSelected(2),
        onChanged: refreshData,
      ),

      TransactionsScreen(
        key: ValueKey('transactions-$refreshCounter'),
        onAddTransaction: () => onTabSelected(2),
        onChanged: refreshData,
      ),

      AddTransactionScreen(
        key: ValueKey('add-$refreshCounter'),
        onTransactionSaved: () {
          refreshData(goToTab: 0);
        },
      ),

      ReportsScreen(key: ValueKey('reports-$refreshCounter')),

      SettingsScreen(onSettingsChanged: refreshData),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: BubbleBottomNav(
            selectedIndex: selectedIndex,
            onTap: onTabSelected,
          ),
        ),
      ),
    );
  }
}

class BubbleBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BubbleBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const List<_BubbleNavItem> items = [
    _BubbleNavItem(icon: Icons.home_rounded, label: 'Home'),
    _BubbleNavItem(
      icon: Icons.format_list_bulleted_rounded,
      label: 'Transactions',
    ),
    _BubbleNavItem(icon: Icons.add_rounded, label: 'Add', isCenterAction: true),
    _BubbleNavItem(icon: Icons.pie_chart_rounded, label: 'Reports'),
    _BubbleNavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = selectedIndex == index;

          return Expanded(
            child: item.isCenterAction
                ? _CenterAddNavButton(
                    isSelected: isSelected,
                    onTap: () => onTap(index),
                  )
                : _BubbleNavButton(
                    icon: item.icon,
                    label: item.label,
                    isSelected: isSelected,
                    onTap: () => onTap(index),
                  ),
          );
        }),
      ),
    );
  }
}

class _BubbleNavItem {
  final IconData icon;
  final String label;
  final bool isCenterAction;

  const _BubbleNavItem({
    required this.icon,
    required this.label,
    this.isCenterAction = false,
  });
}

class _BubbleNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BubbleNavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSelected
        ? AppTheme.primary
        : AppTheme.textSecondary;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: isSelected ? 42 : 36,
                width: isSelected ? 42 : 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryContainer
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: isSelected ? 24 : 22,
                  color: foregroundColor,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterAddNavButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CenterAddNavButton({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add Transaction',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: isSelected ? 54 : 50,
              width: isSelected ? 54 : 50,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.30),
                    blurRadius: isSelected ? 16 : 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 31,
              ),
            ),
            const SizedBox(height: 1),
            const Text(
              'Add',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
