import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/settings_repository.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final repository = SettingsRepository();

  String selectedCode = 'PHP';

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
    {'code': 'HKD', 'symbol': r'$', 'name': 'Hong Kong Dollar'},
    {'code': 'THB', 'symbol': '฿', 'name': 'Thai Baht'},
    {'code': 'MYR', 'symbol': 'RM', 'name': 'Malaysian Ringgit'},
    {'code': 'IDR', 'symbol': 'Rp', 'name': 'Indonesian Rupiah'},
  ];

  @override
  void initState() {
    super.initState();
    loadCurrency();
  }

  Future<void> loadCurrency() async {
    final code = await repository.getMetaValue('currency_code') ?? 'PHP';

    if (!mounted) return;

    setState(() {
      selectedCode = code;
    });
  }

  Future<void> selectCurrency(Map<String, String> currency) async {
    await repository.setMetaValue('currency_code', currency['code']!);
    await repository.setMetaValue('currency_symbol', currency['symbol']!);
    await repository.setMetaValue('currency_name', currency['name']!);

    if (!mounted) return;

    setState(() {
      selectedCode = currency['code']!;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Currency set to ${currency['code']}.'),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final selected = currencies.firstWhere(
          (currency) => currency['code'] == selectedCode,
      orElse: () => currencies.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(
              children: [
                const Icon(
                  Icons.attach_money_rounded,
                  color: AppTheme.primary,
                  size: 34,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Currency',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selected['symbol']} ${selected['code']} - ${selected['name']}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Select Currency',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int index = 0; index < currencies.length; index++) ...[
                  RadioListTile<String>(
                    value: currencies[index]['code']!,
                    groupValue: selectedCode,
                    onChanged: (_) => selectCurrency(currencies[index]),
                    title: Text(
                      '${currencies[index]['symbol']} ${currencies[index]['code']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(currencies[index]['name']!),
                  ),
                  if (index != currencies.length - 1) const Divider(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Note: Changing currency updates the display symbol for the app. It does not convert existing amounts using exchange rates.',
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
}