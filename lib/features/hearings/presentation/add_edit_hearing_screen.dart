import 'package:flutter/material.dart';
import '../../conflict_check/domain/conflict_check_service.dart';
import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/hearing.dart';
import '../../../shared/models/client.dart';

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
  late TextEditingController opposingPartyCtrl;
  DateTime? date;
  int? selectedClientKey;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.hearing?.caseTitle ?? '');
    courtCtrl = TextEditingController(text: widget.hearing?.court ?? '');
    notesCtrl = TextEditingController(text: widget.hearing?.notes ?? '');
    opposingPartyCtrl =
        TextEditingController(text: widget.hearing?.opposingParty ?? '');
    date = widget.hearing?.dateTime;
    selectedClientKey =
        widget.hearing?.clientKey == 0 ? null : widget.hearing?.clientKey;
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null) return;
    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date ?? DateTime.now()),
    );
    if (pickedTime != null) {
      setState(() {
        date = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (titleCtrl.text.trim().isEmpty) return;
    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a hearing date & time')),
      );
      return;
    }
    if (selectedClientKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }

    final opposingParty = opposingPartyCtrl.text.trim();

    // Only check conflict if opposing party is provided
    if (opposingParty.isNotEmpty) {
      final conflicts =
          ConflictCheckService.checkOpposingPartyConflict(opposingParty);
      if (conflicts.isNotEmpty) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Conflict Warning'),
            content: Text(
              'The opposing party matches an existing client:\n\n'
              '${conflicts.map((c) => c.name).join('\n')}\n\n'
              'Save anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save Anyway'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    if (widget.hearing != null) {
      widget.hearing!
        ..caseTitle = titleCtrl.text.trim()
        ..clientKey = selectedClientKey!
        ..court = courtCtrl.text.trim()
        ..notes = notesCtrl.text.trim()
        ..opposingParty = opposingParty
        ..dateTime = date!
        ..save();
    } else {
      HiveService.hearingsBox.add(
        Hearing(
          clientKey: selectedClientKey!,
          caseTitle: titleCtrl.text.trim(),
          dateTime: date!,
          court: courtCtrl.text.trim(),
          notes: notesCtrl.text.trim(),
          opposingParty: opposingParty,
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Hearing?'),
        content: Text(
            'Delete "${widget.hearing!.caseTitle}"?\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      widget.hearing!.delete();
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = HiveService.clientsBox.values.toList();
    final isEdit = widget.hearing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Hearing' : 'Add Hearing',
          style: const TextStyle(color: Colors.white),
        ),
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
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Hearing',
              onPressed: _delete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedClientKey,
                hint: const Text('Select Client'),
                items: clients.map((Client c) {
                  return DropdownMenuItem<int>(
                    value: c.key as int,
                    child: Text(c.name),
                  );
                }).toList(),
                onChanged: (val) =>
                    setState(() => selectedClientKey = val),
                decoration: InputDecoration(
                  labelText: 'Client',
                  filled: true,
                  fillColor: Colors.indigo.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration:
                    const InputDecoration(labelText: 'Case Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: courtCtrl,
                decoration: const InputDecoration(labelText: 'Court'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: opposingPartyCtrl,
                decoration:
                    const InputDecoration(labelText: 'Opposing Party (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDateTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date & Time',
                    filled: true,
                    fillColor: Colors.indigo.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    date != null
                        ? date!.toLocal().toString().split('.')[0]
                        : 'Tap to select a future date & time',
                    style: TextStyle(
                      fontSize: date != null ? 15 : 16,
                      fontWeight: date != null
                          ? FontWeight.normal
                          : FontWeight.bold,
                      color: date != null
                          ? Colors.black87
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isEdit ? 'Update Hearing' : 'Add Hearing',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
