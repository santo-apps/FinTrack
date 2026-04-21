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

  Color _activeAccent(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : theme.colorScheme.primary;
  }

  Color _mutedText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Navigation Settings',
        showBackButton: true,
      ),
      body: SafeArea(
        top: false,
        child: Consumer<SettingsProvider>(
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
                    labelColor: _activeAccent(context),
                    unselectedLabelColor: _mutedText(context),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Bottom Nav'),
                      Tab(text: 'Home FAB'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Bottom Navigation Tab
                      ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          contentBottomPadding(context, hasFab: false),
                        ),
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
                      // Home FAB Tab
                      ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          contentBottomPadding(context, hasFab: false),
                        ),
                        children: [
                          _buildTabHeader(
                            context,
                            'Choose FAB items',
                            'Manage and order actions shown in Home FAB',
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
                                  if (selected.length >= _navOptions.length) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'You can select up to 8 items only.'),
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
                                          'At least one Home FAB action should be selected.',
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
                              final id =
                                  settingsProvider.quickActionItems[index];
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
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              ? _activeAccent(context).withOpacity(0.35)
              : Theme.of(context).dividerColor,
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      color: isSelected ? _activeAccent(context).withOpacity(0.08) : null,
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
                color: _activeAccent(context).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                option.icon,
                color: _activeAccent(context),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : _mutedText(context),
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
              color: _mutedText(context),
              size: 20,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _activeAccent(context).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                option.icon,
                color: _activeAccent(context),
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
