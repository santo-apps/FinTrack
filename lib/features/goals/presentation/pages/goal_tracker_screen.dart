import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/goals/data/models/financial_goal_model.dart';
import 'package:fintrack/features/goals/presentation/providers/goal_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class GoalTrackerScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBackButton;

  const GoalTrackerScreen({
    super.key,
    this.showAppBar = true,
    this.showBackButton = false,
  });

  @override
  State<GoalTrackerScreen> createState() => _GoalTrackerScreenState();
}

class _GoalTrackerScreenState extends State<GoalTrackerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<GoalProvider>(context, listen: false).initGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? CustomAppBar(
              title: 'Financial Goals',
              showBackButton: widget.showBackButton,
            )
          : null,
      body: Consumer2<GoalProvider, SettingsProvider>(
        builder: (context, goalProvider, settingsProvider, _) {
          final currencySymbol = settingsProvider.currencySymbol;
          final goals = goalProvider.goals;
          final activeGoals = goalProvider.activeGoals;

          if (goals.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.flag_outlined,
              title: 'No Goals',
              description: 'Set financial goals to track your progress',
              actionLabel: 'Create Goal',
              onAction: () => _showAddEditDialog(context),
            );
          }

          double totalTarget = 0;
          double totalSaved = 0;
          for (var goal in activeGoals) {
            totalTarget += goal.targetAmount;
            totalSaved += goal.currentAmount;
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                if (activeGoals.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade400, Colors.amber.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Progress',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$currencySymbol${totalSaved.toStringAsFixed(2)} / $currencySymbol${totalTarget.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: totalTarget > 0
                                ? (totalSaved / totalTarget).clamp(0, 1)
                                : 0,
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${((totalSaved / totalTarget) * 100).clamp(0, 100).toStringAsFixed(1)}% complete',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Goals (${activeGoals.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _showAddEditDialog(context),
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: activeGoals.length,
                  itemBuilder: (context, index) {
                    final goal = activeGoals[index];
                    return _GoalCard(
                      goal: goal,
                      onEdit: () => _showAddEditDialog(context, goal),
                      onDelete: () => _deleteGoal(context, goal),
                      onAddAmount: () => _showAddProgressDialog(context, goal),
                      currencySymbol: currencySymbol,
                    );
                  },
                ),
                if (goals.where((g) => g.isCompleted).isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Completed Goals',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: goals.where((g) => g.isCompleted).length,
                    itemBuilder: (context, index) {
                      final goal =
                          goals.where((g) => g.isCompleted).toList()[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    goal.goalName,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Completed: ${_formatDate(goal.completedDate!)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        tooltip: 'Add Goal',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, [FinancialGoal? goal]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEditGoalScreen(goal: goal),
    );
  }

  void _showAddProgressDialog(BuildContext context, FinancialGoal goal) {
    showDialog(
      context: context,
      builder: (context) => _AddProgressDialog(goal: goal),
    );
  }

  void _deleteGoal(BuildContext context, FinancialGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<GoalProvider>(context, listen: false)
                  .deleteGoal(goal.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goal deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _GoalCard extends StatelessWidget {
  final FinancialGoal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddAmount;
  final String currencySymbol;

  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
    required this.onAddAmount,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal.getProgressPercentage();
    final remaining = goal.getRemainingAmount();
    final monthlyRequired = goal.getMonthlyRequiredAmount();
    final daysRemaining = goal.getDaysRemaining();

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
                        goal.goalName,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.category,
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
                Text(
                  '$currencySymbol${goal.currentAmount.toStringAsFixed(2)} / $currencySymbol${goal.targetAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${progress.toStringAsFixed(1)}%',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remaining',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '$currencySymbol${remaining.toStringAsFixed(2)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Monthly Required',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '$currencySymbol${monthlyRequired.toStringAsFixed(2)}',
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
            Text(
              '$daysRemaining days left',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAddAmount,
                child: const Text('Add Progress'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddEditGoalScreen extends StatefulWidget {
  final FinancialGoal? goal;

  const AddEditGoalScreen({super.key, this.goal});

  @override
  State<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late TextEditingController _currentController;
  late TextEditingController _descriptionController;
  late DateTime _selectedTargetDate;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController = TextEditingController(text: widget.goal!.goalName);
      _targetController =
          TextEditingController(text: widget.goal!.targetAmount.toString());
      _currentController =
          TextEditingController(text: widget.goal!.currentAmount.toString());
      _descriptionController =
          TextEditingController(text: widget.goal!.description ?? '');
      _selectedTargetDate = widget.goal!.targetDate;
      _selectedCategory = widget.goal!.category;
    } else {
      _nameController = TextEditingController();
      _targetController = TextEditingController();
      _currentController = TextEditingController(text: '0');
      _descriptionController = TextEditingController();
      _selectedTargetDate = DateTime.now().add(const Duration(days: 365));
      _selectedCategory = 'Savings';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    _descriptionController.dispose();
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
              widget.goal != null ? 'Edit Goal' : 'Create Goal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Goal Name',
                hintText: 'e.g., Save for Vacation',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: const [
                    'Savings',
                    'Travel',
                    'Home',
                    'Education',
                    'Car',
                    'Wedding',
                    'Investment',
                    'Other'
                  ]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value ?? 'Savings'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _targetController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Target Amount',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currentController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Current Amount',
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
                  labelText: 'Target Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_formatDate(_selectedTargetDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveGoal(context),
                child:
                    Text(widget.goal != null ? 'Update Goal' : 'Create Goal'),
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
      initialDate: _selectedTargetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _selectedTargetDate = picked);
    }
  }

  void _saveGoal(BuildContext context) {
    if (_nameController.text.isEmpty || _targetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final currencyCode =
        Provider.of<SettingsProvider>(context, listen: false).currency;

    final goal = widget.goal != null
        ? widget.goal!.copyWith(
            goalName: _nameController.text,
            targetAmount: double.parse(_targetController.text),
            currentAmount: double.parse(_currentController.text),
            targetDate: _selectedTargetDate,
            category: _selectedCategory,
            currency: currencyCode,
            description: _descriptionController.text,
          )
        : FinancialGoal(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            goalName: _nameController.text,
            targetAmount: double.parse(_targetController.text),
            currentAmount: double.parse(_currentController.text),
            targetDate: _selectedTargetDate,
            createdAt: DateTime.now(),
            category: _selectedCategory,
            currency: currencyCode,
            description: _descriptionController.text,
          );

    if (widget.goal != null) {
      Provider.of<GoalProvider>(context, listen: false).updateGoal(goal);
    } else {
      Provider.of<GoalProvider>(context, listen: false).addGoal(goal);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.goal != null ? 'Goal updated' : 'Goal created'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _AddProgressDialog extends StatefulWidget {
  final FinancialGoal goal;

  const _AddProgressDialog({required this.goal});

  @override
  State<_AddProgressDialog> createState() => _AddProgressDialogState();
}

class _AddProgressDialogState extends State<_AddProgressDialog> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Progress'),
      content: SingleChildScrollView(
        child: TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount to Add',
            hintText: 'Enter amount',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text) ?? 0;
            if (amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid amount')),
              );
              return;
            }

            final updatedGoal = widget.goal.copyWith(
              currentAmount: widget.goal.currentAmount + amount,
              isCompleted: (widget.goal.currentAmount + amount) >=
                  widget.goal.targetAmount,
              completedDate: (widget.goal.currentAmount + amount) >=
                      widget.goal.targetAmount
                  ? DateTime.now()
                  : null,
            );

            Provider.of<GoalProvider>(context, listen: false)
                .updateGoal(updatedGoal);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Progress added')),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
