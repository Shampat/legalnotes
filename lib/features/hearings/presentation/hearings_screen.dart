import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/hearing.dart';
import '../../../shared/models/client.dart';
import 'add_edit_hearing_screen.dart';

class HearingsScreen extends StatefulWidget {
  const HearingsScreen({super.key});

  @override
  State<HearingsScreen> createState() => _HearingsScreenState();
}

class _HearingsScreenState extends State<HearingsScreen>
    with AutomaticKeepAliveClientMixin {
  late final Box<Hearing> _hearingsBox;
  late final Box<Client> _clientsBox;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showListView = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _hearingsBox = HiveService.hearingsBox;
    _clientsBox = HiveService.clientsBox;
    _selectedDay = _focusedDay;
  }

  List<Hearing> _getHearingsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _hearingsBox.values
        .where((h) =>
            h.dateTime.isAfter(
                start.subtract(const Duration(seconds: 1))) &&
            h.dateTime.isBefore(end))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Color _hearingColor(Hearing h) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hDay =
        DateTime(h.dateTime.year, h.dateTime.month, h.dateTime.day);
    if (hDay == today) return Colors.red.shade700;
    if (hDay.isBefore(today.add(const Duration(days: 7)))) {
      return Colors.orange.shade700;
    }
    return const Color(0xFF000080);
  }

  void _deleteHearing(Hearing hearing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hearing?'),
        content: Text('Delete "${hearing.caseTitle}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              hearing.delete();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _openHearing([Hearing? hearing]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditHearingScreen(hearing: hearing),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ValueListenableBuilder(
      valueListenable: _hearingsBox.listenable(),
      builder: (_, Box<Hearing> box, __) {
        final hearings = box.values.toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
        final hearingsOnSelectedDay = _selectedDay != null
            ? _getHearingsForDay(_selectedDay!)
            : <Hearing>[];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hearings',
                style: TextStyle(color: Colors.white)),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Color(0xFF000080)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                    _showListView
                        ? Icons.calendar_today
                        : Icons.list,
                    color: Colors.white),
                onPressed: () =>
                    setState(() => _showListView = !_showListView),
              ),
            ],
          ),
          body: _showListView
              ? _buildListView(hearings)
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TableCalendar<Hearing>(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onFormatChanged: (format) =>
                            setState(() => _calendarFormat = format),
                        onPageChanged: (focusedDay) =>
                            _focusedDay = focusedDay,
                        eventLoader: _getHearingsForDay,
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Colors.red.shade300,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Color(0xFF000080),
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold),
                          formatButtonTextStyle:
                              TextStyle(color: Colors.indigo),
                          leftChevronIcon: Icon(Icons.chevron_left,
                              color: Colors.indigo),
                          rightChevronIcon: Icon(Icons.chevron_right,
                              color: Colors.indigo),
                        ),
                      ),
                      const Divider(height: 1),

                      // Selected day hearings
                      if (hearingsOnSelectedDay.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                              child: Text('No hearings on this day',
                                  style:
                                      TextStyle(color: Colors.grey))),
                        )
                      else
                        ...hearingsOnSelectedDay
                            .map((h) => _hearingTile(h, _hearingColor(h))),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
          floatingActionButton: _clientsBox.isEmpty
              ? null
              : FloatingActionButton(
                  backgroundColor: const Color(0xFF000080),
                  onPressed: () => _openHearing(),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
        );
      },
    );
  }

  Widget _hearingTile(Hearing h, Color color) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(Icons.gavel, color: color),
        title: Text(
          h.caseTitle,
          style:
              TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${h.getClientName()} • ${TimeOfDay.fromDateTime(h.dateTime).format(context)}'),
            if (h.court.isNotEmpty)
              Text(h.court,
                  style: const TextStyle(fontSize: 12)),
            if (h.opposingParty.isNotEmpty)
              Text('vs ${h.opposingParty}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                      fontStyle: FontStyle.italic)),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF000080)),
        onTap: () => _openHearing(h),
      ),
    );
  }

  Widget _buildListView(List<Hearing> hearings) {
    if (hearings.isEmpty) {
      return const Center(
          child: Text('No hearings yet\nTap + to add one'));
    }
    return ListView.builder(
      itemCount: hearings.length,
      itemBuilder: (_, i) {
        final h = hearings[i];
        final color = _hearingColor(h);
        return Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          margin:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Icon(Icons.gavel, color: color),
            title: Text(h.caseTitle,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${h.getClientName()} • ${h.dateTime.toLocal().toString().split(' ')[0]} at ${TimeOfDay.fromDateTime(h.dateTime).format(context)}'),
                if (h.court.isNotEmpty) Text(h.court),
                if (h.opposingParty.isNotEmpty)
                  Text('vs ${h.opposingParty}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade400,
                          fontStyle: FontStyle.italic)),
              ],
            ),
            isThreeLine: true,
            trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteHearing(h)),
            onTap: () => _openHearing(h),
          ),
        );
      },
    );
  }
}
