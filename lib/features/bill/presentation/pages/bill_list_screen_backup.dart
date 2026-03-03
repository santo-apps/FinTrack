import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/bill/data/models/bill_model.dart';
import 'package:fintrack/features/bill/presentation/providers/bill_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class BillListScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBackButton;

  const BillListScreen({
    super.key,
    this.showAppBar = true,
    this.showBackButton = false,
  });

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<BillProvider>(context, listen: false).initBills();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? CustomAppBar(
              title: 'Bill Reminders',
              showBackButton: widget.showBackButton,
            )
          : null,
      body: Consumer<BillProvider>(
        builder: (context, billProvider, _) {
          // Show all bills, not just upcoming/overdue
          final allBills = billProvider.bills;

          // Debug info
          print('Total bills in database: ${allBills.length}');
          print('Upcoming bills: ${billProvider.upcomingBills.length}');
          print('Overdue bills: ${billProvider.overdueBills.length}');

          if (allBills.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.receipt_long,
              title: 'No Bills',
              description: 'Add your first bill to track payments',
              actionLabel: 'Add Bill',
              onAction: () => _showAddEditBillDialog(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => billProvider.initBills(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allBills.length,
              itemBuilder: (context, index) {
                // Sort bills by due date
                final sortedBills = List<Bill>.from(allBills)
                  ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
                final bill = sortedBills[index];
                final isOverdue = bill.isOverdue();
                return _BillCard(
                  bill: bill,
                  isOverdue: isOverdue,
                  onEdit: () => _showAddEditBillDialog(context, bill),
                  onDelete: () => _deleteBill(context, bill),
                  onMarkPaid: () => _markBillPaid(context, bill),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBillDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditBillDialog(BuildContext context, [Bill? bill]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEditBillScreen(bill: bill),
    );
  }

  void _deleteBill(BuildContext context, Bill bill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: const Text('Are you sure you want to delete this bill?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<BillProvider>(context, listen: false)
                  .deleteBill(bill.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bill deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _markBillPaid(BuildContext context, Bill bill) {
    final updatedBill = bill.copyWith(isPaid: true, paidDate: DateTime.now());
    Provider.of<BillProvider>(context, listen: false).updateBill(updatedBill);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bill marked as paid')),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Bill bill;
  final bool isOverdue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarkPaid;

  const _BillCard({
    required this.bill,
    required this.isOverdue,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMenu(context),
      child: Card(
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
                          bill.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${bill.currency} ${bill.amount.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bill.isPaid ? 'PAID' : 'PENDING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: bill.isPaid
                            ? Colors.green.shade700
                            : (isOverdue
                                ? Colors.red.shade700
                                : Colors.orange.shade700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due: ${_formatDate(bill.dueDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (!bill.isPaid)
                    Text(
                      '${bill.getDaysUntilDue()} days left',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              if (bill.notes != null && bill.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  bill.notes!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (!bill.isPaid) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onMarkPaid,
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as Paid'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class AddEditBillScreen extends StatefulWidget {
  final Bill? bill;

  const AddEditBillScreen({super.key, this.bill});

  @override
  State<AddEditBillScreen> createState() => _AddEditBillScreenState();
}

class _AddEditBillScreenState extends State<AddEditBillScreen> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _selectedDueDate;
  late bool _isRecurring;
  late String _recurringFrequency;

  @override
  void initState() {
    super.initState();
    if (widget.bill != null) {
      _nameController = TextEditingController(text: widget.bill!.name);
      _amountController =
          TextEditingController(text: widget.bill!.amount.toString());
      _notesController = TextEditingController(text: widget.bill!.notes ?? '');
      _selectedDueDate = widget.bill!.dueDate;
      _isRecurring = widget.bill!.isRecurring;
      _recurringFrequency = widget.bill!.recurringFrequency ?? 'monthly';
    } else {
      _nameController = TextEditingController();
      _amountController = TextEditingController();
      _notesController = TextEditingController();
      _selectedDueDate = DateTime.now().add(const Duration(days: 7));
      _isRecurring = false;
      _recurringFrequency = 'monthly';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              widget.bill != null ? 'Edit Bill' : 'Add Bill',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Bill Name',
                hintText: 'e.g., Electricity Bill',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_formatDate(_selectedDueDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Add any additional notes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Recurring Bill'),
              value: _isRecurring,
              onChanged: (value) =>
                  setState(() => _isRecurring = value ?? false),
            ),
            if (_isRecurring) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<String>(
                  value: _recurringFrequency,
                  isExpanded: true,
                  items: const ['monthly', 'quarterly', 'yearly']
                      .map((f) => DropdownMenuItem(
                          value: f, child: Text(f.toUpperCase())))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _recurringFrequency = value ?? 'monthly'),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveBill(context),
                child: Text(widget.bill != null ? 'Update Bill' : 'Add Bill'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  void _saveBill(BuildContext context) {
    if (_nameController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final currencyCode =
        Provider.of<SettingsProvider>(context, listen: false).currency;

    final bill = widget.bill != null
        ? widget.bill!.copyWith(
            name: _nameController.text,
            amount: double.parse(_amountController.text),
            dueDate: _selectedDueDate,
            notes: _notesController.text,
            currency: currencyCode,
            isRecurring: _isRecurring,
            recurringFrequency: _isRecurring ? _recurringFrequency : null,
          )
        : Bill(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: _nameController.text,
            amount: double.parse(_amountController.text),
            dueDate: _selectedDueDate,
            createdAt: DateTime.now(),
            notes: _notesController.text,
            currency: currencyCode,
            isRecurring: _isRecurring,
            recurringFrequency: _isRecurring ? _recurringFrequency : null,
          );

    if (widget.bill != null) {
      Provider.of<BillProvider>(context, listen: false).updateBill(bill);
    } else {
      Provider.of<BillProvider>(context, listen: false).addBill(bill);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.bill != null ? 'Bill updated' : 'Bill added',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
