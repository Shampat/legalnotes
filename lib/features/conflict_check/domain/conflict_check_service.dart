import 'package:intl/intl.dart';
import '../../../shared/models/hearing.dart';
import '../../../shared/models/client.dart';
import 'package:hive/hive.dart';

class ConflictCheckService {
  static String _norm(String? v) => (v ?? '').trim().toLowerCase();
  static String _digits(String? v) => (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  static String _normPlate(String? v) => (v ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static bool _nameMatches(String a, String b) {
    final na = _norm(a);
    final nb = _norm(b);
    if (na.isEmpty || nb.isEmpty) return false;
    if (na == nb) return true;
    final aParts = na.split(RegExp(r'\s+'));
    final bParts = nb.split(RegExp(r'\s+'));
    if (aParts.length >= 2 && bParts.length >= 2) {
      return aParts.first == bParts.first && aParts.last == bParts.last;
    }
    return false;
  }

  static Map<String, dynamic> fullConflictCheck({
    required String name,
    String phone = '',
    String email = '',
    String dateOfBirth = '',
    String licensePlate = '',
    String ticketNumber = '',
    String fileNumber = '',
  }) {
    final clientBox = Hive.box<Client>('clients');
    final hearingBox = Hive.box<Hearing>('hearings');
    final qName = _norm(name);
    final qPhone = _digits(phone);
    final qEmail = _norm(email);
    final qDob = _norm(dateOfBirth);
    final qPlate = _normPlate(licensePlate);
    final qTicket = _norm(ticketNumber);
    final qFile = _norm(fileNumber);
    final List<Map<String, dynamic>> hits = [];

    void addHit({required String type, required String matchedOn, required String score, required String detail, String? caseTitle, DateTime? hearingDate, String? matterClientName}) {
      hits.add({'type': type, 'matchedOn': matchedOn, 'score': score, 'detail': detail, 'caseTitle': caseTitle, 'hearingDate': hearingDate, 'matterClientName': matterClientName});
    }

    for (final client in clientBox.values) {
      final matchedOn = <String>[];
      if (_nameMatches(qName, client.fullName)) matchedOn.add('name');
      if (qPhone.isNotEmpty && qPhone.length >= 7 && _digits(client.phone) == qPhone) matchedOn.add('phone');
      if (qEmail.isNotEmpty && _norm(client.email) == qEmail) matchedOn.add('email');
      if (qDob.isNotEmpty && _norm(client.dateOfBirth) == qDob) matchedOn.add('dob');
      if (qPlate.isNotEmpty && client.normalizedPlate == qPlate) matchedOn.add('plate');
      if (qTicket.isNotEmpty && _norm(client.ticketNumber) == qTicket) matchedOn.add('ticket');
      if (qFile.isNotEmpty && _norm(client.fileNumber) == qFile) matchedOn.add('fileNumber');
      if (matchedOn.isNotEmpty) {
        final isHard = matchedOn.any((m) => m != 'name');
        addHit(type: 'CLIENT', matchedOn: matchedOn.join(', '), score: isHard ? 'HARD' : 'POSSIBLE', detail: 'Matches existing client: ${client.fullName}');
      }
    }

    for (final hearing in hearingBox.values) {
      for (final op in hearing.opposingParties) {
        final matchedOn = <String>[];
        if (_nameMatches(qName, op.name)) matchedOn.add('name');
        if (qPhone.isNotEmpty && _digits(op.phone) == qPhone) matchedOn.add('phone');
        if (matchedOn.isNotEmpty) {
          final matterClient = clientBox.get(hearing.clientKey);
          final dateStr = DateFormat('dd MMM yyyy').format(hearing.dateTime);
          addHit(type: 'OPPOSING_PARTY', matchedOn: matchedOn.join(', '), score: matchedOn.any((m) => m != 'name') ? 'HARD' : 'POSSIBLE', detail: 'Matches opposing party "${op.name}" in "${hearing.caseTitle}" ($dateStr)', caseTitle: hearing.caseTitle, hearingDate: hearing.dateTime, matterClientName: matterClient?.fullName ?? 'Unknown Client');
        }
      }
    }

    hits.sort((a, b) => a['score'] == 'HARD' ? -1 : 1);
    return {'hasConflict': hits.isNotEmpty, 'hasHardConflict': hits.any((h) => h['score'] == 'HARD'), 'hits': hits, 'conflicts': hits.map((h) => '[${h['score']}] ${h['detail']} (matched on: ${h['matchedOn']})').toList()};
  }

  // Legacy callers expect List<Client> for a single opposing-party name.
  // Kept for hearings + reports + conflict report screen.
  static List<Client> checkOpposingPartyConflict(String opposingPartyName) {
    if (opposingPartyName.trim().isEmpty) return [];
    final box = Hive.box<Client>('clients');
    return box.values.where((c) => _nameMatches(opposingPartyName, c.fullName)).toList();
  }

  static List<Hearing> checkClientConflict(String clientName) {
    if (clientName.trim().isEmpty) return [];
    final box = Hive.box<Hearing>('hearings');
    return box.values.where((h) => h.opposingParties.any((op) => _nameMatches(clientName, op.name))).toList();
  }
}
