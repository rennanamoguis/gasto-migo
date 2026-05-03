import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/add_transaction/presentation/screens/add_transaction_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/transactions/presentation/screens/transactions_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;
  int refreshCounter = 0;

  void onTabSelected(int index) {
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
    final screens = [
      HomeScreen(
        key: ValueKey('home-$refreshCounter'),
        onViewAllTransactions: () => onTabSelected(1),
        onAddTransaction: () => onTabSelected(2),
        onChanged: () => refreshData(),
      ),
      TransactionsScreen(
        key: ValueKey('transactions-$refreshCounter'),
        onAddTransaction: () => onTabSelected(2),
        onChanged: () => refreshData(),
      ),
      AddTransactionScreen(
        key: ValueKey('add-$refreshCounter'),
        onTransactionSaved: () {
          refreshData(goToTab: 0);
        },
      ),
      SettingsScreen(
        onSettingsChanged: () {
          refreshData();
        },
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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

  static const items = [
    _BubbleNavItem(
      icon: Icons.home_rounded,
      label: 'Home',
    ),
    _BubbleNavItem(
      icon: Icons.receipt_long_rounded,
      label: 'Transactions',
    ),
    _BubbleNavItem(
      icon: Icons.add_rounded,
      label: 'Add',
    ),
    _BubbleNavItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = selectedIndex == index;

          return Expanded(
            child: _BubbleNavButton(
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

  const _BubbleNavItem({
    required this.icon,
    required this.label,
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
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: isSelected ? 46 : 42,
              width: isSelected ? 46 : 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryContainer
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: isSelected ? 25 : 23,
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
