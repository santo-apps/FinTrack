import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/accounts/data/models/account_type_model.dart';
import 'package:fintrack/features/accounts/presentation/providers/account_type_provider.dart';

class ManageAccountTypeModelsScreen extends StatefulWidget {
  const ManageAccountTypeModelsScreen({super.key});

  @override
  State<ManageAccountTypeModelsScreen> createState() =>
      _ManageAccountTypeModelsScreenState();
}

class _ManageAccountTypeModelsScreenState
    extends State<ManageAccountTypeModelsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Manage Account Types',
        showBackButton: true,
      ),
      body: Consumer<AccountTypeProvider>(
        builder: (context, provider, child) {
          final types = provider.accountTypes;

          if (types.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment,
                      size: 64, color: AppTheme.textSecondaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'No account types yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first account type',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: types.length,
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final reorderedTypes = List<AccountTypeModel>.from(types);
              final item = reorderedTypes.removeAt(oldIndex);
              reorderedTypes.insert(newIndex, item);
              provider.reorderAccountTypes(reorderedTypes);
            },
            itemBuilder: (context, index) {
              final type = types[index];
              final color = type.color != null
                  ? Color(int.parse(type.color!.replaceFirst('#', '0xFF')))
                  : AppTheme.primaryColor;

              return Card(
                key: ValueKey(type.id),
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        type.icon ?? '💳',
                        style: GoogleFonts.poppins(fontSize: 24),
                      ),
                    ),
                  ),
                  title: Text(
                    type.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showAddEditDialog(type: type),
                        color: AppTheme.primaryColor,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _confirmDelete(type),
                        color: Colors.red,
                      ),
                      const Icon(Icons.drag_handle),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        heroTag: 'manage_account_types_fab',
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditDialog({AccountTypeModel? type}) {
    final isEdit = type != null;
    final nameController = TextEditingController(text: type?.name);
    String selectedIcon = type?.icon ?? '💳';
    Color selectedColor = type?.color != null
        ? Color(int.parse(type!.color!.replaceFirst('#', '0xFF')))
        : AppTheme.primaryColor;

    final commonEmojis = [
      '💳',
      '💎',
      '📱',
      '🏦',
      '💵',
      '💰',
      '👛',
      '💸',
      '📝',
      '🔄',
      '📲',
      '⚡',
      '🎯',
      '✨',
      '🌟',
      '💫',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isEdit ? 'Edit Account Type' : 'Add Account Type',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Type Name',
                    hintText: 'e.g., PayPal',
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Icon',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: commonEmojis.map((emoji) {
                    final isSelected = selectedIcon == emoji;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIcon = emoji;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withOpacity(0.2)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(emoji,
                              style: GoogleFonts.poppins(fontSize: 24)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Color',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Pick a color'),
                        content: SingleChildScrollView(
                          child: BlockPicker(
                            pickerColor: selectedColor,
                            onColorChanged: (color) {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Text(
                        'Tap to change color',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }

                final colorHex =
                    '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

                final provider = context.read<AccountTypeProvider>();
                final newType = AccountTypeModel(
                  id: type?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  icon: selectedIcon,
                  color: colorHex,
                  isDefault: type?.isDefault ?? false,
                  order: type?.order ?? provider.accountTypes.length,
                  createdAt: type?.createdAt ?? DateTime.now(),
                  isActive: true,
                );

                if (isEdit) {
                  await provider.updateAccountType(newType);
                } else {
                  await provider.addAccountType(newType);
                }

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(AccountTypeModel type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account Type',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${type.name}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context
                  .read<AccountTypeProvider>()
                  .deleteAccountType(type.id);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
