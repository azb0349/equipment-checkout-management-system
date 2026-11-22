import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../model/borrower.dart';
import 'borrower_details_screen.dart';

class BorrowersScreen extends StatefulWidget {
  const BorrowersScreen({super.key});

  @override
  State<BorrowersScreen> createState() => _BorrowersScreenState();
}

class _BorrowersScreenState extends State<BorrowersScreen> {
  late Future<Map<String, dynamic>> borrowerData = loadBorrowerData();

  String searchText = '';

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final departmentController = TextEditingController();
  final searchController = TextEditingController();

  Future<Map<String, dynamic>> loadBorrowerData() async {
    final borrowers = await DatabaseHelper.instance.getBorrowers();

    final history = await DatabaseHelper.instance.getCheckoutHistory();

    return {'borrowers': borrowers, 'history': history};
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    departmentController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void refreshBorrowers() {
    setState(() {
      borrowerData = loadBorrowerData();
    });
  }

  void showBorrowerDialog({Borrower? borrower}) {
    nameController.text = borrower?.fullName ?? '';
    emailController.text = borrower?.email ?? '';
    departmentController.text = borrower?.department ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(borrower == null ? 'Register Borrower' : 'Edit Borrower'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
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
                final email = emailController.text.trim();
                final department = departmentController.text.trim();

                if (name.isEmpty || email.isEmpty || department.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please complete all fields.'),
                    ),
                  );
                  return;
                }

                final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                if (!emailPattern.hasMatch(email)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email address.'),
                    ),
                  );
                  return;
                }

                final newBorrower = Borrower(
                  id: borrower?.id,
                  fullName: name,
                  email: email,
                  department: department,
                );

                try {
                  if (borrower == null) {
                    await DatabaseHelper.instance.insertBorrower(newBorrower);
                  } else {
                    await DatabaseHelper.instance.updateBorrower(newBorrower);
                  }

                  if (!dialogContext.mounted) return;

                  Navigator.pop(dialogContext);

                  if (!mounted) return;
                  refreshBorrowers();
                } catch (error) {
                  if (!dialogContext.mounted) return;

                  ScaffoldMessenger.of(dialogContext)
                      .showSnackBar(SnackBar(content: Text('Error: $error')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteBorrower(int id) async {
    try {
      await DatabaseHelper.instance.deleteBorrower(id);

      if (!mounted) return;
      refreshBorrowers();
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
        future: borrowerData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;

          final allBorrowers = data['borrowers'] as List<Borrower>;

          final history = data['history'] as List;

          final borrowers = allBorrowers.where((borrower) {
            final search = searchText.toLowerCase();

            return borrower.fullName.toLowerCase().contains(search) ||
                borrower.email.toLowerCase().contains(search) ||
                borrower.department.toLowerCase().contains(search);
          }).toList();

          if (allBorrowers.isEmpty) {
            return const Center(child: Text('No borrowers registered yet.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search borrowers',
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

              Expanded(
                child: borrowers.isEmpty
                    ? const Center(child: Text('No matching borrowers found.'))
                    : ListView.builder(
                        itemCount: borrowers.length,
                        itemBuilder: (context, index) {
                          final borrower = borrowers[index];

                          final activeCheckoutCount = history.where((checkout) {
                            final sameBorrower =
                                checkout['borrowerId'].toString() ==
                                borrower.id.toString();

                            final notReturned = checkout['returnDate'] == null;

                            return sameBorrower && notReturned;
                          }).length;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.person),

                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return BorrowerDetailsScreen(
                                        borrower: borrower,
                                      );
                                    },
                                  ),
                                );

                                if (!mounted) return;
                                refreshBorrowers();
                              },

                              title: Text(borrower.fullName),

                              subtitle: Text(
                                '${borrower.department}\n'
                                '$activeCheckoutCount '
                                'item(s) currently checked out\n'
                                '${borrower.email}',
                              ),

                              isThreeLine: true,

                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    showBorrowerDialog(borrower: borrower);
                                  } else if (value == 'delete') {
                                    deleteBorrower(borrower.id!);
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
        onPressed: () => showBorrowerDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
