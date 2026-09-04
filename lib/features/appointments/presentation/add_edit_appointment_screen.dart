import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/models/client.dart';
import '../../../core/services/database/hive_service.dart';

class AddEditAppointmentScreen extends StatefulWidget {
  final Appointment? appointment;
  final DateTime? initialDate;
  const AddEditAppointmentScreen({super.key, this.appointment, this.initialDate});
  @override
  State<AddEditAppointmentScreen> createState() => _AddEditAppointmentScreenState();
}

class _AddEditAppointmentScreenState extends State<AddEditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _locationCtrl;
  late DateTime _dateTime;
  int? _selectedClientKey;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.appointment?.title?? '');
    _locationCtrl = TextEditingController(text: widget.appointment?.location?? '');
    _dateTime = widget.appointment?.dateTime ?? widget.initialDate ?? DateTime.now().add(const Duration(hours: 1));
    _selectedClientKey = widget.appointment?.clientKey;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill title')));
      return;
    }
    setState(()=> _saving=true);
    try {
      // Use dynamic constructor to support any Appointment model
      // Try with minimal fields first
      final box = HiveService.appointmentsBox;
      
      Appointment newAppt;
      try {
        // Most common model: title, clientKey, dateTime, location
        newAppt = Appointment(
          title: _titleCtrl.text.trim(),
          clientKey: _selectedClientKey?? 0,
          dateTime: _dateTime,
          location: _locationCtrl.text.trim(),
        );
      } catch (e) {
        // Fallback if model has different constructor
        print('Constructor error: $e');
        rethrow;
      }

      if (widget.appointment!=null && widget.appointment!.key!=null) {
        await box.put(widget.appointment!.key, newAppt);
      } else {
        await box.add(newAppt);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment saved!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
      }
    } finally {
      if (mounted) setState(()=> _saving=false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.appointment==null? 'New Appointment' : 'Edit Appointment'), backgroundColor: const Color(0xFF7C4DFF), foregroundColor: Colors.white),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
              validator: (v)=> v==null||v.trim().isEmpty? 'Title required' : null,
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: HiveService.clientsBox.listenable(),
              builder: (context, Box<Client> box, _) {
                final clients = box.values.toList();
                return DropdownButtonFormField<int>(
                  value: _selectedClientKey,
                  decoration: const InputDecoration(labelText: 'Client', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No client')),
                    ...clients.map((c) => DropdownMenuItem(value: c.key as int, child: Text(c.fullName))),
                  ],
                  onChanged: (v)=> setState(()=> _selectedClientKey=v),
                );
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: _dateTime, firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (date==null) return;
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dateTime));
                if (time==null) return;
                setState(()=> _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.calendar_month, color: Color(0xFF7C4DFF)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Date & Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('${_dateTime.day}/${_dateTime.month}/${_dateTime.year}  ${_dateTime.hour.toString().padLeft(2,'0')}:${_dateTime.minute.toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const Spacer(),
                  const Icon(Icons.edit),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on))),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF), foregroundColor: Colors.white),
                onPressed: _saving? null : _save,
                child: _saving? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(widget.appointment==null? 'Create Appointment' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
