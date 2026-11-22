import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../model/borrower.dart';

class BorrowerDetailsScreen extends StatefulWidget {
  final Borrower borrower;

  const BorrowerDetailsScreen({super.key, required this.borrower});

  @override
  State<BorrowerDetailsScreen> createState() => _BorrowerDetailsScreenState();
}

class _BorrowerDetailsScreenState extends State<BorrowerDetailsScreen> {
  late Future<List<Map<String, dynamic>>> historyFuture;

  @override
  void initState() {
    super.initState();
    historyFuture = DatabaseHelper.instance.getCheckoutHistory();
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.borrower.fullName)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allTransactions = snapshot.data ?? [];

          final borrowerTransactions = allTransactions.where((checkout) {
            return checkout['borrowerId'] == widget.borrower.id;
          }).toList();

          final activeCheckouts = borrowerTransactions.where((checkout) {
            return checkout['returnDate'] == null;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.borrower.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text('Email: ${widget.borrower.email}'),
                      const SizedBox(height: 8),
                      Text('Department: ${widget.borrower.department}'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Currently Borrowed',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 8),

              if (activeCheckouts.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('No equipment currently borrowed.'),
                  ),
                ),

              ...activeCheckouts.map((checkout) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.devices),
                    title: Text(
                      checkout['equipmentName'] ?? 'Unknown equipment',
                    ),
                    subtitle: Text(
                      'Checked out: ${checkout['checkoutDate']}\n'
                      'Due: ${checkout['dueDate']}\n'
                      'Status: ${getStatus(checkout)}',
                    ),
                    isThreeLine: true,
                  ),
                );
              }),

              const SizedBox(height: 20),

              Text(
                'Previous Checkout Transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 8),

              if (borrowerTransactions.isEmpty)
                const Card(
                  child: ListTile(title: Text('No checkout history yet.')),
                ),

              ...borrowerTransactions.map((checkout) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(
                      checkout['equipmentName'] ?? 'Unknown equipment',
                    ),
                    subtitle: Text(
                      'Checked out: ${checkout['checkoutDate']}\n'
                      'Due: ${checkout['dueDate']}\n'
                      'Returned: ${checkout['returnDate'] ?? 'Not returned'}\n'
                      'Status: ${getStatus(checkout)}',
                    ),
                    isThreeLine: true,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
