import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/database/hive_service.dart';
import 'package:fintrack/features/accounts/presentation/providers/payment_account_provider.dart';
import 'package:fintrack/features/bill/presentation/providers/bill_provider.dart';
import 'package:fintrack/features/budget/presentation/providers/budget_provider.dart';
import 'package:fintrack/features/debt/presentation/providers/debt_provider.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:fintrack/features/goals/presentation/providers/goal_provider.dart';
import 'package:fintrack/features/investment/presentation/providers/investment_provider.dart';
import 'package:fintrack/features/loan/presentation/providers/loan_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';
import 'package:fintrack/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:fintrack/services/backup_service.dart';
import 'package:fintrack/services/data_exchange_service.dart';

class SettingsDataManagementScreen extends StatefulWidget {
  const SettingsDataManagementScreen({super.key});

  @override
  State<SettingsDataManagementScreen> createState() =>
      _SettingsDataManagementScreenState();
}

class _SettingsDataManagementScreenState
    extends State<SettingsDataManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Data Management',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Backups Section
          _buildSectionHeader(context, 'Backups', Icons.backup),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            icon: Icons.backup,
            iconColor: Colors.blue,
            title: 'Create Backup',
            description: 'Export encrypted backup of all data',
            onTap: () => _createBackup(context),
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            context,
            icon: Icons.restore,
            iconColor: Colors.green,
            title: 'Restore Backup',
            description: 'Import data from a backup file',
            onTap: () => _restoreBackup(context),
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            context,
            icon: Icons.download,
            iconColor: Colors.orange,
            title: 'Manage Backups',
            description: 'View and delete existing backups',
            onTap: () => _showBackupsDialog(context),
          ),
          const SizedBox(height: 20),

          // Data Exchange Section
          _buildSectionHeader(context, 'Data Exchange', Icons.share),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            icon: Icons.file_download_outlined,
            iconColor: Colors.purple,
            title: 'Export Data',
            description: 'Download as JSON or CSV format',
            onTap: () => _showExportDialog(context),
          ),
          const SizedBox(height: 8),
          _buildActionCard(
            context,
            icon: Icons.file_upload_outlined,
            iconColor: Colors.cyan,
            title: 'Import Data',
            description: 'Import data from a backup file',
            onTap: () => _showImportDialog(context),
          ),
          const SizedBox(height: 20),

          // Danger Zone Section
          _buildSectionHeader(context, 'Caution', Icons.warning,
              isDanger: true),
          const SizedBox(height: 12),
          _buildActionCard(
            context,
            icon: Icons.delete_forever,
            iconColor: Colors.red,
            title: 'Clear All Data',
            description: 'Permanently delete all financial data',
            isDanger: true,
            onTap: () => _showClearDataDialog(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDanger
                  ? Colors.red.withOpacity(0.1)
                  : Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDanger ? Colors.red : Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDanger
              ? Colors.red.withOpacity(0.2)
              : Theme.of(context).dividerColor,
          width: isDanger ? 1 : 0.5,
        ),
      ),
      color: isDanger ? Colors.red.withOpacity(0.03) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDanger ? Colors.red : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creating backup...')),
      );

      await BackupService.createLocalBackup();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating backup: $e')),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    try {
      final backupPaths = await BackupService.getLocalBackups();

      if (backupPaths.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No backups found')),
        );
        return;
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Backup'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: backupPaths.length,
              itemBuilder: (context, index) {
                final backupPath = backupPaths[index];
                final fileName = backupPath.split('/').last;
                return ListTile(
                  title: Text(fileName),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await BackupService.restoreFromBackup(backupPath);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup restored successfully'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error restoring backup: $e'),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showBackupsDialog(BuildContext context) async {
    try {
      final backupPaths = await BackupService.getLocalBackups();

      if (backupPaths.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No backups found')),
        );
        return;
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Available Backups'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: backupPaths.length,
              itemBuilder: (context, index) {
                final backupPath = backupPaths[index];
                final fileName = backupPath.split('/').last;
                final backupFile = File(backupPath);
                final sizeKb = backupFile.existsSync()
                    ? (backupFile.lengthSync() / 1024).toStringAsFixed(2)
                    : 'N/A';
                return ListTile(
                  title: Text(fileName),
                  subtitle: Text('$sizeKb KB'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Restore'),
                        onTap: () => _restoreBackupFile(context, backupPath),
                      ),
                      PopupMenuItem(
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                        onTap: () {
                          try {
                            if (backupFile.existsSync()) {
                              backupFile.deleteSync();
                            }
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Backup deleted'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _restoreBackupFile(BuildContext context, String filePath) async {
    try {
      await BackupService.restoreFromBackup(filePath);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restored successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restoring backup: $e')),
      );
    }
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure? This will permanently delete all your financial data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllData(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clearing all data...')),
      );

      await HiveService.clearAllData();

      if (!mounted) return;

      await context.read<ExpenseProvider>().refreshData();
      await context.read<BudgetProvider>().refreshData();
      await context.read<SubscriptionProvider>().refreshData();
      await context.read<InvestmentProvider>().refreshData();
      await context.read<GoalProvider>().refreshData();
      await context.read<LoanProvider>().refreshData();
      await context.read<BillProvider>().refreshData();
      await context.read<DebtProvider>().refreshData();
      context.read<PaymentAccountProvider>().refreshData();
      await context.read<SettingsProvider>().refreshSettings();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear data: $e')),
      );
    }
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (mounted) {
                await _exportData(context, ExportFormat.json);
              }
            },
            child: const Text('JSON (for backup)'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (mounted) {
                await _exportData(context, ExportFormat.csv);
              }
            },
            child: const Text('CSV (for spreadsheet)'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, ExportFormat format) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exporting data...')),
      );

      String data;
      if (format == ExportFormat.json) {
        data = await DataExchangeService.exportToJSON();
      } else {
        data = await DataExchangeService.exportToCSV();
      }

      final filePath = await DataExchangeService.saveExportFile(data, format);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data exported successfully'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () async {
              await DataExchangeService.shareExportFile(filePath);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
            'Select JSON backup file and choose how to handle existing data:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (mounted) {
                await _importData(context, mergeData: true);
              }
            },
            child: const Text('Merge'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (mounted) {
                await _importData(context, mergeData: false);
              }
            },
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  Future<void> _importData(BuildContext context,
      {required bool mergeData}) async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importing data...')),
      );

      final result =
          await DataExchangeService.importFromFile(mergeData: mergeData);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: ${result['message']}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import error: $e')),
      );
    }
  }
}
