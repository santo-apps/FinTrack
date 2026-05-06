import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fintrack/features/subscription/data/models/subscription_model.dart';

Future<void> main() async {
  print('🔧 Subscription Date Reset Tool');
  print('================================\n');

  // Initialize Hive
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);

    // Register adapter if needed (you may need to import and register your adapters)
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SubscriptionAdapter());
    }

    // Open subscriptions box
    final box = await Hive.openBox<Subscription>('subscriptions');

    print('Found ${box.length} subscriptions:\n');

    // List all subscriptions
    int index = 1;
    for (var sub in box.values) {
      print('$index. ${sub.name}');
      print('   Current renewal date: ${sub.renewalDate}');
      print('   Billing cycle: ${sub.billingCycle}\n');
      index++;
    }

    // Ask user which to update
    stdout.write(
        'Enter the number of the subscription to reset to March (or 0 to cancel): ');
    final input = stdin.readLineSync();
    final selectedIndex = int.tryParse(input ?? '0') ?? 0;

    if (selectedIndex < 1 || selectedIndex > box.length) {
      print('Cancelled.');
      await box.close();
      return;
    }

    final subscription = box.values.elementAt(selectedIndex - 1);

    // Calculate new March date (use the day from current renewal date)
    final marchDate = DateTime(2026, 3, subscription.renewalDate.day);

    print('\nUpdating ${subscription.name}...');
    print('From: ${subscription.renewalDate}');
    print('To: $marchDate');

    // Update subscription
    await subscription.copyWith(renewalDate: marchDate).save();

    print('✅ Updated successfully!');
    print('\nYou can now test marking this subscription as paid in the app.');
    print('It should show as completed in March, not April.\n');

    await box.close();
  } catch (e) {
    print('❌ Error: $e');
  }
}
