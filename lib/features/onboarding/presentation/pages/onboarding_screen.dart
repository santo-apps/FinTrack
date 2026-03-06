import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/accounts/data/models/payment_account_model.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/budget/presentation/providers/budget_provider.dart';
import 'package:fintrack/features/goals/data/models/financial_goal_model.dart';
import 'package:fintrack/features/goals/presentation/providers/goal_provider.dart';
import 'package:fintrack/features/home/presentation/pages/home_screen.dart';
import 'package:fintrack/features/investment/data/models/investment_model.dart';
import 'package:fintrack/features/investment/presentation/providers/investment_provider.dart';
import 'package:fintrack/features/loan/data/models/loan_model.dart';
import 'package:fintrack/features/loan/presentation/providers/loan_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';
import 'package:fintrack/features/subscription/data/models/subscription_model.dart';
import 'package:fintrack/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:dropdown_search/dropdown_search.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final Uuid _uuid = const Uuid();

  int _currentStep = 0;
  bool _isSaving = false;

  String _selectedCurrency = 'USD';

  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountBalanceController =
      TextEditingController();
  String _accountType = '';

  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _goalTargetController = TextEditingController();

  final TextEditingController _budgetAmountController = TextEditingController();
  String _budgetCategory = 'General';

  final TextEditingController _investmentNameController =
      TextEditingController();
  final TextEditingController _investmentAmountController =
      TextEditingController();
  String _investmentType = 'Stocks';

  final TextEditingController _loanLenderController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();
  final TextEditingController _loanRateController = TextEditingController();
  final TextEditingController _loanTenureController = TextEditingController();

  final TextEditingController _subscriptionNameController =
      TextEditingController();
  final TextEditingController _subscriptionCostController =
      TextEditingController();
  String _subscriptionCycle = 'Monthly';

  static const _stepTitles = [
    'Choose Your Currency',
    'Add Your First Account',
    'Set a Financial Goal',
    'Create Monthly Budget',
    'Track an Investment',
    'Add a Loan',
    'Add a Subscription',
    'Review Your Setup',
  ];

  static const _stepSubtitles = [
    'Pick your default currency for all transactions and reports.',
    'Start with one account to track cash flow from day one.',
    'A clear goal helps you build momentum and stay motivated.',
    'Set an initial limit to keep spending in control.',
    'Add one investment to begin building your portfolio.',
    'Track EMIs and outstanding balance with ease.',
    'Keep recurring costs visible and avoid surprise renewals.',
    'Review all your data before completing setup.',
  ];

  static const _stepIcons = [
    Icons.currency_exchange,
    Icons.account_balance_wallet,
    Icons.flag,
    Icons.pie_chart,
    Icons.trending_up,
    Icons.request_quote,
    Icons.subscriptions,
    Icons.check_circle,
  ];

  @override
  void initState() {
    super.initState();
    _selectedCurrency = context.read<SettingsProvider>().currency.isNotEmpty
        ? context.read<SettingsProvider>().currency
        : 'USD';
    _budgetCategory = 'General';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _accountNameController.dispose();
    _accountBalanceController.dispose();
    _goalNameController.dispose();
    _goalTargetController.dispose();
    _budgetAmountController.dispose();
    _investmentNameController.dispose();
    _investmentAmountController.dispose();
    _loanLenderController.dispose();
    _loanAmountController.dispose();
    _loanRateController.dispose();
    _loanTenureController.dispose();
    _subscriptionNameController.dispose();
    _subscriptionCostController.dispose();
    super.dispose();
  }

  Future<void> _completeAndGoHome() async {
    await HiveService.saveSetting('onboarding_completed', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _skipAll() async {
    await _completeAndGoHome();
  }

  Future<void> _skipCurrentStep() async {
    if (_currentStep == _stepTitles.length - 1) {
      await _completeAndGoHome();
      return;
    }

    setState(() => _currentStep += 1);
    await _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  double _calculateMonthlyEmi(double principal, double annualRate, int months) {
    if (months <= 0) return 0;
    if (annualRate <= 0) return principal / months;

    final monthlyRate = annualRate / 12 / 100;
    final numerator = principal * monthlyRate * (pow(1 + monthlyRate, months));
    final denominator = (pow(1 + monthlyRate, months)) - 1;

    if (denominator == 0) return principal / months;
    return numerator / denominator;
  }

  double pow(double x, int n) {
    double result = 1;
    for (int index = 0; index < n; index++) {
      result *= x;
    }
    return result;
  }

  Future<bool> _saveCurrentStep() async {
    switch (_currentStep) {
      case 0:
        await context.read<SettingsProvider>().setCurrency(_selectedCurrency);
        return true;

      case 1:
        final name = _accountNameController.text.trim();
        final balance = double.tryParse(_accountBalanceController.text.trim());
        if (name.isEmpty || balance == null) return true;

        final account = PaymentAccount(
          id: _uuid.v4(),
          name: name,
          accountType: _accountType,
          balance: balance,
          currency: _selectedCurrency,
          isDefault: false,
          createdAt: DateTime.now(),
        );
        await context.read<PaymentAccountProvider>().addAccount(account);
        return true;

      case 2:
        final name = _goalNameController.text.trim();
        final target = double.tryParse(_goalTargetController.text.trim());
        if (name.isEmpty || target == null) return true;

        final goal = FinancialGoal(
          id: _uuid.v4(),
          goalName: name,
          targetAmount: target,
          currentAmount: 0,
          targetDate: DateTime.now().add(const Duration(days: 365)),
          createdAt: DateTime.now(),
          category: 'Savings',
          currency: _selectedCurrency,
        );
        await context.read<GoalProvider>().addGoal(goal);
        return true;

      case 3:
        final totalBudget =
            double.tryParse(_budgetAmountController.text.trim());
        if (totalBudget == null || totalBudget <= 0) return true;

        final now = DateTime.now();
        await context.read<BudgetProvider>().createOrUpdateBudget(
          {_budgetCategory: totalBudget},
          month: now.month,
          year: now.year,
          currency: _selectedCurrency,
          recurrenceType: 'monthly',
          endDate: DateTime(now.year + 1, now.month),
        );
        return true;

      case 4:
        final name = _investmentNameController.text.trim();
        final amount = double.tryParse(_investmentAmountController.text.trim());
        if (name.isEmpty || amount == null) return true;

        final investment = Investment(
          id: _uuid.v4(),
          name: name,
          type: _investmentType,
          investedAmount: amount,
          currentValue: amount,
          createdAt: DateTime.now(),
          purchaseDate: DateTime.now(),
          currency: _selectedCurrency,
        );
        await context.read<InvestmentProvider>().addInvestment(investment);
        return true;

      case 5:
        final lender = _loanLenderController.text.trim();
        final principal = double.tryParse(_loanAmountController.text.trim());
        final rate = double.tryParse(_loanRateController.text.trim());
        final tenure = int.tryParse(_loanTenureController.text.trim());
        if (lender.isEmpty ||
            principal == null ||
            rate == null ||
            tenure == null) {
          return true;
        }

        final monthlyEmi = _calculateMonthlyEmi(principal, rate, tenure);
        final startDate = DateTime.now();

        final loan = Loan(
          id: _uuid.v4(),
          lender: lender,
          borrowedAmount: principal,
          interestRate: rate,
          tenureMonths: tenure,
          monthlyEmi: monthlyEmi,
          startDate: startDate,
          endDate:
              DateTime(startDate.year, startDate.month + tenure, startDate.day),
          emiDate: startDate.day,
          currency: _selectedCurrency,
          createdAt: DateTime.now(),
        );
        await context.read<LoanProvider>().addLoan(loan);
        return true;

      case 6:
        final name = _subscriptionNameController.text.trim();
        final cost = double.tryParse(_subscriptionCostController.text.trim());
        if (name.isEmpty || cost == null) return true;

        final subscription = Subscription(
          id: _uuid.v4(),
          name: name,
          cost: cost,
          billingCycle: _subscriptionCycle,
          renewalDate: DateTime.now().add(const Duration(days: 30)),
          autoRenewal: true,
          currency: _selectedCurrency,
          createdAt: DateTime.now(),
        );
        await context
            .read<SubscriptionProvider>()
            .addSubscription(subscription);
        return true;

      case 7:
        return true;

      default:
        return true;
    }
  }

  /// Validates the current step and returns error message if invalid
  String? _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Currency is always selected (has default)
        return null;

      case 1:
        final name = _accountNameController.text.trim();
        final balance = _accountBalanceController.text.trim();
        if (name.isEmpty) {
          return 'Please enter an account name';
        }
        if (_accountType.isEmpty) {
          return 'Please select an account type';
        }
        if (balance.isEmpty) {
          return 'Please enter the account balance';
        }
        if (double.tryParse(balance) == null) {
          return 'Please enter a valid balance amount';
        }
        return null;

      case 2:
        final name = _goalNameController.text.trim();
        final target = _goalTargetController.text.trim();
        if (name.isEmpty) {
          return 'Please enter a goal name';
        }
        if (target.isEmpty) {
          return 'Please enter the target amount';
        }
        if (double.tryParse(target) == null) {
          return 'Please enter a valid target amount';
        }
        return null;

      case 3:
        final amount = _budgetAmountController.text.trim();
        if (amount.isEmpty) {
          return 'Please enter a budget amount';
        }
        final parsedAmount = double.tryParse(amount);
        if (parsedAmount == null || parsedAmount <= 0) {
          return 'Please enter a valid budget amount greater than 0';
        }
        return null;

      case 4:
        final name = _investmentNameController.text.trim();
        final amount = _investmentAmountController.text.trim();
        if (name.isEmpty) {
          return 'Please enter an investment name';
        }
        if (amount.isEmpty) {
          return 'Please enter the invested amount';
        }
        if (double.tryParse(amount) == null) {
          return 'Please enter a valid amount';
        }
        return null;

      case 5:
        final lender = _loanLenderController.text.trim();
        final amount = _loanAmountController.text.trim();
        final rate = _loanRateController.text.trim();
        final tenure = _loanTenureController.text.trim();
        if (lender.isEmpty) {
          return 'Please enter the lender name';
        }
        if (amount.isEmpty) {
          return 'Please enter the loan amount';
        }
        if (double.tryParse(amount) == null) {
          return 'Please enter a valid loan amount';
        }
        if (rate.isEmpty) {
          return 'Please enter the interest rate';
        }
        if (double.tryParse(rate) == null) {
          return 'Please enter a valid interest rate';
        }
        if (tenure.isEmpty) {
          return 'Please enter the tenure in months';
        }
        if (int.tryParse(tenure) == null) {
          return 'Please enter a valid tenure';
        }
        return null;

      case 6:
        final name = _subscriptionNameController.text.trim();
        final cost = _subscriptionCostController.text.trim();
        if (name.isEmpty) {
          return 'Please enter a subscription name';
        }
        if (cost.isEmpty) {
          return 'Please enter the subscription cost';
        }
        if (double.tryParse(cost) == null) {
          return 'Please enter a valid cost amount';
        }
        return null;

      case 7:
        return null;

      default:
        return null;
    }
  }

  Future<void> _continuePressed() async {
    if (_isSaving) return;

    // Validate current step
    final validationError = _validateCurrentStep();
    if (validationError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _saveCurrentStep();

      if (_currentStep == 6) {
        setState(() => _currentStep += 1);
        await _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOutCubic,
        );
        return;
      }

      if (_currentStep == _stepTitles.length - 1) {
        await _completeAndGoHome();
        return;
      }

      setState(() => _currentStep += 1);
      await _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save this step: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.12),
              Theme.of(context).colorScheme.secondary.withOpacity(0.10),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: List.generate(
                          _stepTitles.length,
                          (index) => Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              margin: const EdgeInsets.only(right: 6),
                              height: 5,
                              decoration: BoxDecoration(
                                color: index <= _currentStep
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _skipAll,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Skip'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStepCard(
                      icon: _stepIcons[0],
                      title: _stepTitles[0],
                      subtitle: _stepSubtitles[0],
                      child: DropdownSearch<String>(
                        items: settings.availableCurrencies,
                        selectedItem: _selectedCurrency,
                        dropdownBuilder: (context, selectedItem) {
                          return Text(selectedItem ?? 'Select currency');
                        },
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          baseStyle: TextStyle(),
                        ),
                        popupProps: PopupProps.menu(
                          title: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Select Currency'),
                          ),
                          showSearchBox: true,
                          searchFieldProps: const TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search currency...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.all(8),
                            ),
                          ),
                          fit: FlexFit.loose,
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedCurrency = value);
                        },
                      ),
                    ),
                    _buildStepCard(
                      icon: _stepIcons[1],
                      title: _stepTitles[1],
                      subtitle: _stepSubtitles[1],
                      child: Column(
                        children: [
                          TextField(
                            controller: _accountNameController,
                            decoration: const InputDecoration(
                              labelText: 'Account name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _accountType.isEmpty ? null : _accountType,
                            decoration: InputDecoration(
                              labelText: 'Account type',
                              hintText: 'Select account type',
                              border: const OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Bank Account',
                                child: Text('Bank Account'),
                              ),
                              DropdownMenuItem(
                                value: 'Cash',
                                child: Text('Cash'),
                              ),
                              DropdownMenuItem(
                                value: 'Credit Card',
                                child: Text('Credit Card'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _accountType = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _accountBalanceController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Current balance',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStepCard(
                      icon: _stepIcons[2],
                      title: _stepTitles[2],
                      subtitle: _stepSubtitles[2],
                      child: Column(
                        children: [
                          TextField(
                            controller: _goalNameController,
                            decoration: const InputDecoration(
                              labelText: 'Goal name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _goalTargetController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Target amount',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStepCard(
                      icon: _stepIcons[3],
                      title: _stepTitles[3],
                      subtitle: _stepSubtitles[3],
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _budgetCategory,
                            decoration: const InputDecoration(
                              labelText: 'Budget category',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'General',
                                child: Text('General'),
                              ),
                              DropdownMenuItem(
                                value: 'Food & Dining',
                                child: Text('Food & Dining'),
                              ),
                              DropdownMenuItem(
                                value: 'Transportation',
                                child: Text('Transportation'),
                              ),
                              DropdownMenuItem(
                                value: 'Shopping',
                                child: Text('Shopping'),
                              ),
                              DropdownMenuItem(
                                value: 'Utilities',
                                child: Text('Utilities'),
                              ),
                              DropdownMenuItem(
                                value: 'Entertainment',
                                child: Text('Entertainment'),
                              ),
                              DropdownMenuItem(
                                value: 'Healthcare',
                                child: Text('Healthcare'),
                              ),
                              DropdownMenuItem(
                                value: 'Education',
                                child: Text('Education'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _budgetCategory = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _budgetAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Monthly budget amount',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStepCard(
                      icon: _stepIcons[4],
                      title: _stepTitles[4],
                      subtitle: _stepSubtitles[4],
                      child: Column(
                        children: [
                          TextField(
                            controller: _investmentNameController,
                            decoration: const InputDecoration(
                              labelText: 'Investment name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownSearch<String>(
                            items: const [
                              'Stocks',
                              'Mutual Funds',
                              'Fixed Deposit',
                              'Bonds',
                              'ETFs',
                              'Government Securities',
                              'Crypto',
                              'Real Estate',
                              'Gold/Precious Metals',
                              'Savings Account',
                              'Recurring Deposit',
                              'Money Market Fund',
                              'Pension Plans',
                              'Insurance Plans',
                              'P2P Lending',
                              'Commodities',
                              'Forex',
                              'Options/Derivatives',
                              'Unit Linked Plans',
                              'Other',
                            ],
                            selectedItem: _investmentType,
                            dropdownBuilder: (context, selectedItem) {
                              return Text(
                                  selectedItem ?? 'Select investment type');
                            },
                            dropdownDecoratorProps:
                                const DropDownDecoratorProps(
                              baseStyle: TextStyle(),
                            ),
                            popupProps: PopupProps.menu(
                              title: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Select Investment Type'),
                              ),
                              showSearchBox: true,
                              searchFieldProps: const TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: 'Search investment type...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(8),
                                ),
                              ),
                              fit: FlexFit.loose,
                            ),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _investmentType = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _investmentAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Invested amount',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStepCard(
                      icon: _stepIcons[5],
                      title: _stepTitles[5],
                      subtitle: _stepSubtitles[5],
                      child: Column(
                        children: [
                          TextField(
                            controller: _loanLenderController,
                            decoration: const InputDecoration(
                              labelText: 'Lender name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _loanAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Loan amount',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _loanRateController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Rate %',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _loanTenureController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Tenure (months)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildStepCard(
                      icon: _stepIcons[6],
                      title: _stepTitles[6],
                      subtitle: _stepSubtitles[6],
                      child: Column(
                        children: [
                          TextField(
                            controller: _subscriptionNameController,
                            decoration: const InputDecoration(
                              labelText: 'Subscription name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _subscriptionCycle,
                            decoration: const InputDecoration(
                              labelText: 'Billing cycle',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Monthly', child: Text('Monthly')),
                              DropdownMenuItem(
                                  value: 'Quarterly', child: Text('Quarterly')),
                              DropdownMenuItem(
                                  value: 'Yearly', child: Text('Yearly')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _subscriptionCycle = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _subscriptionCostController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Cost',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildReviewSummary(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : _skipCurrentStep,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        _currentStep == _stepTitles.length - 1
                            ? 'Skip'
                            : 'Skip this step',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _continuePressed,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                _currentStep == _stepTitles.length - 1
                                    ? 'Complete Setup'
                                    : 'Continue',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final colors = _getStepColors(_currentStep);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Colorful Header with Icon
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative elements
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Opacity(
                        opacity: 0.15,
                        child: Icon(
                          icon,
                          size: 150,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          icon,
                          size: 120,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Main Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.95),
                        ),
                        child: Icon(
                          icon,
                          size: 56,
                          color: colors[0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                                letterSpacing: -0.5,
                              ),
                    ),
                    const SizedBox(height: 12),
                    // Subtitle
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 28),
                    // Input Fields
                    SizedBox(
                      width: double.infinity,
                      child: child,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get gradient colors for each step
  List<Color> _getStepColors(int stepIndex) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (stepIndex % 8) {
      case 0:
        return [
          const Color(0xFF2196F3),
          const Color(0xFF1976D2),
        ]; // Currency - Blue
      case 1:
        return [
          const Color(0xFF4CAF50),
          const Color(0xFF388E3C),
        ]; // Account - Green
      case 2:
        return [
          const Color(0xFFF57C00),
          const Color(0xFFE65100),
        ]; // Goal - Orange
      case 3:
        return [
          const Color(0xFF7B1FA2),
          const Color(0xFF6A1B9A),
        ]; // Budget - Purple
      case 4:
        return [
          const Color(0xFFD32F2F),
          const Color(0xFFC62828),
        ]; // Investment - Red
      case 5:
        return [
          const Color(0xFF00897B),
          const Color(0xFF00695C),
        ]; // Loan - Teal
      case 6:
        return [
          const Color(0xFFAB47BC),
          const Color(0xFF9C27B0),
        ]; // Subscription - Pink/Purple
      case 7:
        return [
          const Color(0xFF0288D1),
          const Color(0xFF01579B),
        ]; // Review - Light Blue
      default:
        return [
          colorScheme.primary,
          colorScheme.primary.withOpacity(0.8),
        ];
    }
  }

  Widget _buildReviewSummary() {
    final loanEmi = _loanTenureController.text.isNotEmpty &&
            _loanAmountController.text.isNotEmpty &&
            _loanRateController.text.isNotEmpty
        ? _calculateMonthlyEmi(
            double.tryParse(_loanAmountController.text) ?? 0,
            double.tryParse(_loanRateController.text) ?? 0,
            int.tryParse(_loanTenureController.text) ?? 1,
          )
        : 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Colorful Header
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0288D1),
                      const Color(0xFF01579B),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Opacity(
                        opacity: 0.15,
                        child: Icon(
                          Icons.check_circle,
                          size: 150,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.95),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: 56,
                          color: const Color(0xFF0288D1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Review Your Setup',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Everything looks good? Confirm to get started.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Review Items
                    Column(
                      children: [
                        _buildReviewItem(
                          'Currency',
                          _selectedCurrency,
                          Icons.currency_exchange,
                        ),
                        const Divider(height: 16, indent: 50),
                        _buildReviewItem(
                          'Account',
                          _accountNameController.text.isNotEmpty &&
                                  _accountType.isNotEmpty
                              ? '${_accountNameController.text} • ${_accountType}'
                              : 'Skipped',
                          Icons.account_balance_wallet,
                        ),
                        const Divider(height: 16, indent: 50),
                        _buildReviewItem(
                          'Goal',
                          _goalNameController.text.isNotEmpty
                              ? _goalNameController.text
                              : 'Skipped',
                          Icons.flag,
                        ),
                        const Divider(height: 16, indent: 50),
                        _buildReviewItem(
                          'Monthly Budget',
                          _budgetAmountController.text.isNotEmpty
                              ? '${_budgetCategory} • ${_selectedCurrency} ${_budgetAmountController.text}'
                              : 'Skipped',
                          Icons.pie_chart,
                        ),
                        const Divider(height: 16, indent: 50),
                        _buildReviewItem(
                          'Investment',
                          _investmentNameController.text.isNotEmpty
                              ? '${_investmentNameController.text} • ${_investmentType}'
                              : 'Skipped',
                          Icons.trending_up,
                        ),
                        const Divider(height: 16, indent: 50),
                        _buildReviewItem(
                          'Loan',
                          _loanLenderController.text.isNotEmpty
                              ? '${_loanLenderController.text} • EMI: ${_selectedCurrency} ${loanEmi.toStringAsFixed(2)}'
                              : 'Skipped',
                          Icons.request_quote,
                        ),
                        const Divider(height: 16, indent: 50),
                        _buildReviewItem(
                          'Subscription',
                          _subscriptionNameController.text.isNotEmpty
                              ? '${_subscriptionNameController.text} • ${_subscriptionCycle}'
                              : 'Skipped',
                          Icons.subscriptions,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(
    String label,
    String value,
    IconData icon, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isHighlight ? FontWeight.w600 : FontWeight.w500,
                        color: isHighlight
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
