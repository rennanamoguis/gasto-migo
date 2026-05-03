import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/settings_repository.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final repository = SettingsRepository();

  bool isLoading = true;
  List<Map<String, dynamic>> accounts = [];

  final accountTypes = const [
    'cash',
    'bank',
    'e-wallet',
    'card',
    'other',
  ];

  final currencies = const [
    {'code': 'PHP', 'symbol': '₱', 'name': 'Philippine Peso'},
    {'code': 'USD', 'symbol': r'$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'SGD', 'symbol': r'$', 'name': 'Singapore Dollar'},
    {'code': 'AUD', 'symbol': r'$', 'name': 'Australian Dollar'},
    {'code': 'CAD', 'symbol': r'$', 'name': 'Canadian Dollar'},
    {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
    {'code': 'KRW', 'symbol': '₩', 'name': 'South Korean Won'},
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
  ];

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    setState(() => isLoading = true);

    try {
      final result = await repository.getAccounts();

      if (!mounted) return;

      setState(() {
        accounts = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> openForm({Map<String, dynamic>? account}) async {
    final nameController = TextEditingController(
      text: account?['name']?.toString() ?? '',
    );

    String selectedType = account?['account_type']?.toString() ?? 'cash';
    String selectedCurrency = account?['currency']?.toString() ?? 'PHP';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(account == null ? 'Add Account' : 'Edit Account'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Account Type',
                      ),
                      items: accountTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                      ),
                      items: currencies.map((currency) {
                        return DropdownMenuItem<String>(
                          value: currency['code'],
                          child: Text(
                            '${currency['symbol']} ${currency['code']} - ${currency['name']}',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedCurrency = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();

                    if (name.isEmpty) return;

                    Navigator.pop(context, {
                      'name': name,
                      'account_type': selectedType,
                      'currency': selectedCurrency,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    await repository.saveAccount(
      id: account?['id'] as int?,
      name: result['name']!,
      accountType: result['account_type']!,
      currency: result['currency']!,
    );

    await loadAccounts();
  }

  Future<void> confirmDelete(Map<String, dynamic> account) async {
    final id = account['id'] as int;
    final name = account['name']?.toString() ?? 'this account';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: Text('Delete $name?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await repository.softDeleteAccount(id);
    await loadAccounts();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String getCurrencySymbol(String code) {
    final found = currencies.where((currency) => currency['code'] == code);

    if (found.isEmpty) return code;

    return found.first['symbol']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            onPressed: () => openForm(),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: loadAccounts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (accounts.isEmpty)
              AppCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppTheme.primary,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No accounts yet',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => openForm(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Account'),
                    ),
                  ],
                ),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (int index = 0; index < accounts.length; index++) ...[
                      ListTile(
                        leading: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppTheme.primary,
                        ),
                        title: Text(
                          accounts[index]['name']?.toString() ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${accounts[index]['account_type'] ?? 'cash'} • '
                              '${getCurrencySymbol(accounts[index]['currency']?.toString() ?? 'PHP')} '
                              '${accounts[index]['currency'] ?? 'PHP'}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              openForm(account: accounts[index]);
                            }

                            if (value == 'delete') {
                              confirmDelete(accounts[index]);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                      if (index != accounts.length - 1) const Divider(),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openForm(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}