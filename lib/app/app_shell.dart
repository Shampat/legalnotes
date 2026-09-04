
import 'package:flutter/material.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/clients/presentation/clients_list_screen.dart';
import '../features/hearings/presentation/hearings_screen.dart';
import '../features/appointments/presentation/appointments_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _screens = const [
    DashboardScreen(),
    ClientsListScreen(),
    HearingsScreen(),
    AppointmentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Hearings'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Appointments'),
        ],
      ),
    );
  }
}
