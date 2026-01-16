import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/hearing.dart';
import '../../../shared/models/client.dart';

class HearingsListScreen extends StatefulWidget {
  const HearingsListScreen({super.key});

  @override
  State<HearingsListScreen> createState() => _HearingsListScreenState();
}

class _HearingsListScreenState extends State<HearingsListScreen> {
  late Box<Hearing> _hearingsBox;
  late Box<Client> _clientsBox;

  @override
  void initState() {
    super.initState();
    _hearingsBox = HiveService.hearingsBox;
    _clientsBox = HiveService.clientsBox;
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
            height: MediaQuery.of(context).size.height * 0.5,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  ),
                  const SizedBox(height: 6),
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Case Title')),
                  const SizedBox(height: 6),
                  ListTile(
                    title: Text('Date & Time: ${selectedDate.toLocal().toString().split('.')[0]}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
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
                        hearing!.caseTitle = titleController.text.trim();
                        hearing.clientKey = selectedClientKey!;
                        hearing.dateTime = selectedDate;
                        hearing.court = courtController.text.trim();
                        hearing.notes = notesController.text.trim();
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
    final hearings = _hearingsBox.values.toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hearings'),
      ),
      body: hearings.isEmpty
          ? const Center(child: Text('No hearings yet'))
          : ListView.builder(
              itemCount: hearings.length,
              itemBuilder: (_, i) {
                final h = hearings[i];
                final client = _clientsBox.get(h.clientKey);
                return ListTile(
                  title: Text(h.caseTitle),
                  subtitle: Text('${client?.name ?? 'Client'} • ${h.dateTime.toLocal().toString().split(' ')[0]} • ${h.court}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteHearing(h),
                  ),
                  onTap: () => _addOrEditHearing(h),
                );
              },
            ),
      floatingActionButton: _clientsBox.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _addOrEditHearing(),
              child: const Icon(Icons.add),
            ),
    );
  }
}
