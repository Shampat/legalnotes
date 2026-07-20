import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/hearing.dart';
import '../../../shared/models/client.dart';
import '../../hearings/presentation/add_edit_hearing_screen.dart';
import '../../conflict_check/domain/conflict_check_service.dart';
import '../../conflict_check/presentation/conflict_report_screen.dart';
import '../../../core/utils/backup_utils.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late TextEditingController _officeController;
  Timer? _timer;
  final _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    final savedName = HiveService.settingsBox
        .get('officeName', defaultValue: 'Jolly Law Office') as String;
    _officeController = TextEditingController(text: savedName);
    _timer = Timer.periodic(
        const Duration(seconds: 60), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _officeController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _statCard(IconData icon, String label, int value,
      List<Color> gradientColors) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF000080), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('$value',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Color _getHearingCardColor(Hearing h) {
    final now = DateTime.now();
    final diff = h.dateTime.difference(now);
    if (diff.isNegative) return Colors.red.shade100;
    if (diff.inMinutes <= 60) return Colors.orange.shade100;
    if (diff.inDays == 0) return Colors.yellow.shade100;
    return Colors.white;
  }

  String _getHearingStatus(Hearing h) {
    final now = DateTime.now();
    final diff = h.dateTime.difference(now);
    if (diff.isNegative) return 'Overdue';
    if (diff.inMinutes <= 60) return '${diff.inMinutes} min left';
    return '';
  }

  Future<void> _playAlert() async {
    try {
      await _audioPlayer.play(AssetSource('alert.mp3'));
    } catch (e) {
      // ignore
    }
  }

  void _editHearingFromDashboard(Hearing h) async {
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddEditHearingScreen(hearing: h)),
    );
    if (saved == true && mounted) setState(() {});
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

            final soonCount = hearings
                .where((h) =>
                    h.dateTime.difference(now).inDays <= 7 &&
                    h.dateTime.isAfter(now))
                .length;

            int conflictCount = 0;
            for (final h in hearings) {
              if (h.opposingParty.trim().isEmpty) continue;
              conflictCount += ConflictCheckService
                  .checkOpposingPartyConflict(h.opposingParty)
                  .length;
            }

            return Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: const Text('Dashboard',
                    style: TextStyle(color: Colors.white)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    tooltip: 'Settings',
                    onPressed: () async {
                      final taxCtrl = TextEditingController(
                        text: (HiveService.settingsBox.get('taxRate', defaultValue: 0.0) as double).toString(),
                      );
                      await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('App Settings'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: taxCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Tax Rate (%)',
                                  hintText: 'e.g. 13 for HST, 5 for GST',
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF000080)),
                              onPressed: () {
                                final rate = double.tryParse(taxCtrl.text) ?? 13.0;
                                HiveService.settingsBox.put('taxRate', rate);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Tax rate set to \$rate%')),
                                );
                              },
                              child: const Text('Save', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo, Color(0xFF000080)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(50),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _officeController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter office name',
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
                          HiveService.settingsBox
                              .put('officeName', value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Office name saved: $value')),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stat cards
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              Icons.people,
                              'Clients',
                              clientBox.length,
                              [Colors.indigo.shade700,
                                  const Color(0xFF000080)],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _statCard(
                              Icons.gavel,
                              'Soon',
                              soonCount,
                              soonCount > 0
                                  ? [Colors.orange.shade700,
                                      Colors.deepOrange]
                                  : [Colors.green.shade700,
                                      Colors.green.shade400],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Conflict warning
                      if (conflictCount > 0)
                        InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ConflictReportScreen(),
                              ),
                            );
                            if (context.mounted) setState(() {});
                          },
                          child: Card(
                            color: Colors.red.shade50,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                  color: Colors.red),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.warning,
                                  color: Colors.red),
                              title: Text(
                                  'Potential Conflicts: $conflictCount'),
                              subtitle: const Text(
                                  'Tap to review conflict matches'),
                              trailing:
                                  const Icon(Icons.chevron_right),
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Reports button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.bar_chart,
                              color: Colors.white),
                          label: const Text('View Office Reports',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF000080)),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ReportsScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Backup & Restore
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.backup,
                                  color: Colors.white),
                              label: const Text('Backup',
                                  style:
                                      TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.green.shade700),
                              onPressed: () async {
                                final path =
                                    await BackupUtils.exportBackup();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                      content: Text(path != null
                                          ? 'Backup exported!'
                                          : 'Backup failed')),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.restore,
                                  color: Colors.white),
                              label: const Text('Restore',
                                  style:
                                      TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.orange.shade700),
                              onPressed: () async {
                                final ok =
                                    await BackupUtils.importBackup();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                      content: Text(ok
                                          ? 'Data restored successfully!'
                                          : 'Restore failed or cancelled')),
                                );
                                if (ok) setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Upcoming hearings
                      const Text(
                        'Upcoming Hearings',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: hearings.length,
                        itemBuilder: (_, i) {
                          final h = hearings[i];
                          final bgColor = _getHearingCardColor(h);
                          final status = _getHearingStatus(h);

                          if (status.contains('min left')) {
                            _playAlert();
                          }

                          return Card(
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                  color: Color(0xFF000080),
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.symmetric(
                                vertical: 4),
                            color: bgColor,
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                              title: Text(h.caseTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(h.getClientName(),
                                      style: const TextStyle(
                                          color: Color(0xFF000080),
                                          fontWeight:
                                              FontWeight.w600)),
                                  if (h.court.isNotEmpty)
                                    Text(h.court,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('MMM d, h:mm a')
                                            .format(h.dateTime),
                                        style: const TextStyle(
                                            color:
                                                Color(0xFF000080)),
                                      ),
                                      if (status.isNotEmpty)
                                        Text(
                                          status,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: status ==
                                                      'Overdue'
                                                  ? Colors.red
                                                  : Colors.orange,
                                              fontWeight:
                                                  FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.edit,
                                  color: Color(0xFF000080)),
                              onTap: () =>
                                  _editHearingFromDashboard(h),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
