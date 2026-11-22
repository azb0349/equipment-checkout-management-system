import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../model/borrower.dart';
import '../model/checkout.dart';
import '../model/equipment.dart';

class CheckoutsScreen extends StatefulWidget {
  const CheckoutsScreen({super.key});

  @override
  State<CheckoutsScreen> createState() => _CheckoutsScreenState();
}

class _CheckoutsScreenState extends State<CheckoutsScreen> {
  late Future<List<Checkout>> checkoutList;

  List<Equipment> availableEquipment = [];
  List<Borrower> borrowers = [];

  int? selectedEquipmentId;
  int? selectedBorrowerId;

  DateTime checkoutDate = DateTime.now();
  DateTime dueDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    refreshCheckouts();
  }

  void refreshCheckouts() {
    setState(() {
      checkoutList = DatabaseHelper.instance.getCheckouts();
    });
  }

  Future<void> loadFormData() async {
    availableEquipment = await DatabaseHelper.instance.getAvailableEquipment();
    borrowers = await DatabaseHelper.instance.getBorrowers();

    selectedEquipmentId = availableEquipment.isNotEmpty
        ? availableEquipment.first.id
        : null;
    selectedBorrowerId = borrowers.isNotEmpty ? borrowers.first.id : null;
  }

  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> chooseDate({required bool choosingDueDate}) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: choosingDueDate ? dueDate : checkoutDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      if (choosingDueDate) {
        dueDate = pickedDate;
      } else {
        checkoutDate = pickedDate;
      }
    });
  }

  Future<void> showCheckoutDialog() async {
    await loadFormData();

    if (!mounted) return;

    if (availableEquipment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No available equipment. Add or return equipment first.',
          ),
        ),
      );
      return;
    }

    if (borrowers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Register a borrower before creating a checkout.'),
        ),
      );
      return;
    }

    selectedEquipmentId = availableEquipment.first.id;
    selectedBorrowerId = borrowers.first.id;
    checkoutDate = DateTime.now();
    dueDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Checkout'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedEquipmentId,
                      decoration: const InputDecoration(
                        labelText: 'Equipment',
                        border: OutlineInputBorder(),
                      ),
                      items: availableEquipment.map((item) {
                        return DropdownMenuItem<int>(
                          value: item.id,
                          child: Text(item.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedEquipmentId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedBorrowerId,
                      decoration: const InputDecoration(
                        labelText: 'Borrower',
                        border: OutlineInputBorder(),
                      ),
                      items: borrowers.map((borrower) {
                        return DropdownMenuItem<int>(
                          value: borrower.id,
                          child: Text(borrower.fullName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedBorrowerId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Checkout Date'),
                      subtitle: Text(formatDate(checkoutDate)),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: checkoutDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              checkoutDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Due Date'),
                      subtitle: Text(formatDate(dueDate)),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: dueDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              dueDate = picked;
                            });
                          }
                        },
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
                ElevatedButton(
                  onPressed: () async {
                    if (selectedEquipmentId == null ||
                        selectedBorrowerId == null) {
                      return;
                    }

                    if (!dueDate.isAfter(checkoutDate)) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Due date must be after checkout date.',
                          ),
                        ),
                      );
                      return;
                    }

                    final newCheckout = Checkout(
                      equipmentId: selectedEquipmentId!,
                      borrowerId: selectedBorrowerId!,
                      checkoutDate: formatDate(checkoutDate),
                      dueDate: formatDate(dueDate),
                    );

                    try {
                      await DatabaseHelper.instance.insertCheckout(newCheckout);

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      if (!mounted) return;
                      refreshCheckouts();
                    } catch (error) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(dialogContext)
                          .showSnackBar(SnackBar(content: Text('$error')));
                    }
                  },
                  child: const Text('Save Checkout'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> returnCheckout(int checkoutId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      await DatabaseHelper.instance.returnEquipment(checkoutId, today);

      if (!mounted) return;

      refreshCheckouts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipment returned successfully!')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Checkout>>(
        future: checkoutList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final activeCheckouts = (snapshot.data ?? [])
              .where((checkout) => checkout.returnDate == null)
              .toList();

          if (activeCheckouts.isEmpty) {
            return const Center(child: Text('No active checkouts.'));
          }

          return ListView.builder(
            itemCount: activeCheckouts.length,
            itemBuilder: (context, index) {
              final checkout = activeCheckouts[index];

              return FutureBuilder<List<Equipment>>(
                future: DatabaseHelper.instance.getEquipment(),
                builder: (context, equipmentSnapshot) {
                  return FutureBuilder<List<Borrower>>(
                    future: DatabaseHelper.instance.getBorrowers(),
                    builder: (context, borrowerSnapshot) {
                      if (!equipmentSnapshot.hasData ||
                          !borrowerSnapshot.hasData) {
                        return const ListTile(
                          title: Text('Loading checkout...'),
                        );
                      }

                      final equipment = equipmentSnapshot.data!.where(
                        (item) => item.id == checkout.equipmentId,
                      );
                      final borrower = borrowerSnapshot.data!.where(
                        (item) => item.id == checkout.borrowerId,
                      );

                      final equipmentName = equipment.isEmpty
                          ? 'Unknown equipment'
                          : equipment.first.name;
                      final borrowerName = borrower.isEmpty
                          ? 'Unknown borrower'
                          : borrower.first.fullName;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.assignment),
                          title: Text(equipmentName),
                          subtitle: Text(
                            'Borrower: $borrowerName\n'
                            'Due: ${checkout.dueDate}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.assignment_return),
                            tooltip: 'Return Equipment',
                            onPressed: () => returnCheckout(checkout.id!),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCheckoutDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
