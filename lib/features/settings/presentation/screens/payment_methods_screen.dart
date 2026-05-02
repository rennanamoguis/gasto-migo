import 'package:flutter/material.dart';

import '../../data/settings_repository.dart';
import 'simple_manage_screen.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SettingsRepository();

    return SimpleManageScreen(
      title: 'Payment Methods',
      addLabel: 'Add Payment Method',
      icon: Icons.payment_rounded,
      loadItems: repository.getPaymentMethods,
      saveItem: ({int? id, required String name}) {
        return repository.savePaymentMethod(id: id, name: name);
      },
      deleteItem: repository.softDeletePaymentMethod,
    );
  }
}