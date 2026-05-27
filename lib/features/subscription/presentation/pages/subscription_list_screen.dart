import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/core/utils/dropdown_search_utils.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/expense/data/models/expense_model.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:fintrack/features/settings/presentation/pages/manage_subscription_categories_screen.dart';
import 'package:fintrack/features/subscription/data/models/subscription_category_model.dart';
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

class _SubscriptionListScreenState extends State<SubscriptionListScreen>
    with SingleTickerProviderStateMixin {
  static const String _allCategoriesFilter = 'All';
  String _selectedCategoryFilter = _allCategoriesFilter;
  String _searchQuery = '';
  bool _showArchived = false;
  DateTime _activeMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _historyMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  late TabController _tabController;

  void _handleScreenSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 180) return;

    final nextArchived = velocity < 0;
    final targetIndex = nextArchived ? 1 : 0;
    if (_tabController.index == targetIndex) return;
    _tabController.animateTo(targetIndex);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      final isPast = _tabController.index == 1;
      if (_showArchived == isPast) return;
      setState(() {
        _showArchived = isPast;
        _selectedCategoryFilter = _allCategoriesFilter;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<SubscriptionProvider>().initSubscriptions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      body: SafeArea(
        top: false,
        child:
            Consumer3<SubscriptionProvider, SettingsProvider, ExpenseProvider>(
          builder:
              (context, subProvider, settingsProvider, expenseProvider, _) {
            final currencySymbol = settingsProvider.currencySymbol;
            final categoryModels = settingsProvider.subscriptionCategories;
            final categoryByName = {
              for (final category in categoryModels)
                category.name.toLowerCase(): category,
            };

            final subscriptions = _showArchived
                ? subProvider.archivedSubscriptions
                : subProvider.activeSubscriptions;

            final categoryFilters = _buildCategoryFilters(subscriptions);
            if (!categoryFilters.contains(_selectedCategoryFilter)) {
              _selectedCategoryFilter = _allCategoriesFilter;
            }

            final query = _searchQuery.trim().toLowerCase();
            final searchedSubscriptions = query.isEmpty
                ? subscriptions
                : subscriptions.where((subscription) {
                    final haystack = [
                      subscription.name,
                      subscription.category ?? '',
                      subscription.notes ?? '',
                      subscription.billingCycle,
                    ].join(' ').toLowerCase();
                    return haystack.contains(query);
                  }).toList();

            final now = DateTime.now();
            final isCurrentActiveMonth = _activeMonth.year == now.year &&
                _activeMonth.month == now.month;
            final currentDay = now.day;
            final activeMonthMaxDay =
                _daysInMonth(_activeMonth.year, _activeMonth.month);
            final activeReferenceDay = currentDay <= activeMonthMaxDay
                ? currentDay
                : activeMonthMaxDay;
            final today = _showArchived
                ? DateTime(now.year, now.month, now.day)
                : DateTime(
                    _activeMonth.year, _activeMonth.month, activeReferenceDay);

            final filteredSubscriptions = _getFilteredSubscriptions(
              searchedSubscriptions,
              _selectedCategoryFilter,
            )..sort((a, b) {
                final aAnchor = _statusAnchorRenewalDate(a, today);
                final bAnchor = _statusAnchorRenewalDate(b, today);
                return aAnchor.compareTo(bAnchor);
              });
            final hasActiveFilter = _searchQuery.trim().isNotEmpty ||
                _selectedCategoryFilter != _allCategoriesFilter;

            double totalMonthly = 0;
            for (var sub in filteredSubscriptions) {
              totalMonthly += sub.getMonthlyAmount();
            }
            final overdueSubscriptions = _showArchived
                ? <Subscription>[]
                : filteredSubscriptions.where((subscription) {
                    final renewal = _statusAnchorRenewalDate(
                      subscription,
                      today,
                    );
                    if (!renewal.isBefore(today)) {
                      return false;
                    }
                    return !_isCurrentDueSettled(expenseProvider, subscription);
                  }).toList();
            final dueSoonSubscriptions = _showArchived
                ? <Subscription>[]
                : !isCurrentActiveMonth
                    ? <Subscription>[]
                    : filteredSubscriptions.where((subscription) {
                        final renewal = _statusAnchorRenewalDate(
                          subscription,
                          today,
                        );
                        final days = renewal.difference(today).inDays;
                        if (days < 0 || days > 7) {
                          return false;
                        }
                        return !_isCurrentDueSettled(
                            expenseProvider, subscription);
                      }).toList();
            final upcomingSubscriptions = _showArchived
                ? filteredSubscriptions
                : filteredSubscriptions.where((subscription) {
                    final renewal = _statusAnchorRenewalDate(
                      subscription,
                      today,
                    );
                    final days = renewal.difference(today).inDays;
                    if (_isCurrentDueSettled(expenseProvider, subscription)) {
                      return true;
                    }
                    if (isCurrentActiveMonth) {
                      return days > 7;
                    }
                    return !renewal.isBefore(today);
                  }).toList();

            final historyPayments = expenseProvider.expenses
                .where(_isSubscriptionPaymentEntry)
                .where((expense) {
              final date = expense.date;
              return date.year == _historyMonth.year &&
                  date.month == _historyMonth.month;
            }).toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            final historyTotal = historyPayments.fold<double>(
              0,
              (sum, payment) => sum + payment.amount,
            );

            Widget sectionTitle(String title, int count, {Color? color}) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (color ?? AppTheme.primaryColor)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color ?? AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: _handleScreenSwipe,
              child: Column(
                children: [
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Active'),
                            Tab(text: 'Past'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.accentColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.subscriptions_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _showArchived
                                        ? 'Past subscriptions'
                                        : 'Monthly spend',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _showArchived
                                        ? '${filteredSubscriptions.length} items'
                                        : 'Recurring charges at a glance',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _showArchived
                              ? '${filteredSubscriptions.length} total'
                              : 'Monthly spend: $currencySymbol${totalMonthly.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _CompactStatPill(
                                label: 'Total',
                                value: '${filteredSubscriptions.length}',
                                inverted: true,
                              ),
                              const SizedBox(width: 6),
                              _CompactStatPill(
                                label: 'Due 7d',
                                value: '${dueSoonSubscriptions.length}',
                                inverted: true,
                              ),
                              const SizedBox(width: 6),
                              _CompactStatPill(
                                label: 'Overdue',
                                value: '${overdueSubscriptions.length}',
                                inverted: true,
                                emphasize: overdueSubscriptions.isNotEmpty,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerLowest
                          .withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Search subscriptions',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchQuery.trim().isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            final selected = await showModalBottomSheet<String>(
                              context: context,
                              useSafeArea: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              builder: (sheetContext) => SafeArea(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    const ListTile(
                                      title: Text('Filter by category'),
                                    ),
                                    ...categoryFilters.map((category) {
                                      final isSelected =
                                          category == _selectedCategoryFilter;
                                      return ListTile(
                                        title: Text(category),
                                        trailing: isSelected
                                            ? Icon(
                                                Icons.check,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              )
                                            : null,
                                        onTap: () => Navigator.of(sheetContext)
                                            .pop(category),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            );
                            if (selected == null) return;
                            setState(() {
                              _selectedCategoryFilter = selected;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 92),
                                  child: Text(
                                    _selectedCategoryFilter ==
                                            _allCategoriesFilter
                                        ? 'All'
                                        : _selectedCategoryFilter,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (hasActiveFilter) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: 'Clear filters',
                            visualDensity: const VisualDensity(
                              horizontal: -3,
                              vertical: -3,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _selectedCategoryFilter = _allCategoriesFilter;
                              });
                            },
                            icon: const Icon(Icons.restart_alt, size: 20),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!_showArchived)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _activeMonth = DateTime(
                                  _activeMonth.year,
                                  _activeMonth.month - 1,
                                  1,
                                );
                              });
                            },
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Text(
                              _formatHistoryMonth(_activeMonth),
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: _canMoveActiveMonthForward()
                                ? () {
                                    setState(() {
                                      _activeMonth = DateTime(
                                        _activeMonth.year,
                                        _activeMonth.month + 1,
                                        1,
                                      );
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: filteredSubscriptions.isEmpty
                        ? Center(
                            child: EmptyStateWidget(
                              icon: _showArchived
                                  ? Icons.history
                                  : Icons.subscriptions,
                              title: _showArchived
                                  ? 'No Past Subscriptions'
                                  : 'No Active Subscriptions',
                              description: _searchQuery.trim().isEmpty
                                  ? (_showArchived
                                      ? 'Move a subscription from Active and it will appear here.'
                                      : 'Add your recurring subscriptions to track renewals and spend.')
                                  : 'No subscriptions match your search/filter.',
                              actionLabel:
                                  _showArchived ? null : 'Add Subscription',
                              onAction: _showArchived
                                  ? null
                                  : () => _showAddEditDialog(context),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async =>
                                subProvider.initSubscriptions(),
                            child: ListView(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                contentBottomPadding(context),
                              ),
                              children: [
                                if (_showArchived) ...[
                                  sectionTitle('Past Subscriptions',
                                      filteredSubscriptions.length),
                                  ...filteredSubscriptions.map((sub) {
                                    return _SubscriptionCard(
                                      subscription: sub,
                                      categoryIcon: categoryByName[
                                              (sub.category ?? 'other')
                                                  .toLowerCase()]
                                          ?.icon,
                                      onDelete: () =>
                                          _deleteSubscriptionPermanently(
                                        context,
                                        sub,
                                      ),
                                      onRestore: () =>
                                          _restoreSubscription(context, sub),
                                    );
                                  }),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 0, 16, 6),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _historyMonth = DateTime(
                                                _historyMonth.year,
                                                _historyMonth.month - 1,
                                                1,
                                              );
                                            });
                                          },
                                          icon: const Icon(Icons.chevron_left),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Payments • ${_formatHistoryMonth(_historyMonth)}',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w700),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed:
                                              _canMoveHistoryMonthForward()
                                                  ? () {
                                                      setState(() {
                                                        _historyMonth =
                                                            DateTime(
                                                          _historyMonth.year,
                                                          _historyMonth.month +
                                                              1,
                                                          1,
                                                        );
                                                      });
                                                    }
                                                  : null,
                                          icon: const Icon(Icons.chevron_right),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Total paid',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '$currencySymbol${historyTotal.toStringAsFixed(2)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (historyPayments.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 6),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerLow,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'No subscription payments found for this month.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ),
                                    )
                                  else
                                    ...historyPayments.map((expense) {
                                      final subscriptionName = expense.title
                                          .replaceFirst(
                                              'Subscription Payment - ', '');
                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 0, 16, 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerLow,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      subscriptionName,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      _formatDate(expense.date),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                ] else ...[
                                  if (overdueSubscriptions.isNotEmpty) ...[
                                    sectionTitle(
                                        'Overdue', overdueSubscriptions.length,
                                        color: Colors.red.shade700),
                                    ...overdueSubscriptions.map((sub) {
                                      final isSettled = _isCurrentDueSettled(
                                          expenseProvider, sub);
                                      return _SubscriptionCard(
                                        subscription: sub,
                                        categoryIcon: categoryByName[
                                                (sub.category ?? 'other')
                                                    .toLowerCase()]
                                            ?.icon,
                                        statusReferenceDate: today,
                                        onEdit: () =>
                                            _showAddEditDialog(context, sub),
                                        onDelete: () =>
                                            _deleteSubscription(context, sub),
                                        onRestore: null,
                                        onMarkPaid: isSettled
                                            ? null
                                            : () =>
                                                _showMarkSubscriptionPaidSheet(
                                                  context,
                                                  sub,
                                                ),
                                        showPaidChip: isSettled,
                                      );
                                    }),
                                  ],
                                  if (dueSoonSubscriptions.isNotEmpty) ...[
                                    sectionTitle(
                                        'Due Soon', dueSoonSubscriptions.length,
                                        color: Colors.orange.shade700),
                                    ...dueSoonSubscriptions.map((sub) {
                                      final isSettled = _isCurrentDueSettled(
                                          expenseProvider, sub);
                                      return _SubscriptionCard(
                                        subscription: sub,
                                        categoryIcon: categoryByName[
                                                (sub.category ?? 'other')
                                                    .toLowerCase()]
                                            ?.icon,
                                        statusReferenceDate: today,
                                        onEdit: () =>
                                            _showAddEditDialog(context, sub),
                                        onDelete: () =>
                                            _deleteSubscription(context, sub),
                                        onRestore: null,
                                        onMarkPaid: isSettled
                                            ? null
                                            : () =>
                                                _showMarkSubscriptionPaidSheet(
                                                  context,
                                                  sub,
                                                ),
                                        showPaidChip: isSettled,
                                      );
                                    }),
                                  ],
                                  if (upcomingSubscriptions.isNotEmpty) ...[
                                    sectionTitle('Upcoming',
                                        upcomingSubscriptions.length),
                                    ...upcomingSubscriptions.map((sub) {
                                      final isSettled = _isCurrentDueSettled(
                                          expenseProvider, sub);
                                      return _SubscriptionCard(
                                        subscription: sub,
                                        categoryIcon: categoryByName[
                                                (sub.category ?? 'other')
                                                    .toLowerCase()]
                                            ?.icon,
                                        statusReferenceDate: today,
                                        onEdit: () =>
                                            _showAddEditDialog(context, sub),
                                        onDelete: () =>
                                            _deleteSubscription(context, sub),
                                        onRestore: null,
                                        onMarkPaid: isSettled
                                            ? null
                                            : () =>
                                                _showMarkSubscriptionPaidSheet(
                                                  context,
                                                  sub,
                                                ),
                                        showPaidChip: isSettled,
                                      );
                                    }),
                                  ],
                                ],
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: _showArchived
          ? null
          : AdaptiveBottomFab(
              child: FloatingActionButton(
                mini: true,
                heroTag: 'subscription_list_fab_add',
                onPressed: () => _showAddEditDialog(context),
                child: const Icon(Icons.add),
              ),
            ),
    );
  }

  void _showAddEditDialog(BuildContext context, [Subscription? subscription]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          AddEditSubscriptionScreen(subscription: subscription),
    );
  }

  void _deleteSubscription(BuildContext context, Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove From Active Subscriptions'),
        content: const Text(
            'This subscription will stop appearing in upcoming reminders, but past records will be preserved in Past view.'),
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
              showTimedSnackBar(
                context,
                const SnackBar(content: Text('Subscription moved to Past')),
              );
            },
            child: const Text('Move', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _restoreSubscription(BuildContext context, Subscription subscription) {
    Provider.of<SubscriptionProvider>(context, listen: false)
        .restoreSubscription(subscription.id);
    showTimedSnackBar(
      context,
      const SnackBar(content: Text('Subscription restored to Active')),
    );
  }

  void _showMarkSubscriptionPaidSheet(
    BuildContext context,
    Subscription subscription,
  ) {
    final accountProvider = context.read<PaymentAccountProvider>();
    final accounts = accountProvider.activeAccounts;
    if (accounts.isEmpty) {
      showTimedSnackBar(
        context,
        const SnackBar(content: Text('No active payment account found')),
      );
      return;
    }

    String selectedAccountId = accounts.first.id;
    final amountController =
        TextEditingController(text: subscription.cost.toStringAsFixed(2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final selectedAccount = accounts.firstWhere(
              (account) => account.id == selectedAccountId,
              orElse: () => accounts.first,
            );

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
                    effectiveBottomInset(sheetContext) +
                    16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mark as Paid',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subscription.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownSearch<String>(
                    selectedItem: selectedAccountId,
                    items: accounts.map((account) => account.id).toList(),
                    itemAsString: (id) {
                      final account = accounts.firstWhere((a) => a.id == id);
                      return '${account.name} (${account.accountType})';
                    },
                    popupProps: DropdownSearchUi.adaptiveMenuPopup<String>(
                      context: sheetContext,
                      searchHint: 'Search account...',
                      preferBelow: true,
                    ),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: const InputDecoration(
                        labelText: 'Payment Account',
                      ),
                    ),
                    onChanged: (id) {
                      if (id == null) return;
                      setSheetState(() {
                        selectedAccountId = id;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Paid Amount',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Account type: ${selectedAccount.accountType}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount =
                            double.tryParse(amountController.text.trim());
                        if (amount == null || amount <= 0) {
                          showTimedSnackBar(
                            context,
                            const SnackBar(
                                content: Text('Enter a valid amount')),
                          );
                          return;
                        }
                        Navigator.pop(sheetContext);
                        final account = accounts.firstWhere(
                          (a) => a.id == selectedAccountId,
                        );
                        await _processSubscriptionPayment(
                          context,
                          subscription,
                          account,
                          amount,
                        );
                      },
                      child: const Text('Confirm Payment'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(amountController.dispose);
  }

  Future<void> _processSubscriptionPayment(
    BuildContext context,
    Subscription subscription,
    PaymentAccount selectedAccount,
    double paymentAmount,
  ) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final accountProvider = context.read<PaymentAccountProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();

    try {
      final expenseId = const Uuid().v4();
      final expense = Expense(
        id: expenseId,
        title: 'Subscription Payment - ${subscription.name}',
        category: 'Subscriptions',
        amount: paymentAmount,
        date: DateTime.now(),
        currency: subscription.currency,
        paymentMethod: 'Bank Transfer',
        accountId: selectedAccount.id,
        notes: 'Paid from ${selectedAccount.name}',
        transactionType: 'payment',
      );

      final isCreditCard =
          selectedAccount.accountType.toLowerCase().contains('credit');
      final updatedAccount = selectedAccount.copyWith(
        balance: isCreditCard
            ? selectedAccount.balance + paymentAmount
            : selectedAccount.balance - paymentAmount,
        lastUpdated: DateTime.now(),
      );

      final alreadyPaidForCurrentDue = _getPaidAmountForCurrentDue(
        expenseProvider,
        subscription,
      );
      final totalPaidForCurrentDue = alreadyPaidForCurrentDue + paymentAmount;
      final settlesCurrentDue =
          totalPaidForCurrentDue + 0.005 >= subscription.cost;

      await expenseProvider.addExpense(expense);
      await accountProvider.updateAccount(updatedAccount);

      DateTime? previousRenewalDate;
      DateTime? nextRenewalDate;
      if (settlesCurrentDue) {
        previousRenewalDate = subscription.renewalDate;
        final currentDueDate =
            _currentPayableDueDate(subscription, DateTime.now());
        nextRenewalDate = _advanceByBillingCycle(
          currentDueDate,
          subscription.billingCycle,
        );
        await subscriptionProvider.updateSubscription(
          subscription.copyWith(renewalDate: nextRenewalDate),
        );
      }

      if (!mounted) return;
      showTimedSnackBar(
        this.context,
        SnackBar(
          duration: const Duration(milliseconds: 1400),
          content: Text(
            settlesCurrentDue
                ? 'Subscription marked as paid'
                : 'Partial subscription payment recorded',
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ScaffoldMessenger.of(this.context).hideCurrentSnackBar();
              _reverseSubscriptionPayment(
                selectedAccount,
                expenseId,
                paymentAmount,
                subscriptionId: subscription.id,
                previousRenewalDate: previousRenewalDate,
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showTimedSnackBar(
        this.context,
        SnackBar(
          duration: const Duration(milliseconds: 1400),
          content: Text('Error recording payment: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _reverseSubscriptionPayment(
    PaymentAccount originalAccount,
    String expenseId,
    double paymentAmount, {
    String? subscriptionId,
    DateTime? previousRenewalDate,
  }) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final accountProvider = context.read<PaymentAccountProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();

    try {
      await expenseProvider.deleteExpense(expenseId);
      final latestAccount =
          accountProvider.getAccountById(originalAccount.id) ?? originalAccount;
      final isCreditCard =
          latestAccount.accountType.toLowerCase().contains('credit');
      await accountProvider.updateAccount(
        latestAccount.copyWith(
          balance: isCreditCard
              ? latestAccount.balance - paymentAmount
              : latestAccount.balance + paymentAmount,
          lastUpdated: DateTime.now(),
        ),
      );

      if (subscriptionId != null && previousRenewalDate != null) {
        final currentSubscription = subscriptionProvider.subscriptions
            .where((sub) => sub.id == subscriptionId)
            .firstOrNull;
        if (currentSubscription != null) {
          await subscriptionProvider.updateSubscription(
            currentSubscription.copyWith(renewalDate: previousRenewalDate),
          );
        }
      }
      if (!mounted) return;
      showTimedSnackBar(
        context,
        const SnackBar(
          duration: Duration(milliseconds: 1400),
          content: Text('Payment reverted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showTimedSnackBar(
        context,
        SnackBar(
          duration: const Duration(milliseconds: 1400),
          content: Text('Unable to revert payment: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  DateTime _statusAnchorRenewalDate(Subscription subscription, DateTime today) {
    final currentDate = DateTime(today.year, today.month, today.day);
    final base = DateTime(
      subscription.renewalDate.year,
      subscription.renewalDate.month,
      subscription.renewalDate.day,
    );

    if (!base.isBefore(currentDate)) {
      return base;
    }

    var next = base;
    while (next.isBefore(currentDate)) {
      next = _advanceByBillingCycle(next, subscription.billingCycle);
    }

    return _rewindByBillingCycle(next, subscription.billingCycle);
  }

  DateTime _currentPayableDueDate(Subscription subscription, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final nextDue = _nextRenewalAfter(
      subscription.renewalDate,
      subscription.billingCycle,
      today,
    );
    final daysToNext = nextDue.difference(today).inDays;
    if (daysToNext <= 7) {
      return nextDue;
    }
    return _rewindByBillingCycle(nextDue, subscription.billingCycle);
  }

  DateTime _rewindByBillingCycle(DateTime date, String billingCycle) {
    switch (billingCycle.toLowerCase()) {
      case 'weekly':
        return date.subtract(const Duration(days: 7));
      case 'quarterly':
        return _addMonthsClamped(date, -3);
      case 'yearly':
      case 'annual':
        return _addMonthsClamped(date, -12);
      case 'monthly':
      default:
        return _addMonthsClamped(date, -1);
    }
  }

  DateTime _nextRenewalAfter(
    DateTime renewalDate,
    String billingCycle,
    DateTime referenceDate,
  ) {
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    var next = DateTime(renewalDate.year, renewalDate.month, renewalDate.day);
    while (!next.isAfter(today)) {
      next = _advanceByBillingCycle(next, billingCycle);
    }
    return next;
  }

  DateTime _advanceByBillingCycle(DateTime date, String billingCycle) {
    switch (billingCycle.toLowerCase()) {
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'quarterly':
        return _addMonthsClamped(date, 3);
      case 'yearly':
      case 'annual':
        return _addMonthsClamped(date, 12);
      case 'monthly':
      default:
        return _addMonthsClamped(date, 1);
    }
  }

  DateTime _addMonthsClamped(DateTime date, int monthsToAdd) {
    final targetMonth = date.month + monthsToAdd;
    final targetYear = date.year + ((targetMonth - 1) ~/ 12);
    final normalizedMonth = ((targetMonth - 1) % 12) + 1;
    final maxDay = _daysInMonth(targetYear, normalizedMonth);
    final day = date.day <= maxDay ? date.day : maxDay;
    return DateTime(targetYear, normalizedMonth, day);
  }

  int _daysInMonth(int year, int month) {
    if (month == 12) {
      return DateTime(year + 1, 1, 0).day;
    }
    return DateTime(year, month + 1, 0).day;
  }

  double _getPaidAmountForCurrentDue(
    ExpenseProvider expenseProvider,
    Subscription subscription,
  ) {
    final dueDate = _currentPayableDueDate(subscription, DateTime.now());
    final cycleEnd = _advanceByBillingCycle(dueDate, subscription.billingCycle);

    return expenseProvider.expenses
        .where(
            (expense) => _isSubscriptionPaymentExpense(expense, subscription))
        .where((expense) {
      final paidDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      return !paidDate.isBefore(dueDate) && paidDate.isBefore(cycleEnd);
    }).fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  bool _isCurrentDueSettled(
    ExpenseProvider expenseProvider,
    Subscription subscription,
  ) {
    final paid = _getPaidAmountForCurrentDue(expenseProvider, subscription);
    return paid + 0.005 >= subscription.cost;
  }

  bool _isSubscriptionPaymentEntry(Expense expense) {
    final type = (expense.transactionType ?? 'expense').toLowerCase();
    return type == 'payment' &&
        expense.category == 'Subscriptions' &&
        expense.title.startsWith('Subscription Payment - ');
  }

  bool _canMoveHistoryMonthForward() {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return _historyMonth.isBefore(currentMonth);
  }

  bool _canMoveActiveMonthForward() {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return _activeMonth.isBefore(currentMonth);
  }

  String _formatHistoryMonth(DateTime month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSubscriptionPaymentExpense(
      Expense expense, Subscription subscription) {
    final type = (expense.transactionType ?? 'expense').toLowerCase();
    return type == 'payment' &&
        expense.category == 'Subscriptions' &&
        expense.title == 'Subscription Payment - ${subscription.name}';
  }

  void _deleteSubscriptionPermanently(
      BuildContext context, Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: const Text(
            'This will permanently remove this archived subscription record.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<SubscriptionProvider>(context, listen: false)
                  .deleteSubscriptionPermanently(subscription.id);
              Navigator.pop(context);
              showTimedSnackBar(
                context,
                const SnackBar(
                    content: Text('Subscription deleted permanently')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
  final String? categoryIcon;
  final DateTime? statusReferenceDate;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onMarkPaid;
  final bool showPaidChip;

  const _SubscriptionCard({
    required this.subscription,
    this.categoryIcon,
    this.statusReferenceDate,
    this.onEdit,
    this.onDelete,
    this.onRestore,
    this.onMarkPaid,
    this.showPaidChip = false,
  });

  @override
  Widget build(BuildContext context) {
    final ref = statusReferenceDate ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final renewalDay = _statusAnchorRenewalDate(subscription, today);
    final daysToRenewal = renewalDay.difference(today).inDays;

    Color statusColor;
    String statusLabel;
    if (showPaidChip) {
      statusColor = Colors.green.shade700;
      statusLabel = 'Paid';
    } else if (daysToRenewal < 0) {
      statusColor = Colors.red.shade700;
      statusLabel = 'Overdue ${daysToRenewal.abs()}d';
    } else if (daysToRenewal == 0) {
      statusColor = Colors.orange.shade700;
      statusLabel = 'Due today';
    } else if (daysToRenewal <= 7) {
      statusColor = Colors.orange.shade700;
      statusLabel = 'Due in ${daysToRenewal}d';
    } else {
      statusColor = Colors.green.shade700;
      statusLabel = 'On track';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        categoryIcon ?? '📋',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _displayCategory(subscription.category),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${subscription.currency} ${subscription.cost.toStringAsFixed(2)} / ${_formatCycle(subscription.billingCycle)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Renews on ${_formatDate(renewalDay)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (onMarkPaid != null ||
                  showPaidChip ||
                  onEdit != null ||
                  onDelete != null ||
                  onRestore != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (showPaidChip)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Paid',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      )
                    else if (onMarkPaid != null)
                      FilledButton.icon(
                        onPressed: onMarkPaid,
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Mark as Paid'),
                        style: FilledButton.styleFrom(
                          visualDensity: const VisualDensity(
                            horizontal: -2,
                            vertical: -2,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (onRestore != null)
                      IconButton(
                        tooltip: 'Restore',
                        icon: const Icon(Icons.restore),
                        onPressed: onRestore,
                      ),
                    if (onEdit != null)
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: onDelete,
                        color: Colors.red,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatCycle(String cycle) {
    final value = cycle.trim().toLowerCase();
    if (value.isEmpty) return 'Monthly';
    return '${value[0].toUpperCase()}${value.substring(1)}';
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

  DateTime _statusAnchorRenewalDate(Subscription subscription, DateTime today) {
    final currentDate = DateTime(today.year, today.month, today.day);
    final base = DateTime(
      subscription.renewalDate.year,
      subscription.renewalDate.month,
      subscription.renewalDate.day,
    );

    var next = base;
    while (next.isBefore(currentDate)) {
      next = _advanceByBillingCycle(next, subscription.billingCycle);
    }

    if (next == base) {
      return base;
    }

    var previous = _rewindByBillingCycle(next, subscription.billingCycle);
    if (previous.isBefore(base)) {
      previous = base;
    }

    final daysToNext = next.difference(currentDate).inDays.abs();
    final daysFromPrevious = currentDate.difference(previous).inDays.abs();
    return daysFromPrevious <= daysToNext ? previous : next;
  }

  DateTime _advanceByBillingCycle(DateTime date, String billingCycle) {
    switch (billingCycle.toLowerCase()) {
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'quarterly':
        return _addMonthsClamped(date, 3);
      case 'yearly':
      case 'annual':
        return _addMonthsClamped(date, 12);
      case 'monthly':
      default:
        return _addMonthsClamped(date, 1);
    }
  }

  DateTime _rewindByBillingCycle(DateTime date, String billingCycle) {
    switch (billingCycle.toLowerCase()) {
      case 'weekly':
        return date.subtract(const Duration(days: 7));
      case 'quarterly':
        return _addMonthsClamped(date, -3);
      case 'yearly':
      case 'annual':
        return _addMonthsClamped(date, -12);
      case 'monthly':
      default:
        return _addMonthsClamped(date, -1);
    }
  }

  DateTime _addMonthsClamped(DateTime date, int monthsToAdd) {
    final targetMonth = date.month + monthsToAdd;
    final targetYear = date.year + ((targetMonth - 1) ~/ 12);
    final normalizedMonth = ((targetMonth - 1) % 12) + 1;
    final maxDay = _daysInMonth(targetYear, normalizedMonth);
    final day = date.day <= maxDay ? date.day : maxDay;
    return DateTime(targetYear, normalizedMonth, day);
  }

  int _daysInMonth(int year, int month) {
    if (month == 12) {
      return DateTime(year + 1, 1, 0).day;
    }
    return DateTime(year, month + 1, 0).day;
  }

  String _displayCategory(String? category) {
    final value = category?.trim();
    if (value == null || value.isEmpty) {
      return 'Other';
    }
    return value;
  }
}

class _CompactStatPill extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final bool inverted;

  const _CompactStatPill({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: inverted
            ? (emphasize
                ? Colors.white.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.14))
            : (emphasize
                ? Theme.of(context).colorScheme.errorContainer
                : Theme.of(context).colorScheme.surface),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: inverted
              ? Colors.white.withValues(alpha: 0.28)
              : (emphasize
                  ? Theme.of(context).colorScheme.error.withValues(alpha: 0.35)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.55)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: inverted
                  ? Colors.white70
                  : (emphasize
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: inverted
                  ? Colors.white
                  : (emphasize
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
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
  static const List<String> _billingCycles = [
    'weekly',
    'monthly',
    'quarterly',
    'yearly',
  ];

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
    final allCategoryModels =
        context.watch<SettingsProvider>().subscriptionCategories;
    final subscriptions = context.watch<SubscriptionProvider>().subscriptions;

    final usage = <String, int>{};
    for (final subscription in subscriptions) {
      final category = subscription.category?.trim();
      if (category == null || category.isEmpty) continue;
      final key = category.toLowerCase();
      usage[key] = (usage[key] ?? 0) + 1;
    }

    final categoryModels =
        List<SubscriptionCategoryModel>.from(allCategoryModels)
          ..sort((a, b) {
            final aCount = usage[a.name.toLowerCase()] ?? 0;
            final bCount = usage[b.name.toLowerCase()] ?? 0;
            if (aCount != bCount) {
              return bCount.compareTo(aCount);
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

    final categories = categoryModels.map((c) => c.name).toList();
    final availableCategories = categories.isEmpty ? ['Other'] : categories;
    final Map<String, SubscriptionCategoryModel> categoryByName = {
      for (final category in categoryModels) category.name: category,
    };

    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = availableCategories.contains('Other')
          ? 'Other'
          : availableCategories.first;
    }

    return Material(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom +
                effectiveBottomInset(context) +
                16,
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
                    style: TextStyle(
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
                  SizedBox(
                    width: 150,
                    child: DropdownSearch<String>(
                      selectedItem: _selectedBillingCycle,
                      items: _billingCycles,
                      dropdownBuilder: (context, selectedItem) {
                        return Text(
                          _formatBillingCycleLabel(selectedItem ?? 'monthly'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        );
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      popupProps: DropdownSearchUi.adaptiveMenuPopup<String>(
                        context: context,
                        searchHint: 'Search cycle...',
                        preferBelow: true,
                        itemBuilder: (context, item, isSelected) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            child: Text(
                              _formatBillingCycleLabel(item),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          );
                        },
                      ),
                      onChanged: (value) => setState(
                          () => _selectedBillingCycle = value ?? 'monthly'),
                    ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownSearch<String>(
                      selectedItem: _selectedCategory,
                      items: availableCategories,
                      dropdownBuilder: (context, selectedItem) {
                        final model = selectedItem == null
                            ? null
                            : categoryByName[selectedItem];
                        return Row(
                          children: [
                            Text(
                              model?.icon ?? '📋',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedItem ?? 'Other',
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        );
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      popupProps: DropdownSearchUi.adaptiveMenuPopup<String>(
                        context: context,
                        searchHint: 'Search category...',
                        preferBelow: true,
                        itemBuilder: (context, item, isSelected) {
                          final model = categoryByName[item];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            child: Row(
                              children: [
                                Text(
                                  model?.icon ?? '📋',
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: IconButton(
                      tooltip: 'Manage category icons',
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
      showTimedSnackBar(
        context,
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
    showTimedSnackBar(
      context,
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

  String _formatBillingCycleLabel(String cycle) {
    final value = cycle.trim().toLowerCase();
    if (value.isEmpty) {
      return 'Monthly';
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
