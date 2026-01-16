import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/hearing.dart';

class AddEditHearingScreen extends StatefulWidget {
  final Hearing? hearing;

  const AddEditHearingScreen({super.key, this.hearing});

  @override
  State<AddEditHearingScreen> createState() => _AddEditHearingScreenState();
}

class _AddEditHearingScreenState extends State<AddEditHearingScreen> {
  late TextEditingController titleCtrl;
  late TextEditingController courtCtrl;
  late TextEditingController notesCtrl;
  late DateTime date;

  @override
  void initState() {
    super.initState();
    titleCtrl =
        TextEditingController(text: widget.hearing?.caseTitle ?? '');
    courtCtrl =
        TextEditingController(text: widget.hearing?.court ?? '');
    notesCtrl =
        TextEditingController(text: widget.hearing?.notes ?? '');
    date = widget.hearing?.dateTime ?? DateTime.now();
  }

  void _save() {
    if (titleCtrl.text.trim().isEmpty) return;

    if (widget.hearing != null) {
      widget.hearing!
        ..caseTitle = titleCtrl.text.trim()
        ..court = courtCtrl.text.trim()
        ..notes = notesCtrl.text.trim()
        ..dateTime = date
        ..save();
    } else {
      HiveService.hearingsBox.add(
        Hearing(
          clientKey: 0,
          caseTitle: titleCtrl.text.trim(),
          dateTime: date,
          court: courtCtrl.text.trim(),
          notes: notesCtrl.text.trim(),
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.hearing == null ? 'Add Hearing' : 'Edit Hearing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Case Title'),
            ),
            TextField(
              controller: courtCtrl,
              decoration: const InputDecoration(labelText: 'Court'),
            ),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(
                  'Date: ${date.toLocal().toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) setState(() => date = picked);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
