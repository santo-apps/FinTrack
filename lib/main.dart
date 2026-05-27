import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'features/receivable/presentation/providers/receivable_provider.dart';
import 'features/home/presentation/pages/home_screen.dart';
import 'features/auth/presentation/pages/auth_screen.dart';
import 'features/onboarding/presentation/pages/onboarding_screen.dart';
import 'services/notification_service.dart';

const List<String> _onboardingStepCompletionKeys = [
  'onboarding_step_currency_completed',
  'onboarding_step_account_completed',
  'onboarding_step_goal_completed',
  'onboarding_step_budget_completed',
  'onboarding_step_investment_completed',
  'onboarding_step_loan_completed',
  'onboarding_step_subscription_completed',
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Lock app to portrait orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Keep system bars visible to avoid OEM gesture/nav overlap on some devices.
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // Set initial icon/contrast style only; avoid deprecated system bar color APIs.
  // This will be overridden by the MaterialApp builder once theme is loaded.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ),
  );

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

  // Sync reminder scheduling from persisted settings
  final notificationsEnabled =
      HiveService.getSetting('notifications_enabled', defaultValue: true);
  final dailyReminderEnabled =
      HiveService.getSetting('daily_reminder_enabled', defaultValue: true);
  final dailyReminderHour =
      HiveService.getSetting('daily_reminder_hour', defaultValue: 9);
  final dailyReminderMinute =
      HiveService.getSetting('daily_reminder_minute', defaultValue: 0);

  if (notificationsEnabled && dailyReminderEnabled) {
    await NotificationService.scheduleDailyReminder(
      hour: dailyReminderHour,
      minute: dailyReminderMinute,
    );
  } else {
    await NotificationService.cancelDailyReminder();
  }

  final settings = HiveService.getAllSettings();
  if (!settings.containsKey('onboarding_completed')) {
    final hasExistingData = HiveService.getAllExpenses().isNotEmpty ||
        HiveService.getAllBudgets().isNotEmpty ||
        HiveService.getAllSubscriptions().isNotEmpty ||
        HiveService.getAllInvestments().isNotEmpty ||
        HiveService.getAllGoals().isNotEmpty ||
        HiveService.getAllLoans().isNotEmpty ||
        HiveService.getAllBills().isNotEmpty ||
        HiveService.getAllDebts().isNotEmpty;

    if (hasExistingData) {
      await HiveService.saveSetting('onboarding_completed', true);
    }
  }

  await _migrateOnboardingStepFlags();
  await _backfillOnboardingStepFlagsFromData();

  runApp(const FinTrack());
}

Future<void> _migrateOnboardingStepFlags() async {
  final onboardingCompleted =
      HiveService.getSetting('onboarding_completed', defaultValue: false) ==
          true;

  if (!onboardingCompleted) {
    return;
  }

  final settings = HiveService.getAllSettings();
  final hasAnyStepFlag = _onboardingStepCompletionKeys
      .any((stepKey) => settings.containsKey(stepKey));

  if (hasAnyStepFlag) {
    return;
  }

  for (final stepKey in _onboardingStepCompletionKeys) {
    await HiveService.saveSetting(stepKey, false);
  }
}

Future<void> _backfillOnboardingStepFlagsFromData() async {
  final onboardingCompleted =
      HiveService.getSetting('onboarding_completed', defaultValue: false) ==
          true;

  if (!onboardingCompleted) {
    return;
  }

  final settings = HiveService.getAllSettings();

  Future<void> setStepIfIncomplete(String key, bool completed) async {
    if (!completed) return;
    if (HiveService.getSetting(key, defaultValue: false) == true) return;
    await HiveService.saveSetting(key, true);
  }

  await setStepIfIncomplete(
    'onboarding_step_currency_completed',
    settings.containsKey('currency'),
  );
  await setStepIfIncomplete(
    'onboarding_step_account_completed',
    HiveService.getAllPaymentAccounts().isNotEmpty,
  );
  await setStepIfIncomplete(
    'onboarding_step_goal_completed',
    HiveService.getAllGoals().isNotEmpty,
  );
  await setStepIfIncomplete(
    'onboarding_step_budget_completed',
    HiveService.getAllBudgets().isNotEmpty,
  );
  await setStepIfIncomplete(
    'onboarding_step_investment_completed',
    HiveService.getAllInvestments().isNotEmpty,
  );
  await setStepIfIncomplete(
    'onboarding_step_loan_completed',
    HiveService.getAllLoans().isNotEmpty,
  );
  await setStepIfIncomplete(
    'onboarding_step_subscription_completed',
    HiveService.getAllSubscriptions().isNotEmpty,
  );
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
        ChangeNotifierProvider(create: (_) => ReceivableProvider()),
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
    final onboardingCompleted =
        HiveService.getSetting('onboarding_completed', defaultValue: false);
    if (!onboardingCompleted) {
      return const OnboardingScreen();
    }

    final isPINEnabled = settingsProvider.pinEnabled;
    final isBiometricEnabled = settingsProvider.biometricEnabled;

    if (isPINEnabled || isBiometricEnabled) {
      return const AuthScreen();
    }
    return const HomeScreen();
  }
}
