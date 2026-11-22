import 'package:equipmeny_checkout/screens/borrowers_screen.dart';
import 'package:flutter/material.dart';

import 'history_screen.dart';
import 'checkouts_screen.dart';
import 'equipment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<String> titles = [
    'Equipment',
    'Borrowers',
    'Checkouts',
    'History',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        centerTitle: false,
        titleSpacing: 20,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),

      body: IndexedStack(
        index: selectedIndex,
        children: const [
          EquipmentScreen(),
          BorrowersScreen(),
          CheckoutsScreen(),
          HistoryScreen(),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: const Color(0xFFDCEAF7),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices),
            label: 'Equipment',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Borrowers',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Checkouts',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
