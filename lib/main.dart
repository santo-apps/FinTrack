import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'database/hive_service.dart';
import 'features/expense/presentation/providers/expense_provider.dart';
import 'features/budget/presentation/providers/budget_provider.dart';
import 'features/subscription/presentation/providers/subscription_provider.dart';
import 'features/bill/presentation/providers/bill_provider.dart';
import 'features/debt/presentation/providers/debt_provider.dart';
import 'features/investment/presentation/providers/investment_provider.dart';
import 'features/investment/presentation/providers/investment_type_provider.dart';
import 'features/goals/presentation/providers/goal_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/accounts/presentation/providers/payment_account_provider.dart';
import 'features/accounts/presentation/providers/account_type_provider.dart';
import 'features/loan/presentation/providers/loan_provider.dart';
import 'features/home/presentation/pages/home_screen.dart';
import 'features/auth/presentation/pages/auth_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ignore FlutterError for Google Fonts network issues
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('google_fonts') ||
        details.exception.toString().contains('fonts.gstatic.com')) {
      // Ignore Google Fonts network errors
      return;
    }
    FlutterError.presentError(details);
  };

  // Initialize Hive database
  await HiveService.init();

  // Initialize notifications
  await NotificationService.init();

  runApp(const FinTrack());
}

class FinTrack extends StatelessWidget {
  const FinTrack({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => BillProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => InvestmentProvider()),
        ChangeNotifierProvider(create: (_) => InvestmentTypeProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => PaymentAccountProvider()),
        ChangeNotifierProvider(create: (_) => AccountTypeProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return MaterialApp(
            title: 'Fin Track',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode:
                settingsProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: _getHomeScreen(settingsProvider),
          );
        },
      ),
    );
  }

  Widget _getHomeScreen(SettingsProvider settingsProvider) {
    final isPINEnabled = settingsProvider.pinEnabled;
    final isBiometricEnabled = settingsProvider.biometricEnabled;

    if (isPINEnabled || isBiometricEnabled) {
      return const AuthScreen();
    }
    return const HomeScreen();
  }
}
