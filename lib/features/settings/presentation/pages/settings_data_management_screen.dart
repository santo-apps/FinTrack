import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/core/utils/data_refresh_utils.dart';
import 'package:fintrack/database/hive_service.dart';
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
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            contentBottomPadding(context, hasFab: false),
          ),
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
              onTap: _createBackup,
            ),
            const SizedBox(height: 8),
            _buildActionCard(
              context,
              icon: Icons.restore,
              iconColor: Colors.green,
              title: 'Restore Backup',
              description: 'Import data from a backup file',
              onTap: _restoreBackup,
            ),
            const SizedBox(height: 8),
            _buildActionCard(
              context,
              icon: Icons.download,
              iconColor: Colors.orange,
              title: 'Manage Backups',
              description: 'View and delete existing backups',
              onTap: _showBackupsDialog,
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
              onTap: _showExportDialog,
            ),
            const SizedBox(height: 8),
            _buildActionCard(
              context,
              icon: Icons.file_upload_outlined,
              iconColor: Colors.cyan,
              title: 'Import Data',
              description: 'Import data from a backup file',
              onTap: _showImportDialog,
            ),
            const SizedBox(height: 8),
            _buildActionCard(
              context,
              icon: Icons.rule_folder_outlined,
              iconColor: Colors.teal,
              title: 'Preflight Import Check',
              description: 'Validate backup totals before import',
              onTap: _runImportPreflight,
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
              onTap: _showClearDataDialog,
            ),
            const SizedBox(height: 8),
          ],
        ),
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
                  ? Colors.red.withValues(alpha: 0.1)
                  : Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
              ? Colors.red.withValues(alpha: 0.2)
              : Theme.of(context).dividerColor,
          width: isDanger ? 1 : 0.5,
        ),
      ),
      color: isDanger ? Colors.red.withValues(alpha: 0.03) : null,
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
                  color: iconColor.withValues(alpha: 0.15),
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

  Future<void> _createBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Creating backup...')),
      );

      await BackupService.createLocalBackup();
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('Backup created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error creating backup: $e')),
      );
    }
  }

  Future<void> _restoreBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final backupPaths = await BackupService.getLocalBackups();

      if (backupPaths.isEmpty) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('No backups found')),
        );
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Select Backup'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: backupPaths.length,
              itemBuilder: (itemContext, index) {
                final backupPath = backupPaths[index];
                final fileName = backupPath.split('/').last;
                return ListTile(
                  title: Text(fileName),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    try {
                      await BackupService.restoreFromBackup(backupPath);
                      await _refreshAllProviders();
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Backup restored successfully'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
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
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showBackupsDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final backupPaths = await BackupService.getLocalBackups();

      if (backupPaths.isEmpty) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('No backups found')),
        );
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Available Backups'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: backupPaths.length,
              itemBuilder: (itemContext, index) {
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
                    itemBuilder: (menuContext) => [
                      PopupMenuItem(
                        child: const Text('Restore'),
                        onTap: () => _restoreBackupFile(backupPath),
                      ),
                      PopupMenuItem(
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                        onTap: () {
                          try {
                            if (backupFile.existsSync()) {
                              backupFile.deleteSync();
                            }
                            Navigator.pop(dialogContext);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Backup deleted'),
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _restoreBackupFile(String filePath) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await BackupService.restoreFromBackup(filePath);
      await _refreshAllProviders();
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Backup restored successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error restoring backup: $e')),
      );
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure? This will permanently delete all your financial data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _clearAllData();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Clearing all data...')),
      );

      await HiveService.clearAllData();

      if (!mounted) return;

      await _refreshAllProviders();

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('All data cleared successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to clear data: $e')),
      );
    }
  }

  void _showExportDialog() {
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
                await _exportData(ExportFormat.json);
              }
            },
            child: const Text('JSON (for backup)'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (mounted) {
                await _exportData(ExportFormat.csv);
              }
            },
            child: const Text('CSV (for spreadsheet)'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(ExportFormat format) async {
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
          duration: const Duration(seconds: 4),
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

  void _showImportDialog() {
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
                await _importData(mergeData: true);
              }
            },
            child: const Text('Merge'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (mounted) {
                await _importData(mergeData: false);
              }
            },
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  Future<void> _importData({required bool mergeData}) async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importing data...')),
      );

      final result =
          await DataExchangeService.importFromFile(mergeData: mergeData);

      if (!mounted) return;

      if (result['success']) {
        await _refreshAllProviders();
        if (!mounted) return;

        final comparison = result['comparison'] as Map<String, dynamic>?;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (comparison != null) {
          _showIntegrityReport(
            comparison: comparison,
            importSnapshot:
                result['importSnapshot'] as Map<String, dynamic>? ?? const {},
            afterSnapshot:
                result['afterSnapshot'] as Map<String, dynamic>? ?? const {},
          );
        }
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

  Future<void> _runImportPreflight() async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Running import preflight...')),
    );

    final result = await DataExchangeService.preflightImportFile();
    if (!mounted) return;

    messenger.hideCurrentSnackBar();

    if (result['success'] != true) {
      messenger.showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Failed')),
      );
      return;
    }

    _showPreflightReport(
      selectedPath: result['selectedPath']?.toString() ?? '',
      currentSnapshot:
          result['currentSnapshot'] as Map<String, dynamic>? ?? const {},
      fileSnapshot: result['fileSnapshot'] as Map<String, dynamic>? ?? const {},
      replaceDelta: result['replaceDelta'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<void> _refreshAllProviders() async {
    await DataRefreshUtils.refreshAllAndSignal(context);
  }

  void _showIntegrityReport({
    required Map<String, dynamic> comparison,
    required Map<String, dynamic> importSnapshot,
    required Map<String, dynamic> afterSnapshot,
  }) {
    if (!mounted) return;

    final mismatches =
        (comparison['mismatches'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];
    final isMatch = comparison['isMatch'] == true;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isMatch ? 'Import Complete' : 'Integrity Differences Found',
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: isMatch
              ? const Text('Data imported successfully.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: mismatches.length,
                  itemBuilder: (context, index) {
                    final mismatch = mismatches[index];
                    final key = mismatch['key']?.toString() ?? 'unknown';
                    final expected = mismatch['expected'];
                    final actual = mismatch['actual'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('$key: expected=$expected, actual=$actual'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          if (!isMatch)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                final summary =
                    'Imported: ${importSnapshot['expensesCount'] ?? 0} expenses, ${importSnapshot['receivablesCount'] ?? 0} receivables | After: ${afterSnapshot['expensesCount'] ?? 0} expenses, ${afterSnapshot['receivablesCount'] ?? 0} receivables';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(summary)),
                );
              },
              child: const Text('Show Summary'),
            ),
        ],
      ),
    );
  }

  void _showPreflightReport({
    required String selectedPath,
    required Map<String, dynamic> currentSnapshot,
    required Map<String, dynamic> fileSnapshot,
    required Map<String, dynamic> replaceDelta,
  }) {
    if (!mounted) return;

    final mismatches =
        (replaceDelta['mismatches'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];
    final willChange = mismatches.isNotEmpty;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(willChange
            ? 'Preflight: Differences Detected'
            : 'Preflight: No Differences'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('File: ${selectedPath.split('/').last}'),
              const SizedBox(height: 8),
              Text(
                  'Current expenses: ${currentSnapshot['expensesCount'] ?? 0} | File: ${fileSnapshot['expensesCount'] ?? 0}'),
              Text(
                  'Current receivables: ${currentSnapshot['receivablesCount'] ?? 0} | File: ${fileSnapshot['receivablesCount'] ?? 0}'),
              Text(
                  'Current accounts: ${currentSnapshot['accountsCount'] ?? 0} | File: ${fileSnapshot['accountsCount'] ?? 0}'),
              Text(
                  'Current currency: ${currentSnapshot['currency'] ?? '-'} | File: ${fileSnapshot['currency'] ?? '-'}'),
              if (willChange) ...[
                const SizedBox(height: 10),
                const Text('Replace mode changes:'),
                const SizedBox(height: 6),
                ...mismatches.map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${row['key']}: file=${row['expected']} | current=${row['actual']}',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              const Text(
                'Note: Merge mode appends/overwrites by IDs and does not guarantee exact parity.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
