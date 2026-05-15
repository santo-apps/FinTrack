import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/utils/custom_widgets.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class ManageGoalCategoriesScreen extends StatelessWidget {
  const ManageGoalCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Manage Goal Categories',
      ),
      body: SafeArea(
        top: false,
        child: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, _) {
            final categories = settingsProvider.goalCategories;

            if (categories.isEmpty) {
              return Center(
                child: Text(
                  'No categories available',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
                final isOther = category.toLowerCase() == 'other';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flag_outlined),
                    ),
                    title: Text(
                      category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: isOther
                              ? null
                              : () => _showCategoryDialog(
                                    context,
                                    existingCategory: category,
                                  ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: isOther
                              ? null
                              : () => _confirmDelete(context, category),
                          color: Colors.red,
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
          heroTag: 'manage_goal_categories_fab_add',
          onPressed: () => _showCategoryDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String category) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Category'),
            content: Text('Delete "$category"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete || !context.mounted) {
      return;
    }

    final success =
        await context.read<SettingsProvider>().deleteGoalCategory(category);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            success ? 'Category deleted' : 'Category could not be deleted'),
      ),
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context, {
    String? existingCategory,
  }) async {
    final controller = TextEditingController(text: existingCategory ?? '');
    final isEdit = existingCategory != null;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Category' : 'Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g., Retirement',
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null || result.isEmpty || !context.mounted) {
      return;
    }

    final settingsProvider = context.read<SettingsProvider>();
    final success = isEdit
        ? await settingsProvider.updateGoalCategory(existingCategory, result)
        : await settingsProvider.addGoalCategory(result);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? (isEdit ? 'Category updated' : 'Category added')
            : 'Category already exists or invalid'),
      ),
    );
  }
}
