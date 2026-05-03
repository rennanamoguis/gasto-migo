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
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onTabSelected,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                label: 'Transactions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline_rounded),
                label: 'Add',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
