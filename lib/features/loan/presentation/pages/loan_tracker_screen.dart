import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/loan/data/models/loan_model.dart';
import 'package:fintrack/features/loan/presentation/providers/loan_provider.dart';
import 'package:fintrack/features/loan/presentation/widgets/add_edit_loan_dialog.dart';
import 'package:fintrack/features/loan/presentation/widgets/record_payment_dialog.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class LoanTrackerScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBackButton;

  const LoanTrackerScreen({
    super.key,
    this.showAppBar = true,
    this.showBackButton = false,
  });

  @override
  State<LoanTrackerScreen> createState() => _LoanTrackerScreenState();
}

class _LoanTrackerScreenState extends State<LoanTrackerScreen>
    with SingleTickerProviderStateMixin {
  bool _showCompletedLoans = false;
  late TabController _tabController;

  void _handleScreenSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 180) return;

    final nextCompleted = velocity < 0;
    final targetIndex = nextCompleted ? 1 : 0;
    if (_tabController.index == targetIndex) return;
    _tabController.animateTo(targetIndex);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      final completed = _tabController.index == 1;
      if (_showCompletedLoans == completed) return;
      setState(() {
        _showCompletedLoans = completed;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<LoanProvider>(context, listen: false).initLoans();
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
              title: 'Loan Tracker',
              showBackButton: widget.showBackButton,
            )
          : null,
      body: SafeArea(
        top: false,
        child: Consumer2<LoanProvider, SettingsProvider>(
          builder: (context, loanProvider, settingsProvider, _) {
            final currencySymbol = settingsProvider.currencySymbol;
            final activeLoans = loanProvider.activeLoans;
            final completedLoans = loanProvider.completedLoans;
            final displayLoans =
                _showCompletedLoans ? completedLoans : activeLoans;

            if (loanProvider.loans.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.account_balance,
                title: 'No Loans',
                description: 'Track your loans and EMI payments here',
                actionLabel: 'Add Loan',
                onAction: () => _showAddLoanDialog(context),
              );
            }

            final totalOutstanding = loanProvider.getTotalOutstandingAmount();
            final totalMonthlyEmi = loanProvider.getTotalMonthlyEmi();

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: _handleScreenSwipe,
              child: Column(
                children: [
                  // Summary Card
                  Container(
                    margin: const EdgeInsets.all(12),
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
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Outstanding Loan Amount',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppUtils.formatCurrency(
                            totalOutstanding,
                            currencySymbol: currencySymbol,
                          ),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryItem(
                              label: 'Monthly EMI',
                              value: AppUtils.formatCurrency(
                                totalMonthlyEmi,
                                currencySymbol: currencySymbol,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            _SummaryItem(
                              label: 'Active Loans',
                              value: '${activeLoans.length}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Toggle between active and completed
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Active'),
                            Tab(text: 'Completed'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Loan List
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => loanProvider.initLoans(),
                      child: displayLoans.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _showCompletedLoans
                                        ? Icons.check_circle_outline
                                        : Icons.pending_actions_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _showCompletedLoans
                                        ? 'No completed loans'
                                        : 'No active loans',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                12,
                                0,
                                12,
                                contentBottomPadding(context),
                              ),
                              itemCount: displayLoans.length,
                              itemBuilder: (context, index) {
                                final loan = displayLoans[index];
                                return _LoanCard(
                                  loan: loan,
                                  currencySymbol: currencySymbol,
                                  onTap: () => _showLoanDetails(context, loan),
                                  onEdit: () =>
                                      _showAddLoanDialog(context, loan),
                                  onDelete: () => _deleteLoan(context, loan),
                                  onPayment: () =>
                                      _showPaymentDialog(context, loan),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: AdaptiveBottomFab(
        child: FloatingActionButton(
          mini: true,
          heroTag: 'loan_tracker_fab_add',
          onPressed: () => _showAddLoanDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddLoanDialog(BuildContext context, [Loan? loan]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: AddEditLoanDialog(loan: loan),
      ),
    );
  }

  void _showLoanDetails(BuildContext context, Loan loan) {
    // TODO: Implement loan details view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Details for ${loan.lender}')),
    );
  }

  void _deleteLoan(BuildContext context, Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Loan'),
        content: Text(
            'Are you sure you want to delete the loan from ${loan.lender}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<LoanProvider>(context, listen: false)
                  .deleteLoan(loan.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loan deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Loan loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RecordPaymentDialog(loan: loan),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _LoanCard extends StatefulWidget {
  final Loan loan;
  final String currencySymbol;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPayment;

  const _LoanCard({
    required this.loan,
    required this.currencySymbol,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onPayment,
  });

  @override
  State<_LoanCard> createState() => _LoanCardState();
}

class _LoanCardState extends State<_LoanCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final currencySymbol = widget.currencySymbol;
    final progress = loan.borrowedAmount > 0
        ? (loan.paidAmount / loan.borrowedAmount).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 6,
      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.account_balance,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loan.lender,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${loan.interestRate.toStringAsFixed(2)}% interest',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') widget.onEdit();
                        if (value == 'delete') widget.onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Collapsed View - Quick Info
            if (!_isExpanded) ...[
              Row(
                children: [
                  Expanded(
                    child: _DetailItem(
                      label: 'Monthly EMI',
                      value: AppUtils.formatCurrency(
                        loan.monthlyEmi,
                        currencySymbol: currencySymbol,
                      ),
                      valueColor: AppTheme.successColor,
                    ),
                  ),
                  Expanded(
                    child: _DetailItem(
                      label: 'Pending',
                      value: AppUtils.formatCurrency(
                        loan.pendingAmount,
                        currencySymbol: currencySymbol,
                      ),
                      valueColor: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Quick Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    loan.isCompleted
                        ? AppTheme.successColor
                        : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],

            // Expanded View - Full Details
            if (_isExpanded) ...[
              // Monthly EMI
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.successColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly EMI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      AppUtils.formatCurrency(
                        loan.monthlyEmi,
                        currencySymbol: currencySymbol,
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Loan Details Grid
              Row(
                children: [
                  Expanded(
                    child: _DetailItem(
                      label: 'Borrowed',
                      value: AppUtils.formatCurrency(
                        loan.borrowedAmount,
                        currencySymbol: currencySymbol,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _DetailItem(
                      label: 'Pending',
                      value: AppUtils.formatCurrency(
                        loan.pendingAmount,
                        currencySymbol: currencySymbol,
                      ),
                      valueColor: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _DetailItem(
                      label: 'EMI Date',
                      value:
                          '${loan.emiDate}${_getDaySuffix(loan.emiDate)} of month',
                    ),
                  ),
                  Expanded(
                    child: _DetailItem(
                      label: 'Tenure',
                      value: '${loan.tenureMonths} months',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _DetailItem(
                      label: 'Start Date',
                      value: DateFormat('MMM dd, yyyy').format(loan.startDate),
                    ),
                  ),
                  Expanded(
                    child: _DetailItem(
                      label: 'End Date',
                      value: DateFormat('MMM dd, yyyy').format(loan.endDate),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Repayment Progress',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor:
                          Theme.of(context).colorScheme.outlineVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        loan.isCompleted
                            ? AppTheme.successColor
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),

              // Payment Button
              if (!loan.isCompleted) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onPayment,
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('Record Payment'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
