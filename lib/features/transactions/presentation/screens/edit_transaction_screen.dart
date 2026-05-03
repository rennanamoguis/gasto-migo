import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../models/account_model.dart';
import '../../../../models/category_model.dart';
import '../../../../models/expense_transaction.dart';
import '../../../../models/expense_transaction_item.dart';
import '../../../../models/payment_method_model.dart';
import '../../../../repositories/lookup_repository.dart';
import '../../../../repositories/transaction_repository.dart';
import '../../../add_transaction/presentation/models/transaction_item_form.dart';
import '../../../../core/utils/app_format_utils.dart';
import '../../../../models/app_preferences.dart';
import '../../../../features/settings/data/settings_repository.dart';

class EditTransactionScreen extends StatefulWidget {
  final int transactionId;

  const EditTransactionScreen({super.key, required this.transactionId});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _PickerCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableItemRow extends StatelessWidget {
  final TransactionItemForm item;
  final VoidCallback onRemove;
  final String currencySymbol;

  const _EditableItemRow({required this.item, required this.onRemove, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.drag_handle_rounded,
          color: AppTheme.textSecondary,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.itemName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${item.quantity} ${item.unit} x ${MoneyUtils.formatAmount(
                  item.unitPriceAmount,
                  currencySymbol: currencySymbol,
                )}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          MoneyUtils.formatAmount(
            item.subtotalAmount,
            currencySymbol: currencySymbol,
          ),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded, color: AppTheme.error),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _EditAddItemSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final String currencySymbol;

  const _EditAddItemSheet({required this.categories, required this.currencySymbol});

  @override
  State<_EditAddItemSheet> createState() => _EditAddItemSheetState();
}

class _EditAddItemSheetState extends State<_EditAddItemSheet> {
  final itemNameController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final unitController = TextEditingController(text: 'pc');
  final unitPriceController = TextEditingController();
  final discountController = TextEditingController(text: '0');
  final taxController = TextEditingController(text: '0');
  final notesController = TextEditingController();

  int? selectedCategoryId;

  int get unitPriceAmount {
    return MoneyUtils.pesosToCentavos(unitPriceController.text);
  }

  int get discountAmount {
    return MoneyUtils.pesosToCentavos(discountController.text);
  }

  int get taxAmount {
    return MoneyUtils.pesosToCentavos(taxController.text);
  }

  double get quantity {
    return double.tryParse(quantityController.text.trim()) ?? 0;
  }

  int get subtotalAmount {
    final gross = (quantity * unitPriceAmount).round();
    return gross - discountAmount + taxAmount;
  }

  void saveItem() {
    final itemName = itemNameController.text.trim();
    final unit = unitController.text.trim();

    if (itemName.isEmpty) {
      showMessage('Please enter item name.');
      return;
    }

    if (quantity <= 0) {
      showMessage('Quantity must be greater than zero.');
      return;
    }

    if (unitPriceAmount <= 0) {
      showMessage('Unit price must be greater than zero.');
      return;
    }

    if (discountAmount < 0 || taxAmount < 0) {
      showMessage('Discount and tax cannot be negative.');
      return;
    }

    if (subtotalAmount < 0) {
      showMessage('Subtotal cannot be negative.');
      return;
    }

    final item = TransactionItemForm(
      itemName: itemName,
      categoryId: selectedCategoryId,
      quantity: quantity,
      unit: unit.isEmpty ? 'pc' : unit,
      unitPriceAmount: unitPriceAmount,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
    );

    Navigator.pop(context, item);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    itemNameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    unitPriceController.dispose();
    discountController.dispose();
    taxController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Add Item',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('No category'),
                  ),
                  ...widget.categories.map((category) {
                    return DropdownMenuItem<int?>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCategoryId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Unit Price',
                  prefixText: '${widget.currencySymbol} ',
                  prefixIcon: const Icon(Icons.payments_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: discountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Discount',
                        prefixText: '${widget.currencySymbol} ',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: taxController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Tax',
                        prefixText: '${widget.currencySymbol} ',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Item Notes',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Item Subtotal',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      MoneyUtils.formatAmount(
                        subtotalAmount,
                        currencySymbol: widget.currencySymbol,
                      ),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: saveItem,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Item'),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final merchantController = TextEditingController();
  final notesController = TextEditingController();

  final lookupRepository = LookupRepository();
  final transactionRepository = TransactionRepository();
  final settingsRepository = SettingsRepository();
  final uuid = const Uuid();

  List<Map<String, dynamic>> merchants = [];

  AppPreferences preferences = AppPreferences.defaults();

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  List<CategoryModel> categories = [];
  List<PaymentMethodModel> paymentMethods = [];
  List<AccountModel> accounts = [];

  int? selectedPaymentMethodId;
  int? selectedAccountId;

  String transactionDate = '';
  String transactionTime = '';

  List<TransactionItemForm> items = [];

  int get subtotalAmount {
    return items.fold<int>(0, (sum, item) => sum + item.subtotalAmount);
  }

  int get discountAmount {
    return items.fold<int>(0, (sum, item) => sum + item.discountAmount);
  }

  int get taxAmount {
    return items.fold<int>(0, (sum, item) => sum + item.taxAmount);
  }

  int get extraAmount => 0;

  int get totalAmount => subtotalAmount + extraAmount;

  @override
  void initState() {
    super.initState();
    loadEditData();
  }

  Future<void> loadEditData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedPreferences = await settingsRepository.getPreferences();

      final loadedCategories = await lookupRepository.getCategories();
      final loadedPaymentMethods = await lookupRepository.getPaymentMethods();
      final loadedAccounts = await lookupRepository.getAccounts();
      final loadedMerchants = await lookupRepository.getMerchants();

      final transaction = await transactionRepository.getTransactionById(
        widget.transactionId,
      );

      if (transaction == null) {
        throw Exception('Transaction not found.');
      }

      final loadedItems = await transactionRepository.getItemsByTransactionId(
        widget.transactionId,
      );

      final merchantName =
          transaction['merchant_name']?.toString() ??
          transaction['title']?.toString() ??
          '';

      final mappedItems = loadedItems.map((item) {
        return TransactionItemForm(
          itemName: item['item_name']?.toString() ?? '',
          categoryId: item['category_id'] as int?,
          quantity: (item['quantity'] as num? ?? 1).toDouble(),
          unit: item['unit']?.toString() ?? 'pc',
          unitPriceAmount: _readInt(item['unit_price_amount']),
          discountAmount: _readInt(item['discount_amount']),
          taxAmount: _readInt(item['tax_amount']),
          notes: item['notes']?.toString(),
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        preferences = loadedPreferences;
        categories = loadedCategories;
        paymentMethods = loadedPaymentMethods;
        accounts = loadedAccounts;

        merchantController.text = merchantName;
        notesController.text = transaction['notes']?.toString() ?? '';

        selectedPaymentMethodId = transaction['payment_method_id'] as int?;
        selectedAccountId = transaction['account_id'] as int?;

        transactionDate = transaction['transaction_date']?.toString() ?? '';
        transactionTime = transaction['transaction_time']?.toString() ?? '';

        merchants = loadedMerchants.map((merchant) {
          return {
            'id': merchant.id,
            'name': merchant.name,
          };
        }).toList();

        items = mappedItems;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> pickDate() async {
    final currentDate = DateTime.tryParse(transactionDate) ?? DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    setState(() {
      transactionDate = pickedDate.toIso8601String().substring(0, 10);
    });
  }

  Future<void> pickTime() async {
    final parts = transactionTime.split(':');

    final initialTime = TimeOfDay(
      hour: int.tryParse(parts.first) ?? TimeOfDay.now().hour,
      minute: parts.length > 1
          ? int.tryParse(parts[1]) ?? TimeOfDay.now().minute
          : TimeOfDay.now().minute,
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null) return;

    setState(() {
      final hour = pickedTime.hour.toString().padLeft(2, '0');
      final minute = pickedTime.minute.toString().padLeft(2, '0');
      transactionTime = '$hour:$minute';
    });
  }

  Future<void> openAddItemSheet() async {
    final item = await showModalBottomSheet<TransactionItemForm>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _EditAddItemSheet(
          categories: categories,
          currencySymbol: preferences.currencySymbol,
        );
      },
    );

    if (item == null) return;

    setState(() {
      items.add(item);
    });
  }

  void removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  Future<void> saveChanges() async {
    final merchantName = merchantController.text.trim();

    if (merchantName.isEmpty) {
      showMessage('Please enter the merchant or store name.');
      return;
    }

    if (items.isEmpty) {
      showMessage('Please add at least one item.');
      return;
    }

    if (selectedPaymentMethodId == null) {
      showMessage('Please select a payment method.');
      return;
    }

    if (selectedAccountId == null) {
      showMessage('Please select an account.');
      return;
    }

    setState(() => isSaving = true);

    try {
      final merchantId = await lookupRepository.findOrCreateMerchant(
        merchantName,
      );

      final now = DateTime.now().toIso8601String();

      final transaction = ExpenseTransaction(
        uuid: uuid.v4(),
        merchantId: merchantId,
        title: merchantName,
        transactionDate: transactionDate,
        transactionTime: transactionTime,
        paymentMethodId: selectedPaymentMethodId,
        accountId: selectedAccountId,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        subtotalAmount: subtotalAmount,
        discountAmount: discountAmount,
        taxAmount: taxAmount,
        extraAmount: extraAmount,
        totalAmount: totalAmount,
        itemCount: items.length,
        receiptCount: 0,
        createdAt: now,
        updatedAt: now,
        syncStatus: 'pending_update',
      );

      final transactionItems = items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        return ExpenseTransactionItem(
          uuid: uuid.v4(),
          lineNo: index + 1,
          itemName: item.itemName,
          normalizedItemName: item.itemName.trim().toLowerCase(),
          categoryId: item.categoryId,
          quantity: item.quantity,
          unit: item.unit.isEmpty ? null : item.unit,
          unitPriceAmount: item.unitPriceAmount,
          discountAmount: item.discountAmount,
          taxAmount: item.taxAmount,
          subtotalAmount: item.subtotalAmount,
          notes: item.notes,
          createdAt: now,
          updatedAt: now,
          syncStatus: 'pending_update',
        );
      }).toList();

      await transactionRepository.updateTransaction(
        transactionId: widget.transactionId,
        transaction: transaction,
        items: transactionItems,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction updated.')));

      Navigator.pop(context, true);
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    merchantController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Edit Transaction')),
        body: LoadingView(message: 'Loading transaction...'),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Transaction')),
        body: EmptyStateView(
          icon: Icons.error_outline_rounded,
          title: 'Unable to edit transaction',
          message: errorMessage!,
          actionLabel: 'Try Again',
          onActionPressed: loadEditData,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
        actions: [
          IconButton(
            onPressed: isSaving ? null : saveChanges,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          AppCard(
            child: Column(
              children: [
                _EditMerchantAutocompleteField(
                  controller: merchantController,
                  merchants: merchants,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PickerCard(
                        label: 'Date',
                        value: AppFormatUtils.formatDate(
                          transactionDate,
                          dateFormat: preferences.dateFormat,
                        ),
                        icon: Icons.calendar_today_rounded,
                        onTap: pickDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerCard(
                        label: 'Time',
                        value: AppFormatUtils.formatTime(
                          transactionTime,
                          timeFormat: preferences.timeFormat,
                        ),
                        icon: Icons.access_time_rounded,
                        onTap: pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedPaymentMethodId,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.payment_rounded),
                  ),
                  items: paymentMethods.map((method) {
                    return DropdownMenuItem<int>(
                      value: method.id,
                      child: Text(method.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethodId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Account',
                    prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                  ),
                  items: accounts.map((account) {
                    return DropdownMenuItem<int>(
                      value: account.id,
                      child: Text(account.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAccountId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.notes_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton.icon(
                onPressed: openAddItemSheet,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Item'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          AppCard(
            child: Column(
              children: [
                for (int index = 0; index < items.length; index++) ...[
                  _EditableItemRow(
                    item: items[index],
                    currencySymbol: preferences.currencySymbol,
                    onRemove: () => removeItem(index),
                  ),
                  if (index != items.length - 1) const Divider(height: 20),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          AppCard(
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Subtotal',
                  amount: MoneyUtils.formatAmount(
                    subtotalAmount,
                    currencySymbol: preferences.currencySymbol,
                  ),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Item Discounts',
                  amount: MoneyUtils.formatAmount(
                    discountAmount,
                    currencySymbol: preferences.currencySymbol,
                  ),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Item Tax',
                  amount: MoneyUtils.formatAmount(
                    taxAmount,
                    currencySymbol: preferences.currencySymbol,
                  ),
                ),
                const Divider(height: 24),
                _SummaryRow(
                  label: 'Total (${items.length} items)',
                  amount: MoneyUtils.formatAmount(
                    totalAmount,
                    currencySymbol: preferences.currencySymbol,
                  ),
                  isTotal: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: isSaving ? null : saveChanges,
            icon: isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(isSaving ? 'Saving...' : 'Save Changes'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  int _readInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

class _EditMerchantAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final List<Map<String, dynamic>> merchants;

  const _EditMerchantAutocompleteField({
    required this.controller,
    required this.merchants,
  });

  @override
  State<_EditMerchantAutocompleteField> createState() =>
      _EditMerchantAutocompleteFieldState();
}

class _EditMerchantAutocompleteFieldState
    extends State<_EditMerchantAutocompleteField> {
  late final FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Map<String, dynamic>>(
      textEditingController: widget.controller,
      focusNode: focusNode,
      displayStringForOption: (option) {
        return option['name']?.toString() ?? '';
      },
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();

        if (widget.merchants.isEmpty) {
          return const Iterable<Map<String, dynamic>>.empty();
        }

        if (query.isEmpty) {
          return widget.merchants.take(8);
        }

        return widget.merchants.where((merchant) {
          final name = merchant['name']?.toString().toLowerCase() ?? '';
          return name.contains(query);
        }).take(8);
      },
      onSelected: (merchant) {
        widget.controller.text = merchant['name']?.toString() ?? '';
      },
      fieldViewBuilder: (
          context,
          textEditingController,
          focusNode,
          onFieldSubmitted,
          ) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Merchant / Store',
            hintText: 'Type or select merchant',
            prefixIcon: Icon(Icons.storefront_rounded),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 240,
                maxWidth: 340,
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  final name = option['name']?.toString() ?? '';

                  return ListTile(
                    leading: const Icon(
                      Icons.storefront_rounded,
                      color: AppTheme.primary,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
