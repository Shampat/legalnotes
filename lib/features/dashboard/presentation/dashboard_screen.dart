import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../shared/models/hearing.dart';
import '../../../shared/models/client.dart';
import '../../../shared/models/appointment.dart';
import '../../../core/services/database/hive_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Color _bgHearing(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return const Color(0xFFFF8A80);
    if (diff.inHours <= 24) return const Color(0xFFFFCDD2);
    if (diff.inHours <= 48) return const Color(0xFFFFE082);
    return Colors.white;
  }
  Color _borderHearing(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return Colors.red;
    if (diff.inHours <= 24) return Colors.redAccent;
    if (diff.inHours <= 48) return Colors.orange;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
      backgroundColor: const Color(0xFFF5F5F5),
      body: ValueListenableBuilder(
        valueListenable: HiveService.clientsBox.listenable(),
        builder: (context, Box<Client> clientBox, _) {
          return ValueListenableBuilder(
            valueListenable: HiveService.hearingsBox.listenable(),
            builder: (context, Box<Hearing> hBox, __) {
              return ValueListenableBuilder(
                valueListenable: HiveService.appointmentsBox.listenable(),
                builder: (context, Box<Appointment> aBox, ___) {
                  final items = <Map<String, dynamic>>[];
                  for (var h in hBox.values) items.add({'isH':true, 'd':h.dateTime, 'title':h.caseTitle, 'sub':h.court??'', 'obj':h});
                  for (var a in aBox.values) items.add({'isH':false, 'd':a.dateTime, 'title':a.title, 'sub':a.location??'', 'obj':a});
                  items.sort((a,b)=> (a['d'] as DateTime).compareTo(b['d'] as DateTime));

                  return Column(children: [
                    // FIXED - NO OVERFLOW: Fixed height 90, small padding, min Column
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 90,
                              decoration: BoxDecoration(color: const Color(0xFF2196F3), borderRadius: BorderRadius.circular(16)),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people, color: Colors.white, size: 22),
                                    SizedBox(height: 4),
                                    _CountText(boxName: 'clients'),
                                    Text('Clients', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 90,
                              decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(16)),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.event, color: Colors.white, size: 22),
                                    SizedBox(height: 4),
                                    _CountText(boxName: 'total'),
                                    Text('Upcoming', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)), const SizedBox(width: 4), const Text('Hearing', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 10),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF7C4DFF), shape: BoxShape.circle)), const SizedBox(width: 4), const Text('Appointment', style: TextStyle(fontSize: 10)),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: items.isEmpty? const Center(child: Text('No events yet', style: TextStyle(fontSize: 12))) :
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: items.length,
                        itemBuilder: (_,i){
                          final it=items[i];
                          final dt=it['d'] as DateTime;
                          final isH=it['isH'] as bool;
                          final bg = isH? _bgHearing(dt) : const Color(0xFFEDE7F6);
                          final border = isH? _borderHearing(dt) : const Color(0xFF7C4DFF);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border(left: BorderSide(color: border, width: 5))),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(children: [
                              Icon(isH? Icons.gavel: Icons.event, color: border, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text('${it['title']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                              Text('${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}', style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                            ]),
                          );
                        },
                      ),
                    ),
                  ]);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CountText extends StatelessWidget {
  final String boxName;
  const _CountText({required this.boxName});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService.clientsBox.listenable(),
      builder: (context, Box<Client> cBox, _) {
        return ValueListenableBuilder(
          valueListenable: HiveService.hearingsBox.listenable(),
          builder: (context, Box<Hearing> hBox, __) {
            return ValueListenableBuilder(
              valueListenable: HiveService.appointmentsBox.listenable(),
              builder: (context, Box<Appointment> aBox, ___) {
                final count = boxName=='clients'? cBox.length : hBox.length + aBox.length;
                return Text('$count', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold));
              },
            );
          },
        );
      },
    );
  }
}
