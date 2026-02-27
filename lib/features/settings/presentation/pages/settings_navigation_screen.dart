import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class SettingsNavigationScreen extends StatefulWidget {
  final int initialTab;

  const SettingsNavigationScreen({super.key, this.initialTab = 0});

  @override
  State<SettingsNavigationScreen> createState() =>
      _SettingsNavigationScreenState();
}

class _SettingsNavigationScreenState extends State<SettingsNavigationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const List<_NavOption> _navOptions = [
    _NavOption(id: 'expenses', label: 'Expenses', icon: Icons.receipt_long),
    _NavOption(
      id: 'accounts',
      label: 'Accounts',
      icon: Icons.account_balance_wallet,
    ),
    _NavOption(id: 'budget', label: 'Budget', icon: Icons.pie_chart),
    _NavOption(id: 'bills', label: 'Bills', icon: Icons.calendar_today),
    _NavOption(
      id: 'subscriptions',
      label: 'Subscriptions',
      icon: Icons.subscriptions,
    ),
    _NavOption(
      id: 'investments',
      label: 'Investments',
      icon: Icons.trending_up,
    ),
    _NavOption(id: 'goals', label: 'Goals', icon: Icons.flag_outlined),
    _NavOption(id: 'loans', label: 'Loans', icon: Icons.account_balance),
  ];

  static const List<_OverviewOption> _overviewOptions = [
    _OverviewOption(
      id: 'monthly_spending',
      label: 'Monthly Spending',
      icon: Icons.trending_down,
    ),
    _OverviewOption(
      id: 'subscriptions',
      label: 'Subscriptions',
      icon: Icons.subscriptions,
    ),
    _OverviewOption(
      id: 'portfolio_value',
      label: 'Portfolio Value',
      icon: Icons.trending_up,
    ),
    _OverviewOption(
      id: 'total_balance',
      label: 'Total Balance',
      icon: Icons.account_balance_wallet,
    ),
    _OverviewOption(
      id: 'outstanding_loans',
      label: 'Outstanding Loans',
      icon: Icons.account_balance,
    ),
    _OverviewOption(
      id: 'unpaid_bills',
      label: 'Unpaid Bills',
      icon: Icons.calendar_today,
    ),
  ];

  _NavOption _navOptionById(String id) {
    return _navOptions.firstWhere(
      (option) => option.id == id,
      orElse: () => const _NavOption(
        id: 'unknown',
        label: 'Unknown',
        icon: Icons.help_outline,
      ),
    );
  }

  _OverviewOption _overviewOptionById(String id) {
    return _overviewOptions.firstWhere(
      (option) => option.id == id,
      orElse: () => const _OverviewOption(
        id: 'unknown',
        label: 'Unknown',
        icon: Icons.help_outline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Navigation Settings',
        showBackButton: true,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Bottom Nav'),
                    Tab(text: 'Quick Actions'),
                    Tab(text: 'Overview'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Bottom Navigation Tab
                    ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      children: [
                        _buildTabHeader(
                          context,
                          'Select up to 3 items',
                          'Customize your bottom navigation bar',
                        ),
                        const SizedBox(height: 12),
                        ..._navOptions.map((option) {
                          final isSelected = settingsProvider.bottomNavItems
                              .contains(option.id);
                          return _buildNavOptionCard(
                            context,
                            option,
                            isSelected,
                            (value) {
                              final selected = List<String>.from(
                                  settingsProvider.bottomNavItems);

                              if (value == true) {
                                if (selected.length >= 3) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'You can select up to 3 items only.'),
                                    ),
                                  );
                                  return;
                                }
                                selected.add(option.id);
                              } else {
                                if (selected.length <= 1 &&
                                    selected.contains(option.id)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'At least one menu item should be selected.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                selected.remove(option.id);
                              }

                              settingsProvider.setBottomNavItems(selected);
                            },
                          );
                        }),
                        const SizedBox(height: 20),
                        _buildTabHeader(
                          context,
                          'Drag to reorder',
                          'Arrange items as you prefer',
                        ),
                        const SizedBox(height: 12),
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: settingsProvider.bottomNavItems.length,
                          onReorder: (oldIndex, newIndex) {
                            final ordered = List<String>.from(
                                settingsProvider.bottomNavItems);
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = ordered.removeAt(oldIndex);
                            ordered.insert(newIndex, item);
                            settingsProvider.setBottomNavItems(ordered);
                          },
                          itemBuilder: (context, index) {
                            final id = settingsProvider.bottomNavItems[index];
                            final option = _navOptionById(id);
                            return _buildReorderableNavCard(
                              context,
                              key: ValueKey('nav-$id'),
                              option: option,
                            );
                          },
                        ),
                      ],
                    ),
                    // Quick Actions Tab
                    ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      children: [
                        _buildTabHeader(
                          context,
                          'Select up to 3 items',
                          'Choose dashboard quick action shortcuts',
                        ),
                        const SizedBox(height: 12),
                        ..._navOptions.map((option) {
                          final isSelected = settingsProvider.quickActionItems
                              .contains(option.id);
                          return _buildNavOptionCard(
                            context,
                            option,
                            isSelected,
                            (value) {
                              final selected = List<String>.from(
                                  settingsProvider.quickActionItems);

                              if (value == true) {
                                if (selected.length >= 3) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'You can select up to 3 items only.'),
                                    ),
                                  );
                                  return;
                                }
                                selected.add(option.id);
                              } else {
                                if (selected.length <= 1 &&
                                    selected.contains(option.id)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'At least one quick action should be selected.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                selected.remove(option.id);
                              }

                              settingsProvider.setQuickActionItems(selected);
                            },
                          );
                        }),
                        const SizedBox(height: 20),
                        _buildTabHeader(
                          context,
                          'Drag to reorder',
                          'Arrange items as you prefer',
                        ),
                        const SizedBox(height: 12),
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: settingsProvider.quickActionItems.length,
                          onReorder: (oldIndex, newIndex) {
                            final ordered = List<String>.from(
                                settingsProvider.quickActionItems);
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = ordered.removeAt(oldIndex);
                            ordered.insert(newIndex, item);
                            settingsProvider.setQuickActionItems(ordered);
                          },
                          itemBuilder: (context, index) {
                            final id = settingsProvider.quickActionItems[index];
                            final option = _navOptionById(id);
                            return _buildReorderableNavCard(
                              context,
                              key: ValueKey('quick-action-$id'),
                              option: option,
                            );
                          },
                        ),
                      ],
                    ),
                    // Financial Overview Tab
                    ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      children: [
                        _buildTabHeader(
                          context,
                          'Select overview cards',
                          'Choose financial overview cards for dashboard',
                        ),
                        const SizedBox(height: 12),
                        ..._overviewOptions.map((option) {
                          final isSelected = settingsProvider.overviewItems
                              .contains(option.id);
                          return _buildOverviewOptionCard(
                            context,
                            option,
                            isSelected,
                            (value) {
                              final selected = List<String>.from(
                                  settingsProvider.overviewItems);

                              if (value == true) {
                                selected.add(option.id);
                              } else {
                                if (selected.length <= 1 &&
                                    selected.contains(option.id)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'At least one overview card should be selected.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                selected.remove(option.id);
                              }

                              settingsProvider.setOverviewItems(selected);
                            },
                          );
                        }),
                        const SizedBox(height: 20),
                        _buildTabHeader(
                          context,
                          'Drag to reorder',
                          'Arrange cards as you prefer',
                        ),
                        const SizedBox(height: 12),
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: settingsProvider.overviewItems.length,
                          onReorder: (oldIndex, newIndex) {
                            final ordered = List<String>.from(
                                settingsProvider.overviewItems);
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = ordered.removeAt(oldIndex);
                            ordered.insert(newIndex, item);
                            settingsProvider.setOverviewItems(ordered);
                          },
                          itemBuilder: (context, index) {
                            final id = settingsProvider.overviewItems[index];
                            final option = _overviewOptionById(id);
                            return _buildReorderableOverviewCard(
                              context,
                              key: ValueKey('overview-$id'),
                              option: option,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabHeader(
      BuildContext context, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildNavOptionCard(
    BuildContext context,
    _NavOption option,
    bool isSelected,
    ValueChanged<bool?> onChanged,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Theme.of(context).dividerColor,
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      color:
          isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: onChanged,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                option.icon,
                color: Theme.of(context).primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? null : Colors.grey.shade800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableNavCard(
    BuildContext context, {
    required Key key,
    required _NavOption option,
  }) {
    return Card(
      key: key,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.drag_handle,
              color: Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                option.icon,
                color: Theme.of(context).primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewOptionCard(
    BuildContext context,
    _OverviewOption option,
    bool isSelected,
    ValueChanged<bool?> onChanged,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Theme.of(context).dividerColor,
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      color:
          isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: onChanged,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                option.icon,
                color: Theme.of(context).primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? null : Colors.grey.shade800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableOverviewCard(
    BuildContext context, {
    required Key key,
    required _OverviewOption option,
  }) {
    return Card(
      key: key,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.drag_handle,
              color: Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                option.icon,
                color: Theme.of(context).primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavOption {
  final String id;
  final String label;
  final IconData icon;

  const _NavOption({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class _OverviewOption {
  final String id;
  final String label;
  final IconData icon;

  const _OverviewOption({
    required this.id,
    required this.label,
    required this.icon,
  });
}
