import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/hearing.dart';
import '../../../shared/models/client.dart';
import '../../hearings/presentation/add_edit_hearing_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _officeController =
      TextEditingController(text: 'Jolly Law Office');

  Widget _statCard(
    IconData icon,
    String label,
    int value,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return ValueListenableBuilder(
      valueListenable: HiveService.clientsBox.listenable(),
      builder: (_, Box<Client> clientBox, __) {
        return ValueListenableBuilder(
          valueListenable: HiveService.hearingsBox.listenable(),
          builder: (_, Box<Hearing> hearingBox, ___) {
            final hearings = hearingBox.values.toList()
              ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

            final upcoming = hearings
                .where((h) => h.dateTime.isAfter(now))
                .toList();

            final soonCount = upcoming
                .where((h) => h.dateTime.difference(now).inDays <= 7)
                .length;

            return Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: const Text('Dashboard'),
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo, Colors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(50),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _officeController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Jolly Law Office',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        onSubmitted: (value) {
                          // Optionally, save the name to Hive or SharedPreferences
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Office name updated: $value'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            Icons.people,
                            'Clients',
                            clientBox.length,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _statCard(
                            Icons.gavel,
                            'Soon',
                            soonCount,
                            soonCount > 0 ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Upcoming Hearings',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: upcoming.isEmpty
                          ? const Center(
                              child: Text('No upcoming hearings'),
                            )
                          : ListView.builder(
                              itemCount: upcoming.length,
                              itemBuilder: (_, i) {
                                final h = upcoming[i];
                                return Card(
                                  child: ListTile(
                                    title: Text(h.caseTitle),
                                    subtitle: Text(
                                      DateFormat('MMM d, h:mm a')
                                          .format(h.dateTime),
                                    ),
                                    trailing: const Icon(Icons.edit),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AddEditHearingScreen(
                                                  hearing: h),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

