import 'package:flutter/material.dart';

import '../../data/settings_repository.dart';
import 'simple_manage_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SettingsRepository();

    return SimpleManageScreen(
      title: 'Categories',
      addLabel: 'Add Category',
      icon: Icons.category_rounded,
      loadItems: repository.getCategories,
      saveItem: ({int? id, required String name}) {
        return repository.saveCategory(id: id, name: name);
      },
      deleteItem: repository.softDeleteCategory,
    );
  }
}