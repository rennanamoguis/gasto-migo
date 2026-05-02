import 'package:flutter/material.dart';

import '../../data/settings_repository.dart';
import 'simple_manage_screen.dart';

class MerchantsScreen extends StatelessWidget {
  const MerchantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SettingsRepository();

    return SimpleManageScreen(
      title: 'Merchants',
      addLabel: 'Add Merchant',
      icon: Icons.storefront_rounded,
      loadItems: repository.getMerchants,
      saveItem: ({int? id, required String name}) {
        return repository.saveMerchant(id: id, name: name);
      },
      deleteItem: repository.softDeleteMerchant,
    );
  }
}