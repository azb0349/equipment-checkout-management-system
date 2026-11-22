import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> historyList;

  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    refreshHistory();
  }

  void refreshHistory() {
    setState(() {
      historyList = DatabaseHelper.instance.getCheckoutHistory();
    });
  }

  String getStatus(Map<String, dynamic> checkout) {
    if (checkout['returnDate'] != null) {
      return 'Returned';
    }

    final today = DateTime.now().toIso8601String().split('T')[0];

    if (checkout['dueDate'].toString().compareTo(today) < 0) {
      return 'Overdue';
    }

    return 'Active';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text(
                'Filter:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedFilter,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: ['All', 'Active', 'Returned', 'Overdue']
                      .map(
                        (filter) => DropdownMenuItem(
                          value: filter,
                          child: Text(filter),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedFilter = value;
                      });
                    }
                  },
                ),
              ),
              IconButton(
                onPressed: refreshHistory,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh history',
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: historyList,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final allCheckouts = snapshot.data ?? [];

              final filteredCheckouts = allCheckouts.where((checkout) {
                if (selectedFilter == 'All') {
                  return true;
                }

                return getStatus(checkout) == selectedFilter;
              }).toList();

              if (filteredCheckouts.isEmpty) {
                return const Center(child: Text('No checkout records found.'));
              }

              return ListView.builder(
                itemCount: filteredCheckouts.length,
                itemBuilder: (context, index) {
                  final checkout = filteredCheckouts[index];
                  final status = getStatus(checkout);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(
                        checkout['equipmentName'] ?? 'Unknown equipment',
                      ),
                      subtitle: Text(
                        'Borrower: ${checkout['borrowerName']}\n'
                        'Checked out: ${checkout['checkoutDate']}\n'
                        'Due: ${checkout['dueDate']}\n'
                        'Returned: ${checkout['returnDate'] ?? 'Not returned'}\n'
                        'Status: $status',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
