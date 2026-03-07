import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/features/subscription/data/models/subscription_category_model.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class ManageSubscriptionCategoriesScreen extends StatelessWidget {
  const ManageSubscriptionCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Subscription Categories',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          final categories = settingsProvider.subscriptionCategories;

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.subscriptions,
                      size: 64, color: AppTheme.textSecondaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'No subscription categories yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first category',
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
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final reorderedCategories = List.from(categories);
              final item = reorderedCategories.removeAt(oldIndex);
              reorderedCategories.insert(newIndex, item);
              // Note: Add reorder method to SettingsProvider if needed
            },
            itemBuilder: (context, index) {
              final category = categories[index];
              final isOther = category.name.toLowerCase() == 'other';

              return Card(
                key: ValueKey(category.id),
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
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        category.icon,
                        style: GoogleFonts.poppins(fontSize: 24),
                      ),
                    ),
                  ),
                  title: Text(
                    category.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
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
                        color: AppTheme.primaryColor,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: isOther
                            ? null
                            : () => _confirmDelete(context, category.name),
                        color: Colors.red,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                      const Icon(Icons.drag_handle, size: 20),
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
        heroTag: 'manage_subscription_categories_fab',
        onPressed: () => _showCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String category) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Category',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "$category"?',
          style: GoogleFonts.poppins(),
        ),
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
    );

    if (result != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final success = await context
        .read<SettingsProvider>()
        .deleteSubscriptionCategory(category);

    if (!context.mounted) {
      return;
    }

    // Additional safety check before showing snackbar
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Category deleted' : 'Category could not be deleted',
          ),
        ),
      );
    } catch (e) {
      // Silently fail if context is no longer valid
    }
  }

  Future<void> _showCategoryDialog(
    BuildContext context, {
    SubscriptionCategoryModel? existingCategory,
  }) async {
    final controller =
        TextEditingController(text: existingCategory?.name ?? '');
    final isEdit = existingCategory != null;
    String selectedIcon = existingCategory?.icon ?? '📱';

    final commonEmojis = [
      '📱',
      '🎬',
      '🎵',
      '📺',
      '💼',
      '☁️',
      '💪',
      '📰',
      '📚',
      '🎮',
      '🍔',
      '🛒',
      '🚗',
      '💻',
      '📋',
      '✨',
    ];

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(
              isEdit ? 'Edit Category' : 'Add Category',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g., Entertainment',
                    ),
                    onSubmitted: (value) {
                      Navigator.pop(context, value.trim());
                    },
                  ),
                  const SizedBox(height: 16),
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
                          width: 44,
                          height: 44,
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
                            child: Text(
                              emoji,
                              style: GoogleFonts.poppins(fontSize: 20),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  Navigator.pop(context, text);
                },
                child: Text(isEdit ? 'Update' : 'Add'),
              ),
            ],
          ),
        );
      },
    );

    // Dispose controller after dialog is fully closed
    Future.delayed(const Duration(milliseconds: 100), () {
      controller.dispose();
    });

    if (result == null || result.isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final settingsProvider = context.read<SettingsProvider>();
    final success = existingCategory == null
        ? await settingsProvider.addSubscriptionCategory(result, selectedIcon)
        : await settingsProvider.updateSubscriptionCategory(
            existingCategory.name,
            result,
            newIcon: selectedIcon,
          );

    if (!context.mounted) {
      return;
    }

    // Additional safety check before showing snackbar
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (existingCategory == null
                    ? 'Category added'
                    : 'Category updated')
                : 'Category already exists or invalid',
          ),
        ),
      );
    } catch (e) {
      // Silently fail if context is no longer valid
    }
  }
}
