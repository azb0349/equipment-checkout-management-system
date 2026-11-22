import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../model/equipment.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  late Future<Map<String, dynamic>> equipmentData = loadEquipmentData();

  final nameController = TextEditingController();
  final searchController = TextEditingController();

  String searchText = '';
  String selectedCategoryFilter = 'All';
  String selectedAvailabilityFilter = 'All';

  final List<String> categories = ['Laptop', 'Camera', 'Tablet', 'Other'];

  final List<String> conditions = ['Excellent', 'Good', 'Fair', 'Damaged'];

  Future<Map<String, dynamic>> loadEquipmentData() async {
    final equipment = await DatabaseHelper.instance.getEquipment();

    final history = await DatabaseHelper.instance.getCheckoutHistory();

    return {'equipment': equipment, 'history': history};
  }

  @override
  void dispose() {
    nameController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void refreshEquipment() {
    setState(() {
      equipmentData = loadEquipmentData();
    });
  }

  void showEquipmentDialog({Equipment? equipment}) {
    nameController.text = equipment?.name ?? '';

    String selectedCategory = categories.contains(equipment?.category)
        ? equipment!.category
        : categories.first;

    String selectedCondition = conditions.contains(equipment?.condition)
        ? equipment!.condition
        : conditions.first;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                equipment == null ? 'Add Equipment' : 'Edit Equipment',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Equipment Name',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedCategory = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: selectedCondition,
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(),
                      ),
                      items: conditions.map((condition) {
                        return DropdownMenuItem(
                          value: condition,
                          child: Text(condition),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedCondition = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an equipment name.'),
                        ),
                      );
                      return;
                    }

                    final newEquipment = Equipment(
                      id: equipment?.id,
                      name: name,
                      category: selectedCategory,
                      condition: selectedCondition,
                    );

                    try {
                      if (equipment == null) {
                        await DatabaseHelper.instance.insertEquipment(
                          newEquipment,
                        );
                      } else {
                        await DatabaseHelper.instance.updateEquipment(
                          newEquipment,
                        );
                      }

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      if (!mounted) return;
                      refreshEquipment();
                    } catch (error) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(SnackBar(content: Text('Error: $error')));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteEquipment(int id) async {
    try {
      await DatabaseHelper.instance.deleteEquipment(id);

      if (!mounted) return;
      refreshEquipment();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: equipmentData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;

          final allEquipment = data['equipment'] as List<Equipment>;

          final history = data['history'] as List;

          final filteredEquipment = allEquipment.where((item) {
            final matchesSearch = item.name.toLowerCase().contains(
              searchText.toLowerCase(),
            );

            final matchesCategory =
                selectedCategoryFilter == 'All' ||
                item.category == selectedCategoryFilter;

            final isCheckedOut = history.any((checkout) {
              final sameEquipment =
                  checkout['equipmentId'].toString() == item.id.toString();

              final notReturned = checkout['returnDate'] == null;

              return sameEquipment && notReturned;
            });

            final availability = isCheckedOut ? 'Checked Out' : 'Available';

            final matchesAvailability =
                selectedAvailabilityFilter == 'All' ||
                availability == selectedAvailabilityFilter;

            return matchesSearch && matchesCategory && matchesAvailability;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search equipment',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: searchText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();

                              setState(() {
                                searchText = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCategoryFilter,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: ['All', ...categories].map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedCategoryFilter = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedAvailabilityFilter,
                        decoration: const InputDecoration(
                          labelText: 'Availability',
                          border: OutlineInputBorder(),
                        ),
                        items: const ['All', 'Available', 'Checked Out'].map((
                          availability,
                        ) {
                          return DropdownMenuItem(
                            value: availability,
                            child: Text(availability),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            selectedAvailabilityFilter = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: filteredEquipment.isEmpty
                    ? const Center(child: Text('No matching equipment found.'))
                    : ListView.builder(
                        itemCount: filteredEquipment.length,
                        itemBuilder: (context, index) {
                          final item = filteredEquipment[index];

                          final isCheckedOut = history.any((checkout) {
                            final sameEquipment =
                                checkout['equipmentId'].toString() ==
                                item.id.toString();

                            final notReturned = checkout['returnDate'] == null;

                            return sameEquipment && notReturned;
                          });

                          final availability = isCheckedOut
                              ? 'Checked Out'
                              : 'Available';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.devices),

                              title: Text(item.name),

                              subtitle: Text(
                                '${item.category} • '
                                '${item.condition}\n'
                                'Status: $availability',
                              ),

                              isThreeLine: true,

                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    showEquipmentDialog(equipment: item);
                                  } else if (value == 'delete') {
                                    deleteEquipment(item.id!);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => showEquipmentDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
