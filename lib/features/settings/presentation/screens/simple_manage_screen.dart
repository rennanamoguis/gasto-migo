import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';

class SimpleManageScreen extends StatefulWidget {
  final String title;
  final String addLabel;
  final IconData icon;
  final Future<List<Map<String, dynamic>>> Function() loadItems;
  final Future<void> Function({int? id, required String name}) saveItem;
  final Future<void> Function(int id) deleteItem;

  const SimpleManageScreen({
    super.key,
    required this.title,
    required this.addLabel,
    required this.icon,
    required this.loadItems,
    required this.saveItem,
    required this.deleteItem,
  });

  @override
  State<SimpleManageScreen> createState() => _SimpleManageScreenState();
}

class _SimpleManageScreenState extends State<SimpleManageScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    setState(() => isLoading = true);

    try {
      final result = await widget.loadItems();

      if (!mounted) return;

      setState(() {
        items = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> openForm({Map<String, dynamic>? item}) async {
    final controller = TextEditingController(
      text: item?['name']?.toString() ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? widget.addLabel : 'Edit ${widget.title}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) return;

                Navigator.pop(context, value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null || result.trim().isEmpty) return;

    await widget.saveItem(
      id: item?['id'] as int?,
      name: result.trim(),
    );

    await loadItems();
  }

  Future<void> confirmDelete(Map<String, dynamic> item) async {
    final id = item['id'] as int;
    final name = item['name']?.toString() ?? 'this item';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete item?'),
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

    await widget.deleteItem(id);
    await loadItems();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
        onRefresh: loadItems,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (items.isEmpty)
              AppCard(
                child: Column(
                  children: [
                    Icon(
                      widget.icon,
                      color: AppTheme.primary,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No ${widget.title.toLowerCase()} yet',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => openForm(),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(widget.addLabel),
                    ),
                  ],
                ),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (int index = 0; index < items.length; index++) ...[
                      ListTile(
                        leading: Icon(
                          widget.icon,
                          color: AppTheme.primary,
                        ),
                        title: Text(
                          items[index]['name']?.toString() ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          (items[index]['is_active'] == 0)
                              ? 'Inactive'
                              : 'Active',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              openForm(item: items[index]);
                            }

                            if (value == 'delete') {
                              confirmDelete(items[index]);
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
                      if (index != items.length - 1) const Divider(),
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