import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/investment/data/models/investment_model.dart';
import 'package:fintrack/features/investment/presentation/providers/investment_provider.dart';
import 'package:fintrack/features/investment/presentation/providers/investment_type_provider.dart';
import 'package:fintrack/features/investment/presentation/pages/manage_investment_types_screen.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class InvestmentPortfolioScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBackButton;

  const InvestmentPortfolioScreen({
    super.key,
    this.showAppBar = true,
    this.showBackButton = false,
  });

  @override
  State<InvestmentPortfolioScreen> createState() =>
      _InvestmentPortfolioScreenState();
}

class _InvestmentPortfolioScreenState extends State<InvestmentPortfolioScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<InvestmentProvider>(context, listen: false).initInvestments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Investment Portfolio'),
              elevation: 0,
              automaticallyImplyLeading: widget.showBackButton,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Manage Investment Types',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ManageInvestmentTypesScreen(),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      body: Consumer2<InvestmentProvider, SettingsProvider>(
        builder: (context, invProvider, settingsProvider, _) {
          final currencySymbol = settingsProvider.currencySymbol;
          final investments = invProvider.investments;

          if (investments.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.trending_up,
              title: 'No Investments',
              description: 'Start building your investment portfolio',
              actionLabel: 'Add Investment',
              onAction: () => _showAddEditDialog(context),
            );
          }

          double totalInvestment = 0;
          double currentValue = 0;
          double totalGainLoss = 0;

          for (var inv in investments) {
            totalInvestment += inv.getTotalInvestmentValue();
            currentValue += inv.getCurrentValue();
            totalGainLoss += inv.getGainLoss();
          }

          final gainLossPercentage = totalInvestment > 0
              ? ((totalGainLoss / totalInvestment) * 100)
              : 0;

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 240,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: totalGainLoss >= 0
                                ? [Colors.green.shade400, Colors.green.shade600]
                                : [Colors.red.shade400, Colors.red.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Portfolio Value',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$currencySymbol${currentValue.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Invested',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                    Text(
                                      '$currencySymbol${totalInvestment.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Gain/Loss',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                    Text(
                                      '${totalGainLoss >= 0 ? '+' : ''}$currencySymbol${totalGainLoss.toStringAsFixed(2)} (${gainLossPercentage.toStringAsFixed(2)}%)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Investments',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${investments.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: investments.length,
                  itemBuilder: (context, index) {
                    final inv = investments[index];
                    return _InvestmentCard(
                      investment: inv,
                      onEdit: () => _showAddEditDialog(context, inv),
                      onDelete: () => _deleteInvestment(context, inv),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, [Investment? investment]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddEditInvestmentScreen(investment: investment),
    );
  }

  void _deleteInvestment(BuildContext context, Investment investment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Investment'),
        content: const Text('Are you sure you want to delete this investment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<InvestmentProvider>(context, listen: false)
                  .deleteInvestment(investment.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Investment deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _InvestmentCard extends StatelessWidget {
  final Investment investment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InvestmentCard({
    required this.investment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final gainLoss = investment.getGainLoss();
    final gainLossPercentage = investment.getGainLossPercentage();
    final isProfit = investment.isProfit();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        investment.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        investment.type,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: onEdit,
                      child: const Text('Edit'),
                    ),
                    PopupMenuItem(
                      onTap: onDelete,
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invested Amount',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${investment.currency} ${investment.getTotalInvestmentValue().toStringAsFixed(2)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (investment.quantity != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${investment.quantity}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                if (investment.buyPrice != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit Price',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${investment.currency} ${investment.buyPrice!.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isProfit ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Value',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${investment.currency} ${investment.getCurrentValue().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isProfit
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isProfit ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gain/Loss',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${isProfit ? '+' : ''} ${investment.currency} ${gainLoss.toStringAsFixed(2)} (${gainLossPercentage.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isProfit
                          ? Colors.green.shade700
                          : Colors.red.shade700,
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

class AddEditInvestmentScreen extends StatefulWidget {
  final Investment? investment;

  const AddEditInvestmentScreen({super.key, this.investment});

  @override
  State<AddEditInvestmentScreen> createState() =>
      _AddEditInvestmentScreenState();
}

class _AddEditInvestmentScreenState extends State<AddEditInvestmentScreen> {
  late TextEditingController _nameController;
  late TextEditingController _investedAmountController;
  late TextEditingController _currentValueController;
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _notesController;
  DateTime? _selectedInvestmentDate;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    if (widget.investment != null) {
      _nameController = TextEditingController(text: widget.investment!.name);
      _investedAmountController = TextEditingController(
          text: widget.investment!.investedAmount?.toStringAsFixed(2) ??
              widget.investment!.getTotalInvestmentValue().toStringAsFixed(2));
      _currentValueController = TextEditingController(
          text: widget.investment!.currentValue?.toStringAsFixed(2) ?? '');
      _quantityController = TextEditingController(
          text: widget.investment!.quantity?.toString() ?? '');
      _unitPriceController = TextEditingController(
          text: widget.investment!.buyPrice?.toStringAsFixed(2) ?? '');
      _notesController =
          TextEditingController(text: widget.investment!.notes ?? '');
      _selectedInvestmentDate = widget.investment!.purchaseDate;
      _selectedType = widget.investment!.type;
    } else {
      _nameController = TextEditingController();
      _investedAmountController = TextEditingController();
      _currentValueController = TextEditingController();
      _quantityController = TextEditingController();
      _unitPriceController = TextEditingController();
      _notesController = TextEditingController();
      _selectedInvestmentDate = null;
      // Get first investment type from provider or use default
      final typeProvider =
          Provider.of<InvestmentTypeProvider>(context, listen: false);
      _selectedType = typeProvider.investmentTypes.isNotEmpty
          ? typeProvider.investmentTypes.first.name
          : 'Other';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _investedAmountController.dispose();
    _currentValueController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.investment != null
                    ? 'Edit Investment'
                    : 'Add Investment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Investment Name *',
                  hintText: 'e.g., Apple Inc',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<InvestmentTypeProvider>(
                builder: (context, typeProvider, child) {
                  final types = typeProvider.investmentTypes;

                  // Ensure selected type exists in the list
                  if (!types.any((t) => t.name == _selectedType) &&
                      types.isNotEmpty) {
                    _selectedType = types.first.name;
                  }

                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Investment Type *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        items: types
                            .map((t) => DropdownMenuItem(
                                  value: t.name,
                                  child: Text(t.name),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() {
                          _selectedType = value ??
                              (types.isNotEmpty ? types.first.name : 'Other');
                        }),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _investedAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Invested Amount *',
                  hintText: '0.00',
                  helperText: 'Total amount invested',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _currentValueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Current Value (Optional)',
                  hintText: '0.00',
                  helperText: 'Current market value',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Investment Date (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_selectedInvestmentDate != null
                      ? _formatDate(_selectedInvestmentDate!)
                      : 'Select date'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Total Units (Optional)',
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _unitPriceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Unit Price (Optional)',
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any notes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveInvestment(context),
                  child: Text(widget.investment != null
                      ? 'Update Investment'
                      : 'Add Investment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedInvestmentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedInvestmentDate = picked);
    }
  }

  void _saveInvestment(BuildContext context) {
    // Validate mandatory fields
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter investment name')),
      );
      return;
    }

    if (_investedAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter invested amount')),
      );
      return;
    }

    // Validate invested amount
    final investedAmount = double.tryParse(_investedAmountController.text);
    if (investedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid invested amount')),
      );
      return;
    }

    // Parse optional fields
    final currentValue = _currentValueController.text.isNotEmpty
        ? double.tryParse(_currentValueController.text)
        : null;
    final quantity = _quantityController.text.isNotEmpty
        ? double.tryParse(_quantityController.text)
        : null;
    final unitPrice = _unitPriceController.text.isNotEmpty
        ? double.tryParse(_unitPriceController.text)
        : null;

    // Validate optional numeric fields
    if (_currentValueController.text.isNotEmpty && currentValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid current value')),
      );
      return;
    }

    if (_quantityController.text.isNotEmpty && quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    if (_unitPriceController.text.isNotEmpty && unitPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid unit price')),
      );
      return;
    }

    try {
      final currencyCode =
          Provider.of<SettingsProvider>(context, listen: false).currency;

      final notes = _notesController.text.trim();

      final investment = widget.investment != null
          ? widget.investment!.copyWith(
              name: _nameController.text,
              type: _selectedType,
              investedAmount: investedAmount,
              currentValue: currentValue,
              quantity: quantity,
              buyPrice: unitPrice,
              currentPrice: null,
              purchaseDate: _selectedInvestmentDate,
              currency: currencyCode,
              notes: notes.isEmpty ? null : notes,
            )
          : Investment(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text,
              type: _selectedType,
              investedAmount: investedAmount,
              currentValue: currentValue,
              quantity: quantity,
              buyPrice: unitPrice,
              currentPrice: null,
              purchaseDate: _selectedInvestmentDate,
              createdAt: DateTime.now(),
              currency: currencyCode,
              notes: notes.isEmpty ? null : notes,
            );

      if (widget.investment != null) {
        Provider.of<InvestmentProvider>(context, listen: false)
            .updateInvestment(investment);
      } else {
        Provider.of<InvestmentProvider>(context, listen: false)
            .addInvestment(investment);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.investment != null
              ? 'Investment updated'
              : 'Investment added'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving investment: ${e.toString()}')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
