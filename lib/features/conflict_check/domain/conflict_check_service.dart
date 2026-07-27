import 'package:intl/intl.dart';
import '../../../shared/models/hearing.dart';
import '../../../shared/models/client.dart';
import 'package:hive/hive.dart';

class ConflictCheckService {
  /// Check if a client name/phone/email already exists in opposing parties
  static List<Hearing> checkClientConflict(String clientName) {
    if (clientName.trim().isEmpty) return [];
    final box = Hive.box<Hearing>('hearings');
    final query = clientName.trim().toLowerCase();
    return box.values.where((hearing) {
      return hearing.opposingParties
          .any((op) => op.name.toLowerCase().contains(query));
    }).toList();
  }

  /// Check if an opposing party matches any existing client
  /// Matches on: name, phone, email
  static List<Client> checkOpposingPartyConflict(String opposingParty) {
    if (opposingParty.trim().isEmpty) return [];
    final clientBox = Hive.box<Client>('clients');
    final query = opposingParty.trim().toLowerCase();
    final queryDigits = query.replaceAll(RegExp(r'[^\d]'), '');
    return clientBox.values.where((client) {
      // Match on name
      if (client.name.toLowerCase().contains(query)) return true;
      // Match on phone — only if the search text actually contains digits
      if (queryDigits.isNotEmpty && client.phone.isNotEmpty) {
        final clientPhoneDigits = client.phone.replaceAll(RegExp(r'[^\d]'), '');
        if (clientPhoneDigits.isNotEmpty && clientPhoneDigits.contains(queryDigits)) {
          return true;
        }
      }
      // Match on email
      if (client.email.isNotEmpty &&
          client.email.toLowerCase().contains(query)) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Check a NEW client's identity against every opposing party ever
  /// recorded across all hearings, for all clients, all time.
  /// This is the core "did this person appear as an adverse party in the
  /// past" check — the main safeguard for new client intake.
  static List<Map<String, dynamic>> checkNewClientAgainstHistory({
    required String firstName,
    required String lastName,
    required String phone,
  }) {
    final hearingBox = Hive.box<Hearing>('hearings');
    final clientBox = Hive.box<Client>('clients');

    final fullName = '$firstName $lastName'.trim().toLowerCase();
    final phoneDigits = phone.replaceAll(RegExp(r'[^\d]'), '');

    final results = <Map<String, dynamic>>[];

    for (final hearing in hearingBox.values) {
      for (final op in hearing.opposingParties) {
        final opName = op.name.trim().toLowerCase();
        final opPhoneDigits = (op.phone ?? '').replaceAll(RegExp(r'[^\d]'), '');

        final nameMatches = fullName.isNotEmpty &&
            (opName.contains(fullName) || fullName.contains(opName));
        final phoneMatches = phoneDigits.isNotEmpty &&
            opPhoneDigits.isNotEmpty &&
            opPhoneDigits == phoneDigits;

        if (nameMatches || phoneMatches) {
          final matterClient = clientBox.get(hearing.clientKey);
          results.add({
            'opposingPartyName': op.name,
            'caseTitle': hearing.caseTitle,
            'hearingDate': hearing.dateTime,
            'matterClientName': matterClient?.fullName ?? 'Unknown Client',
            'matchedOn': nameMatches ? 'name' : 'phone',
          });
        }
      }
    }
    return results;
  }

  /// Full conflict check — returns a summary of all conflicts
  static Map<String, dynamic> fullConflictCheck({
    required String name,
    required String phone,
    required String email,
  }) {
    final clientBox = Hive.box<Client>('clients');
    final hearingBox = Hive.box<Hearing>('hearings');
    final conflicts = <String>[];

    final trimmedName = name.trim();
    final phoneDigits = phone.replaceAll(RegExp(r'[^\d]'), '');
    final trimmedEmail = email.trim().toLowerCase();

    // Check against existing clients
    for (final client in clientBox.values) {
      // Name match
      if (trimmedName.isNotEmpty &&
          client.name.toLowerCase().contains(trimmedName.toLowerCase())) {
        conflicts.add('Name matches client: ${client.name}');
      }
      // Phone match — only if both sides actually have digits
      if (phoneDigits.isNotEmpty && client.phone.isNotEmpty) {
        final clientPhoneDigits = client.phone.replaceAll(RegExp(r'[^\d]'), '');
        if (clientPhoneDigits.isNotEmpty && clientPhoneDigits == phoneDigits) {
          conflicts.add('Phone matches client: ${client.name}');
        }
      }
      // Email match
      if (trimmedEmail.isNotEmpty &&
          client.email.isNotEmpty &&
          client.email.trim().toLowerCase() == trimmedEmail) {
        conflicts.add('Email matches client: ${client.name}');
      }
    }

    // Check against opposing parties in hearings (multi-entry aware)
    for (final hearing in hearingBox.values) {
      for (final op in hearing.opposingParties) {
        final opName = op.name.trim().toLowerCase();
        final opPhoneDigits = (op.phone ?? '').replaceAll(RegExp(r'[^\d]'), '');

        final nameMatches = trimmedName.isNotEmpty &&
            opName.isNotEmpty &&
            opName.contains(trimmedName.toLowerCase());
        final phoneMatches = phoneDigits.isNotEmpty &&
            opPhoneDigits.isNotEmpty &&
            opPhoneDigits == phoneDigits;

        if (nameMatches || phoneMatches) {
          final dateStr = DateFormat('dd MMM yyyy').format(hearing.dateTime);
          conflicts.add(
              'Matches opposing party "${op.name}" in "${hearing.caseTitle}" ($dateStr)');
        }
      }
    }

    return {
      'hasConflict': conflicts.isNotEmpty,
      'conflicts': conflicts,
    };
  }
}
