import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';
import 'package:fintrack/features/settings/presentation/pages/settings_navigation_screen.dart';
import 'package:fintrack/features/settings/presentation/pages/settings_content_management_screen.dart';
import 'package:fintrack/features/settings/presentation/pages/settings_data_management_screen.dart';
import 'package:fintrack/features/settings/presentation/pages/settings_about_screen.dart';
import 'package:fintrack/services/security_service.dart';

class SettingsScreen extends StatefulWidget {
  final String? scrollToSection;

  const SettingsScreen({super.key, this.scrollToSection});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
        showBackButton: true,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Appearance Section
              _buildSectionHeader(context, 'Appearance', Icons.palette),
              _buildSettingCard(
                context,
                leading: Icon(Icons.brightness_4,
                    color: Theme.of(context).primaryColor),
                title: 'Dark Mode',
                subtitle: 'Switch between light and dark theme',
                trailing: Switch(
                  value: settingsProvider.isDarkMode,
                  onChanged: (value) {
                    settingsProvider.setDarkMode(value);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Currency Section
              _buildSectionHeader(context, 'Currency', Icons.currency_exchange),
              _buildSettingCard(
                context,
                leading: Icon(Icons.attach_money,
                    color: Theme.of(context).primaryColor),
                title: 'Default Currency',
                subtitle: settingsProvider.currency,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: settingsProvider.currency,
                      underline: const SizedBox(),
                      items: settingsProvider.availableCurrencies
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.setCurrency(value);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.add,
                          color: Theme.of(context).primaryColor, size: 20),
                      tooltip: 'Add currency',
                      onPressed: () =>
                          _showAddCurrencyDialog(context, settingsProvider),
                    ),
                  ],
                ),
              ),
              if (settingsProvider.customCurrencySymbols.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    'Custom Currencies',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                ...settingsProvider.customCurrencySymbols.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildCustomCurrencyCard(
                      context,
                      entry.key,
                      entry.value,
                      settingsProvider,
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),

              // Security Section
              _buildSectionHeader(context, 'Security', Icons.security),
              FutureBuilder<bool>(
                future: BiometricService.canUseBiometrics(),
                builder: (context, snapshot) {
                  final canUseBiometrics = snapshot.data ?? false;
                  return Column(
                    children: [
                      _buildSettingCard(
                        context,
                        leading: Icon(Icons.fingerprint,
                            color: canUseBiometrics
                                ? Theme.of(context).primaryColor
                                : Colors.grey),
                        title: 'Biometric Authentication',
                        subtitle: canUseBiometrics
                            ? 'Use fingerprint or face ID'
                            : 'Not available on this device',
                        enabled: canUseBiometrics,
                        trailing: Switch(
                          value: settingsProvider.biometricEnabled &&
                              canUseBiometrics,
                          onChanged: canUseBiometrics
                              ? (value) async {
                                  if (value) {
                                    final authenticated =
                                        await BiometricService.authenticate();
                                    if (authenticated && mounted) {
                                      settingsProvider
                                          .setBiometricEnabled(true);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Biometric enabled'),
                                        ),
                                      );
                                    }
                                  } else {
                                    settingsProvider.setBiometricEnabled(false);
                                  }
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSettingCard(
                        context,
                        leading: Icon(Icons.vpn_key,
                            color: Theme.of(context).primaryColor),
                        title: 'PIN Protection',
                        subtitle: settingsProvider.pinEnabled
                            ? 'PIN is enabled'
                            : 'No PIN protection',
                        trailing: Switch(
                          value: settingsProvider.pinEnabled,
                          onChanged: (value) {
                            if (value) {
                              _showPINDialog(context, settingsProvider, true);
                            } else {
                              settingsProvider.setPinEnabled(false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN protection disabled'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Notifications Section
              _buildSectionHeader(
                  context, 'Notifications', Icons.notifications),
              _buildSettingCard(
                context,
                leading: Icon(Icons.notifications_active,
                    color: Theme.of(context).primaryColor),
                title: 'Enable Notifications',
                subtitle: 'Receive app notifications',
                trailing: Switch(
                  value: settingsProvider.notificationsEnabled,
                  onChanged: (value) {
                    settingsProvider.setNotificationsEnabled(value);
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Settings Modules Section
              _buildSectionHeader(context, 'Settings Modules', Icons.tune),
              _buildModuleCard(
                context,
                icon: Icons.navigation,
                title: 'Navigation & Quick Actions',
                description:
                    'Customize bottom navigation and dashboard shortcuts',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsNavigationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildModuleCard(
                context,
                icon: Icons.inventory_2,
                title: 'Content Management',
                description: 'Manage categories, types, and data',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const SettingsContentManagementScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildModuleCard(
                context,
                icon: Icons.backup,
                title: 'Data Management',
                description: 'Backup, export, import, and restore data',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const SettingsDataManagementScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildModuleCard(
                context,
                icon: Icons.info,
                title: 'About',
                description: 'App version, privacy, and legal information',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsAboutScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
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

  Widget _buildSettingCard(
    BuildContext context, {
    required Widget leading,
    required String title,
    required String subtitle,
    required Widget trailing,
    bool enabled = true,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: enabled ? null : Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCurrencyCard(
    BuildContext context,
    String code,
    String symbol,
    SettingsProvider provider,
  ) {
    return Card(
      elevation: 0,
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                symbol,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    'Custom currency',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit,
                  size: 18, color: Theme.of(context).primaryColor),
              tooltip: 'Edit symbol',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => _showEditCurrencyDialog(
                context,
                provider,
                code,
                symbol,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              tooltip: 'Remove currency',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => _confirmRemoveCurrency(context, provider, code),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
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
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
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
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
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

  Future<void> _showAddCurrencyDialog(
      BuildContext context, SettingsProvider provider) async {
    final codeController = TextEditingController();
    final symbolController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Currency Code (e.g., BTC)',
                hintText: 'e.g., BTC, ETH',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: symbolController,
              decoration: const InputDecoration(
                labelText: 'Currency Symbol (e.g., ₿)',
                hintText: 'e.g., ₿, ₽',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (codeController.text.isNotEmpty &&
                  symbolController.text.isNotEmpty) {
                provider.addCustomCurrency(
                  codeController.text.toUpperCase(),
                  symbolController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Currency added successfully'),
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCurrencyDialog(BuildContext context,
      SettingsProvider provider, String code, String symbol) async {
    final symbolController = TextEditingController(text: symbol);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Currency'),
        content: TextField(
          controller: symbolController,
          decoration: InputDecoration(
            labelText: 'Currency Symbol',
            hintText: symbol,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (symbolController.text.isNotEmpty) {
                provider.updateCustomCurrencySymbol(
                  code,
                  symbolController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Currency updated successfully'),
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveCurrency(
      BuildContext context, SettingsProvider provider, String code) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Currency'),
        content: Text('Remove $code?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.removeCustomCurrency(code);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Currency removed'),
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPINDialog(BuildContext context,
      SettingsProvider settingsProvider, bool isSetup) async {
    return showDialog(
      context: context,
      builder: (context) => _PINDialog(
        settingsProvider: settingsProvider,
        isSetup: isSetup,
      ),
    );
  }
}

class _PINDialog extends StatefulWidget {
  final SettingsProvider settingsProvider;
  final bool isSetup;

  const _PINDialog({
    required this.settingsProvider,
    required this.isSetup,
  });

  @override
  State<_PINDialog> createState() => _PINDialogState();
}

class _PINDialogState extends State<_PINDialog> {
  late TextEditingController _pinController;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isSetup ? 'Set PIN' : 'Disable PIN'),
      content: widget.isSetup
          ? TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'Enter 6-digit PIN',
                border: OutlineInputBorder(),
              ),
            )
          : const Text('Are you sure you want to disable PIN protection?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            if (widget.isSetup) {
              if (_pinController.text.length == 6) {
                await widget.settingsProvider.setPin(_pinController.text);
                await widget.settingsProvider.setPINEnabled(true);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN set successfully')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be 6 digits')),
                );
              }
            } else {
              await widget.settingsProvider.setPINEnabled(false);
              if (context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: Text(widget.isSetup ? 'Set' : 'Disable'),
        ),
      ],
    );
  }
}
