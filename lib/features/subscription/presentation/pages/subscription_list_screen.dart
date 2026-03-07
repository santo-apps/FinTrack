import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/settings/presentation/pages/manage_subscription_categories_screen.dart';
import 'package:fintrack/features/subscription/data/models/subscription_model.dart';
import 'package:fintrack/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class SubscriptionListScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBackButton;

  const SubscriptionListScreen({
    super.key,
    this.showAppBar = true,
    this.showBackButton = false,
  });

  @override
  State<SubscriptionListScreen> createState() => _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends State<SubscriptionListScreen> {
  static const String _allCategoriesFilter = 'All';
  String _selectedCategoryFilter = _allCategoriesFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<SubscriptionProvider>().initSubscriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? CustomAppBar(
              title: 'Subscriptions',
              showBackButton: widget.showBackButton,
            )
          : null,
      body: Consumer2<SubscriptionProvider, SettingsProvider>(
        builder: (context, subProvider, settingsProvider, _) {
          final currencySymbol = settingsProvider.currencySymbol;
          final subscriptions = subProvider.subscriptions;

          if (subscriptions.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.subscriptions,
              title: 'No Subscriptions',
              description: 'Track your recurring subscriptions here',
              actionLabel: 'Add Subscription',
              onAction: () => _showAddEditDialog(context),
            );
          }

          final categoryFilters = _buildCategoryFilters(subscriptions);
          if (!categoryFilters.contains(_selectedCategoryFilter)) {
            _selectedCategoryFilter = _allCategoriesFilter;
          }
          final filteredSubscriptions =
              _getFilteredSubscriptions(subscriptions, _selectedCategoryFilter);

          double totalMonthly = 0;
          for (var sub in filteredSubscriptions) {
            totalMonthly += sub.getMonthlyAmount();
          }
          final categoryBreakdown =
              _calculateCategoryBreakdown(filteredSubscriptions);

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surface
                      : null,
                  gradient: Theme.of(context).brightness == Brightness.dark
                      ? null
                      : LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.85),
                            AppTheme.primaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(12),
                  border: Theme.of(context).brightness == Brightness.dark
                      ? Border.all(color: Theme.of(context).dividerColor)
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      'Monthly Cost',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$currencySymbol${totalMonthly.toStringAsFixed(2)}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Across ${filteredSubscriptions.length} subscriptions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categoryFilters.map((category) {
                      final isSelected = category == _selectedCategoryFilter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategoryFilter = category;
                            });
                          },
                          elevation: isSelected ? 4 : 2,
                          pressElevation: 6,
                          shadowColor: Colors.black26,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          selectedColor: AppTheme.primaryColor,
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Theme.of(context).dividerColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          labelStyle:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (categoryBreakdown.isNotEmpty)
                Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Breakdown',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ...categoryBreakdown.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${entry.key} (${entry.value.count})',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  '$currencySymbol${entry.value.monthlyAmount.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredSubscriptions.isEmpty
                    ? Center(
                        child: Text(
                          'No subscriptions in this category',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => subProvider.initSubscriptions(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredSubscriptions.length,
                          itemBuilder: (context, index) {
                            final sub = filteredSubscriptions[index];
                            return _SubscriptionCard(
                              subscription: sub,
                              onEdit: () => _showAddEditDialog(context, sub),
                              onDelete: () => _deleteSubscription(context, sub),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        heroTag: 'subscription_list_fab_add',
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, [Subscription? subscription]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          AddEditSubscriptionScreen(subscription: subscription),
    );
  }

  void _deleteSubscription(BuildContext context, Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription'),
        content:
            const Text('Are you sure you want to delete this subscription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<SubscriptionProvider>(context, listen: false)
                  .deleteSubscription(subscription.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subscription deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Map<String, _CategorySummary> _calculateCategoryBreakdown(
    List<Subscription> subscriptions,
  ) {
    final grouped = <String, _CategorySummary>{};

    for (final subscription in subscriptions) {
      final category = _normalizeCategory(subscription.category);
      final existing = grouped[category];
      final monthlyAmount = subscription.getMonthlyAmount();

      grouped[category] = _CategorySummary(
        count: (existing?.count ?? 0) + 1,
        monthlyAmount: (existing?.monthlyAmount ?? 0) + monthlyAmount,
      );
    }

    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.value.monthlyAmount.compareTo(a.value.monthlyAmount));
    return Map<String, _CategorySummary>.fromEntries(sortedEntries);
  }

  String _normalizeCategory(String? category) {
    final value = category?.trim();
    if (value == null || value.isEmpty) {
      return 'Other';
    }
    return value;
  }

  List<String> _buildCategoryFilters(List<Subscription> subscriptions) {
    final categories = subscriptions
        .map((subscription) => _normalizeCategory(subscription.category))
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return [_allCategoriesFilter, ...categories];
  }

  List<Subscription> _getFilteredSubscriptions(
    List<Subscription> subscriptions,
    String selectedFilter,
  ) {
    if (selectedFilter == _allCategoriesFilter) {
      return subscriptions;
    }

    return subscriptions
        .where(
          (subscription) =>
              _normalizeCategory(subscription.category) == selectedFilter,
        )
        .toList();
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubscriptionCard({
    required this.subscription,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.subscriptions, color: AppTheme.primaryColor),
        ),
        title: Text(
          subscription.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Renews: ${_formatDate(subscription.renewalDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${subscription.currency} ${subscription.cost.toStringAsFixed(2)} / ${subscription.billingCycle}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _displayCategory(subscription.category),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: onEdit,
              child: const Text('Edit'),
            ),
            PopupMenuItem(
              onTap: onDelete,
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: () => _showDetails(context),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(subscription.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('Cost', '${subscription.currency} ${subscription.cost}'),
            _DetailRow(
              'Monthly Amount',
              '${subscription.currency} ${subscription.getMonthlyAmount().toStringAsFixed(2)}',
            ),
            _DetailRow('Billing Cycle', subscription.billingCycle),
            _DetailRow(
              'Renewal Date',
              _formatDate(subscription.renewalDate),
            ),
            _DetailRow('Category', _displayCategory(subscription.category)),
            if (subscription.notes != null) ...[
              const SizedBox(height: 12),
              _DetailRow('Notes', subscription.notes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _displayCategory(String? category) {
    final value = category?.trim();
    if (value == null || value.isEmpty) {
      return 'Other';
    }
    return value;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class AddEditSubscriptionScreen extends StatefulWidget {
  final Subscription? subscription;

  const AddEditSubscriptionScreen({super.key, this.subscription});

  @override
  State<AddEditSubscriptionScreen> createState() =>
      _AddEditSubscriptionScreenState();
}

class _AddEditSubscriptionScreenState extends State<AddEditSubscriptionScreen> {
  late TextEditingController _nameController;
  late TextEditingController _costController;
  late TextEditingController _notesController;
  late DateTime _selectedRenewalDate;
  late String _selectedBillingCycle;
  late String _selectedCategory;
  late bool _autoRenewal;

  @override
  void initState() {
    super.initState();
    if (widget.subscription != null) {
      _nameController = TextEditingController(text: widget.subscription!.name);
      _costController =
          TextEditingController(text: widget.subscription!.cost.toString());
      _notesController =
          TextEditingController(text: widget.subscription!.notes ?? '');
      _selectedRenewalDate = widget.subscription!.renewalDate;
      _selectedBillingCycle = widget.subscription!.billingCycle;
      final initialCategory = widget.subscription!.category?.trim();
      _selectedCategory = (initialCategory == null || initialCategory.isEmpty)
          ? 'Other'
          : initialCategory;
      _autoRenewal = widget.subscription!.autoRenewal;
    } else {
      _nameController = TextEditingController();
      _costController = TextEditingController();
      _notesController = TextEditingController();
      _selectedRenewalDate = DateTime.now().add(const Duration(days: 30));
      _selectedBillingCycle = 'monthly';
      _selectedCategory = 'Other';
      _autoRenewal = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryModels =
        context.watch<SettingsProvider>().subscriptionCategories;
    final categories = categoryModels.map((c) => c.name).toList();
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory =
          categories.contains('Other') ? 'Other' : categories.first;
    }

    return Material(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.subscription != null
                        ? 'Edit Subscription'
                        : 'Add Subscription',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Service Name',
                  hintText: 'e.g., Netflix, Spotify',
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
                      controller: _costController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Cost',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedBillingCycle,
                    items: const ['weekly', 'monthly', 'quarterly', 'yearly']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) => setState(
                        () => _selectedBillingCycle = value ?? 'monthly'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Next Renewal Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_formatDate(_selectedRenewalDate)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ManageSubscriptionCategoriesScreen(),
                      ),
                    );
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage categories'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Auto Renewal'),
                value: _autoRenewal,
                onChanged: (value) =>
                    setState(() => _autoRenewal = value ?? true),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveSubscription(context),
                  child: Text(widget.subscription != null
                      ? 'Update Subscription'
                      : 'Add Subscription'),
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
      initialDate: _selectedRenewalDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedRenewalDate = picked);
    }
  }

  void _saveSubscription(BuildContext context) {
    if (_nameController.text.isEmpty || _costController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final currencyCode =
        Provider.of<SettingsProvider>(context, listen: false).currency;

    final subscription = widget.subscription != null
        ? widget.subscription!.copyWith(
            name: _nameController.text,
            cost: double.parse(_costController.text),
            billingCycle: _selectedBillingCycle,
            renewalDate: _selectedRenewalDate,
            notes: _notesController.text,
            currency: currencyCode,
            category: _selectedCategory,
            autoRenewal: _autoRenewal,
          )
        : Subscription(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: _nameController.text,
            cost: double.parse(_costController.text),
            billingCycle: _selectedBillingCycle,
            renewalDate: _selectedRenewalDate,
            createdAt: DateTime.now(),
            notes: _notesController.text,
            currency: currencyCode,
            category: _selectedCategory,
            autoRenewal: _autoRenewal,
          );

    if (widget.subscription != null) {
      Provider.of<SubscriptionProvider>(context, listen: false)
          .updateSubscription(subscription);
    } else {
      Provider.of<SubscriptionProvider>(context, listen: false)
          .addSubscription(subscription);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.subscription != null
            ? 'Subscription updated'
            : 'Subscription added'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _CategorySummary {
  final int count;
  final double monthlyAmount;

  const _CategorySummary({
    required this.count,
    required this.monthlyAmount,
  });
}
