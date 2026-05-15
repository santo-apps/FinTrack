import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/expense/data/models/expense_category_model.dart';
import 'package:fintrack/features/expense/presentation/providers/expense_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ManageExpenseCategoriesScreen extends StatefulWidget {
  const ManageExpenseCategoriesScreen({super.key});

  @override
  State<ManageExpenseCategoriesScreen> createState() =>
      _ManageExpenseCategoriesScreenState();
}

class _ManageExpenseCategoriesScreenState
    extends State<ManageExpenseCategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Manage Categories',
      ),
      body: SafeArea(
        top: false,
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, _) {
            final categories = provider.categories;

            if (categories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 80,
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                contentBottomPadding(context, hasFab: false),
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _hexToColor(category.color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          category.icon,
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showCategoryDialog(
                            context,
                            category: category,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, category),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: AdaptiveBottomFab(
        child: FloatingActionButton(
          mini: true,
          heroTag: 'manage_expense_categories_fab_add',
          onPressed: () => _showCategoryDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, {ExpenseCategory? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final iconController = TextEditingController(text: category?.icon ?? '');
    Color selectedColor =
        category != null ? _hexToColor(category.color) : Colors.blue;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Category' : 'Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(
                    labelText: 'Icon (Emoji)',
                    border: OutlineInputBorder(),
                    helperText: 'Enter a single emoji',
                  ),
                  maxLength: 2,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
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
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Tap to change color',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final expenseProvider = context.read<ExpenseProvider>();

                if (nameController.text.trim().isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a category name'),
                    ),
                  );
                  return;
                }

                if (iconController.text.trim().isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an emoji icon'),
                    ),
                  );
                  return;
                }

                final newCategory = ExpenseCategory(
                  id: category?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  icon: iconController.text.trim(),
                  color: _colorToHex(selectedColor),
                  isDefault: category?.isDefault ?? false,
                  createdAt: category?.createdAt ?? DateTime.now(),
                );

                if (isEditing) {
                  await expenseProvider.updateCategory(newCategory);
                } else {
                  await expenseProvider.addCategory(newCategory);
                }

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'Category updated successfully'
                          : 'Category added successfully',
                    ),
                  ),
                );
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseCategory category) {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final expenseProvider = parentContext.read<ExpenseProvider>();
              final messenger = ScaffoldMessenger.of(parentContext);
              await expenseProvider.deleteCategory(category.id);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Category deleted successfully'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
