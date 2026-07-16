import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/client.dart';
import '../../../shared/models/hearing.dart';
import '../domain/conflict_check_service.dart';
import '../../hearings/presentation/add_edit_hearing_screen.dart';

class ConflictReportScreen extends StatelessWidget {
  const ConflictReportScreen({super.key});

  List<Map<String, dynamic>> _buildConflicts() {
    final hearings = HiveService.hearingsBox.values.toList();
    final conflicts = <Map<String, dynamic>>[];

    for (final hearing in hearings) {
      if (hearing.opposingParty.trim().isEmpty) continue;
      final matches = ConflictCheckService.checkOpposingPartyConflict(
        hearing.opposingParty,
      );
      if (matches.isNotEmpty) {
        conflicts.add({
          'hearing': hearing,
          'clients': matches,
        });
      }
    }

    // Sort by hearing dateTime descending (most recent first)
    conflicts.sort((a, b) {
      final aDate = (a['hearing'] as Hearing).dateTime;
      final bDate = (b['hearing'] as Hearing).dateTime;
      return bDate.compareTo(aDate);
    });

    return conflicts;
  }

  @override
  Widget build(BuildContext context) {
    final conflicts = _buildConflicts();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Conflict Report',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF000080),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '${conflicts.length} found',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: conflicts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified, size: 70, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'No conflicts detected',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All opposing parties are clear.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: conflicts.length,
              itemBuilder: (context, index) {
                final hearing = conflicts[index]['hearing'] as Hearing;
                final clients = conflicts[index]['clients'] as List<Client>;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddEditHearingScreen(hearing: hearing),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.red),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Potential Conflict',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          _label('Matched Client(s)'),
                          Text(
                            clients.map((e) => e.name).join(', '),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 12),

                          _label('Opposing Party'),
                          Text(
                            hearing.opposingParty,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 12),

                          _label('Case'),
                          Text(
                            hearing.caseTitle,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 12),

                          _label('Court'),
                          Text(
                            hearing.court.isEmpty ? '—' : hearing.court,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 12),

                          _label('Hearing Date'),
                          Text(
                            DateFormat('dd MMM yyyy • hh:mm a')
                                .format(hearing.dateTime),
                            style: const TextStyle(fontSize: 16),
                          ),

                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Tap to open hearing →',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }
}
