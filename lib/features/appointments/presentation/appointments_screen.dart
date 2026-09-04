import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../shared/models/appointment.dart';
import '../../../core/services/database/hive_service.dart';
import 'add_edit_appointment_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  List<Appointment> _forDay(DateTime day, List<Appointment> all) {
    return all.where((a) => a.dateTime.year==day.year && a.dateTime.month==day.month && a.dateTime.day==day.day).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar'), backgroundColor: const Color(0xFF7C4DFF), foregroundColor: Colors.white),
      body: ValueListenableBuilder(
        valueListenable: HiveService.appointmentsBox.listenable(),
        builder: (context, Box<Appointment> box, _) {
          final all = box.values.toList()..sort((a,b)=>a.dateTime.compareTo(b.dateTime));
          final selectedList = _selected==null? all : _forDay(_selected!, all);
          return Column(children: [
            Container(
              color: const Color(0xFF7C4DFF),
              padding: const EdgeInsets.fromLTRB(16,0,16,12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: ()=> setState(()=> _focused=DateTime(_focused.year, _focused.month-1))),
                  Text('${_monthName(_focused.month)} ${_focused.year}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white), onPressed: ()=> setState(()=> _focused=DateTime(_focused.year, _focused.month+1))),
                ]),
                const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ _W('S'), _W('M'), _W('T'), _W('W'), _W('T'), _W('F'), _W('S')]),
                const SizedBox(height: 6),
                _buildGrid(all),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_selected==null? 'All (${all.length})' : '${_selected!.day}/${_selected!.month} - ${selectedList.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (_selected!=null) TextButton(onPressed: ()=> setState(()=> _selected=null), child: const Text('Show All', style: TextStyle(fontSize: 12))),
              ]),
            ),
            Expanded(
              child: selectedList.isEmpty
               ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.event_available, size: 50, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(_selected==null? 'No appointments' : 'No appointments on this day', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> AddEditAppointmentScreen(initialDate: _selected?? DateTime.now()))), child: const Text('Add Appointment')),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: selectedList.length,
                    itemBuilder: (_,i){
                      final a = selectedList[i];
                      final isPast = a.dateTime.isBefore(DateTime.now());
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(color: isPast? Colors.grey[200] : const Color(0xFFEDE7F6), borderRadius: BorderRadius.circular(10), border: Border(left: BorderSide(color: isPast? Colors.grey : const Color(0xFF7C4DFF), width: 4))),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(radius: 16, backgroundColor: const Color(0xFF7C4DFF), child: Text('${a.dateTime.hour}:${a.dateTime.minute.toString().padLeft(2,'0')}', style: const TextStyle(color: Colors.white, fontSize: 8))),
                          title: Text(a.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, decoration: isPast? TextDecoration.lineThrough: null)),
                          subtitle: Text(a.location??'', style: const TextStyle(fontSize: 11)),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> AddEditAppointmentScreen(appointment: a)))),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 18), onPressed: ()=> box.delete(a.key)),
                          ]),
                        ),
                      );
                    },
                  ),
            ),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: const Color(0xFF7C4DFF),
        onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> AddEditAppointmentScreen(initialDate: _selected?? DateTime.now()))),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // FIXED: No overflow in 38.9x31 cells
  Widget _buildGrid(List<Appointment> all) {
    final first = DateTime(_focused.year, _focused.month, 1);
    final daysInMonth = DateTime(_focused.year, _focused.month+1, 0).day;
    final startWeekday = first.weekday % 7;
    final totalCells = startWeekday + daysInMonth;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.4),
      itemCount: totalCells,
      itemBuilder: (_, idx) {
        if (idx < startWeekday) return const SizedBox();
        final dayNum = idx - startWeekday + 1;
        final date = DateTime(_focused.year, _focused.month, dayNum);
        final hasAppt = all.any((a)=> a.dateTime.year==date.year && a.dateTime.month==date.month && a.dateTime.day==date.day);
        final isSelected = _selected!=null && _selected!.year==date.year && _selected!.month==date.month && _selected!.day==date.day;
        final isToday = DateTime.now().year==date.year && DateTime.now().month==date.month && DateTime.now().day==date.day;
        return GestureDetector(
          onTap: ()=> setState(()=> _selected=date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: isSelected? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(6), border: isToday? Border.all(color: Colors.white, width: 1) : null),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min, // FIX: was max causing overflow
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$dayNum', style: TextStyle(fontSize: 12, color: isSelected? const Color(0xFF7C4DFF) : Colors.white, fontWeight: isSelected||isToday? FontWeight.bold: FontWeight.normal)),
                  if (hasAppt) Container(margin: const EdgeInsets.only(top: 1), width: 4, height: 4, decoration: BoxDecoration(color: isSelected? const Color(0xFF7C4DFF): Colors.yellowAccent, shape: BoxShape.circle)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
}
class _W extends StatelessWidget { final String t; const _W(this.t); @override Widget build(BuildContext context) => const SizedBox(width: 20, child: Text('S', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 11))); }
