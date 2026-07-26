import 'package:flutter/material.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/clients/presentation/clients_list_screen.dart';
import '../features/hearings/presentation/hearings_screen.dart';
import '../features/billing/presentation/billing_screen.dart';
import '../features/documents/presentation/documents_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ClientsListScreen(),
    HearingsScreen(),
    BillingScreen(),
    DocumentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Hearings'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Billing'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Documents'),
        ],
      ),
    );
  }
}
