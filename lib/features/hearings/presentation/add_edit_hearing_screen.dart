import 'package:flutter/material.dart';
import '../../conflict_check/domain/conflict_check_service.dart';
import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/hearing.dart';
import '../../../shared/models/client.dart';
import '../../../core/config/canada_holidays.dart';

class AddEditHearingScreen extends StatefulWidget {
  final Hearing? hearing;
  final int? prefillClientKey;
  final String? prefillCaseTitle;
  final int? linkedFromHearingKey;
  const AddEditHearingScreen({
    super.key,
    this.hearing,
    this.prefillClientKey,
    this.prefillCaseTitle,
    this.linkedFromHearingKey,
  });

  @override
  State<AddEditHearingScreen> createState() => _AddEditHearingScreenState();
}

class _OpposingPartyEntry {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  _OpposingPartyEntry({String name = '', String phone = ''})
      : nameCtrl = TextEditingController(text: name),
        phoneCtrl = TextEditingController(text: phone);

  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
  }
}

class _AddEditHearingScreenState extends State<AddEditHearingScreen> {
  late TextEditingController titleCtrl;
  late TextEditingController courtCtrl;
  late TextEditingController notesCtrl;
  late List<_OpposingPartyEntry> opposingParties;
  DateTime? date;
  int? selectedClientKey;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(
        text: widget.hearing?.caseTitle ?? widget.prefillCaseTitle ?? '');
    courtCtrl = TextEditingController(text: widget.hearing?.court ?? '');
    notesCtrl = TextEditingController(text: widget.hearing?.notes ?? '');
    final existing = widget.hearing?.opposingParties ?? [];
    opposingParties = existing.isNotEmpty
        ? existing
            .map((op) => _OpposingPartyEntry(name: op.name, phone: op.phone ?? ''))
            .toList()
        : [_OpposingPartyEntry()];
    date = widget.hearing?.dateTime;
    selectedClientKey = widget.hearing?.clientKey == 0
        ? null
        : (widget.hearing?.clientKey ?? widget.prefillClientKey);
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    courtCtrl.dispose();
    notesCtrl.dispose();
    for (final op in opposingParties) {
      op.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null) return;
    // Prevention at source: Court Closed check
    final holiday = CanadaHolidays.holidayName(pickedDate);
    if (holiday != null && mounted) {
      final next = CanadaHolidays.nextBusinessDay(pickedDate);
      final chooseAnother = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Court Closed'),
          content: Text(
            '${pickedDate.day}/${pickedDate.month}/${pickedDate.year} - $holiday\n'
            'Courts are closed in ${CanadaHolidays.currentProvince} on this day.\n\n'
            'Suggested next business day: ${next.day}/${next.month}/${next.year}\n\n'
            'Pick another date?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Use This Date Anyway')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pick Another Date')),
          ],
        ),
      );
      if (chooseAnother == true) {
        return _pickDateTime();
      }
    }
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

    final validEntries = opposingParties
        .where((op) => op.nameCtrl.text.trim().isNotEmpty)
        .toList();

    final opposingPartiesList = validEntries
        .map((op) => OpposingParty(
              name: op.nameCtrl.text.trim(),
              phone: op.phoneCtrl.text.trim().isEmpty
                  ? null
                  : op.phoneCtrl.text.trim(),
            ))
        .toList();

    final legacyOpposingParty =
        validEntries.map((op) => op.nameCtrl.text.trim()).join(', ');

    // Check conflict for each opposing party name entered
    if (validEntries.isNotEmpty) {
      final allMatches = <Client>[];
      final seenKeys = <int>{};
      for (final op in validEntries) {
        final matches = ConflictCheckService.checkOpposingPartyConflict(
            op.nameCtrl.text.trim());
        for (final m in matches) {
          final k = m.key as int;
          if (!seenKeys.contains(k)) {
            seenKeys.add(k);
            allMatches.add(m);
          }
        }
      }
      if (allMatches.isNotEmpty) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Conflict Warning'),
            content: Text(
              'An opposing party matches an existing client:\n\n'
              '${allMatches.map((c) => c.name).join('\n')}\n\n'
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
        ..opposingParty = legacyOpposingParty
        ..opposingPartiesList = opposingPartiesList
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
          opposingParty: legacyOpposingParty,
          opposingPartiesList: opposingPartiesList,
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

  Widget _buildOpposingPartyFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opposing Parties (optional)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        ...opposingParties.asMap().entries.map((entry) {
          final i = entry.key;
          final op = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: op.nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'Opposing party ${i + 1}',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: op.phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ),
                if (opposingParties.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        op.dispose();
                        opposingParties.removeAt(i);
                      });
                    },
                  ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            setState(() {
              opposingParties.add(_OpposingPartyEntry());
            });
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add another'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final clients = HiveService.clientsBox.values.toList();
    final isEdit = widget.hearing != null;
    final validClientKeys = clients.map((c) => c.key as int).toSet();
    final isOrphaned = selectedClientKey != null &&
        !validClientKeys.contains(selectedClientKey);
    if (isOrphaned) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => selectedClientKey = null);
      });
    }

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                if (isOrphaned)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'The original client for this hearing was deleted. Please select a client below, or delete this hearing.',
                            style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                DropdownButtonFormField<int>(
                  initialValue: isOrphaned ? null : selectedClientKey,
                  hint: const Text('Select Client'),
                  isExpanded: true,
                  items: clients.map((Client c) {
                    return DropdownMenuItem<int>(
                      value: c.key as int,
                      child: Text(
                        c.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (isEdit && !isOrphaned)
                      ? null
                      : (val) => setState(() => selectedClientKey = val),
                  decoration: InputDecoration(
                    labelText: 'Client',
                    filled: true,
                    fillColor: (isEdit && !isOrphaned)
                        ? Colors.grey.shade200
                        : Colors.indigo.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    helperText: (isEdit && !isOrphaned)
                        ? 'Client cannot be changed once a hearing is created'
                        : null,
                    helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
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
                _buildOpposingPartyFields(),
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
