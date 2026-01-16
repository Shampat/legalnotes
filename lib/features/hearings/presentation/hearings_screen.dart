import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/hearing.dart';
import '../../../shared/models/client.dart';

class HearingsScreen extends StatefulWidget {
  const HearingsScreen({super.key});

  @override
  State<HearingsScreen> createState() => _HearingsScreenState();
}

class _HearingsScreenState extends State<HearingsScreen> with AutomaticKeepAliveClientMixin {
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
        .where((h) => h.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) && h.dateTime.isBefore(end))
        .toList();
  }

  void _addOrEditHearing([Hearing? hearing]) async {
    final isEdit = hearing != null;
    final titleController = TextEditingController(text: isEdit ? hearing.caseTitle : '');
    final courtController = TextEditingController(text: isEdit ? hearing.court : '');
    final notesController = TextEditingController(text: isEdit ? hearing.notes : '');
    DateTime selectedDate = isEdit ? hearing.dateTime : DateTime.now();
    int? selectedClientKey = isEdit ? hearing.clientKey : null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Hearing' : 'New Hearing'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.55,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedClientKey,
                    hint: const Text('Select Client'),
                    items: _clientsBox.keys.map((key) {
                      final client = _clientsBox.get(key)!;
                      return DropdownMenuItem<int>(
                        value: key as int,
                        child: Text(client.name),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => selectedClientKey = value),
                    decoration: InputDecoration(
                      labelText: 'Client',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Case Title')),
                  const SizedBox(height: 6),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Date & Time: ${selectedDate.toLocal().toString().split('.')[0]}'),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (time != null) {
                          selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          setDialogState(() {});
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  TextField(controller: courtController, decoration: const InputDecoration(labelText: 'Court')),
                  const SizedBox(height: 6),
                  TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedClientKey == null || titleController.text.trim().isEmpty
                  ? null
                  : () async {
                      if (isEdit) {
                        hearing!
                          ..caseTitle = titleController.text.trim()
                          ..clientKey = selectedClientKey!
                          ..dateTime = selectedDate
                          ..court = courtController.text.trim()
                          ..notes = notesController.text.trim();
                        await hearing.save();
                      } else {
                        final newHearing = Hearing(
                          clientKey: selectedClientKey!,
                          caseTitle: titleController.text.trim(),
                          dateTime: selectedDate,
                          court: courtController.text.trim(),
                          notes: notesController.text.trim(),
                        );
                        await _hearingsBox.add(newHearing);
                      }
                      if (mounted) Navigator.pop(context, true);
                    },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) setState(() {});
  }

  void _deleteHearing(Hearing hearing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hearing?'),
        content: Text('Delete "${hearing.caseTitle}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () {
              hearing.delete();
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ValueListenableBuilder(
      valueListenable: _hearingsBox.listenable(),
      builder: (_, Box<Hearing> box, __) {
        final hearings = box.values.toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
        final hearingsOnSelectedDay = _selectedDay != null ? _getHearingsForDay(_selectedDay!) : <Hearing>[];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hearings'),
            actions: [
              IconButton(
                icon: Icon(_showListView ? Icons.calendar_today : Icons.list),
                onPressed: () => setState(() => _showListView = !_showListView),
              ),
            ],
          ),
          body: _showListView ? _buildListView(hearings) : _buildCalendarView(hearingsOnSelectedDay),
          floatingActionButton: _clientsBox.isEmpty
              ? null
              : FloatingActionButton(
                  onPressed: () => _addOrEditHearing(),
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  Widget _buildCalendarView(List<Hearing> hearingsOnSelectedDay) {
    return Column(
      children: [
        TableCalendar<Hearing>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) => setState(() => _calendarFormat = format),
          onPageChanged: (focusedDay) => _focusedDay = focusedDay,
          eventLoader: _getHearingsForDay,
          headerStyle: const HeaderStyle(formatButtonVisible: true, titleCentered: true),
        ),
        const Divider(height: 1),
        Expanded(
          child: hearingsOnSelectedDay.isEmpty
              ? const Center(child: Text('No hearings on this day'))
              : ListView.builder(
                  itemCount: hearingsOnSelectedDay.length,
                  itemBuilder: (_, i) {
                    final h = hearingsOnSelectedDay[i];
                    return ListTile(
                      title: Text(h.caseTitle),
                      subtitle: Text('${h.getClientName()} • ${TimeOfDay.fromDateTime(h.dateTime).format(context)} • ${h.court.isEmpty ? 'Court TBD' : h.court}'),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteHearing(h)),
                      onTap: () => _addOrEditHearing(h),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildListView(List<Hearing> hearings) {
    return hearings.isEmpty
        ? const Center(child: Text('No hearings yet\nTap + to add one'))
        : ListView.builder(
            itemCount: hearings.length,
            itemBuilder: (_, i) {
              final h = hearings[i];
              return ListTile(
                title: Text(h.caseTitle),
                subtitle: Text('${h.getClientName()}\n${h.dateTime.toLocal().toString().split(' ')[0]} at ${TimeOfDay.fromDateTime(h.dateTime).format(context)}'),
                isThreeLine: true,
                trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteHearing(h)),
                onTap: () => _addOrEditHearing(h),
              );
            },
          );
  }
}
