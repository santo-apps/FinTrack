import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/features/investment/data/models/investment_type_model.dart';
import 'package:fintrack/features/investment/presentation/providers/investment_type_provider.dart';

class ManageInvestmentTypesScreen extends StatelessWidget {
  const ManageInvestmentTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Investment Types'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(context, null),
          ),
        ],
      ),
      body: Consumer<InvestmentTypeProvider>(
        builder: (context, provider, child) {
          final types = provider.investmentTypes;

          if (types.isEmpty) {
            return const Center(
              child: Text('No investment types available'),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: types.length,
            onReorder: (oldIndex, newIndex) {
              final list = List<InvestmentType>.from(types);
              if (newIndex > oldIndex) {
                newIndex--;
              }
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
              provider.reorderInvestmentTypes(list);
            },
            itemBuilder: (context, index) {
              final type = types[index];
              return Card(
                key: ValueKey(type.id),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
                  title: Text(type.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showAddEditDialog(context, type),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDelete(context, type),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, InvestmentType? type) {
    final nameController = TextEditingController(text: type?.name ?? '');
    final isEdit = type != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Investment Type' : 'Add Investment Type'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Type Name',
            hintText: 'e.g., Cryptocurrency',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
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
                  const SnackBar(content: Text('Please enter a type name')),
                );
                return;
              }

              final provider = Provider.of<InvestmentTypeProvider>(
                context,
                listen: false,
              );

              if (isEdit) {
                final updated = type.copyWith(name: name);
                await provider.updateInvestmentType(updated);
              } else {
                final newType = InvestmentType(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  order: provider.investmentTypes.length,
                  createdAt: DateTime.now(),
                );
                await provider.addInvestmentType(newType);
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit
                        ? 'Investment type updated'
                        : 'Investment type added'),
                  ),
                );
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, InvestmentType type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Investment Type'),
        content: Text(
          'Are you sure you want to delete "${type.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final provider = Provider.of<InvestmentTypeProvider>(
                context,
                listen: false,
              );
              await provider.deleteInvestmentType(type.id);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Investment type deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
