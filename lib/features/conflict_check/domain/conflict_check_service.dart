import '../../../shared/models/hearing.dart';
import '../../../shared/models/client.dart';
import 'package:hive/hive.dart';

class ConflictCheckService {
  /// Check if a client name/phone/email already exists in opposing parties
  static List<Hearing> checkClientConflict(String clientName) {
    final box = Hive.box<Hearing>('hearings');
    return box.values.where((hearing) {
      return hearing.opposingParty
          .toLowerCase()
          .contains(clientName.toLowerCase());
    }).toList();
  }

  /// Check if an opposing party matches any existing client
  /// Matches on: name, phone, email
  static List<Client> checkOpposingPartyConflict(String opposingParty) {
    if (opposingParty.trim().isEmpty) return [];
    final clientBox = Hive.box<Client>('clients');
    final query = opposingParty.trim().toLowerCase();

    return clientBox.values.where((client) {
      // Match on name
      if (client.name.toLowerCase().contains(query)) return true;
      // Match on phone
      if (client.phone.isNotEmpty &&
          client.phone.replaceAll(RegExp(r'[^\d]'), '').contains(
              query.replaceAll(RegExp(r'[^\d]'), ''))) {
        return true;
      }
      // Match on email
      if (client.email.isNotEmpty &&
          client.email.toLowerCase().contains(query)) {
        return true;
      }
      return false;
    }).toList();
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

    // Check against existing clients
    for (final client in clientBox.values) {
      // Name match
      if (name.isNotEmpty &&
          client.name.toLowerCase().contains(name.toLowerCase())) {
        conflicts.add('Name matches client: ${client.name}');
      }
      // Phone match
      if (phone.isNotEmpty &&
          client.phone.isNotEmpty &&
          client.phone.replaceAll(RegExp(r'[^\d]'), '') ==
              phone.replaceAll(RegExp(r'[^\d]'), '')) {
        conflicts.add('Phone matches client: ${client.name}');
      }
      // Email match
      if (email.isNotEmpty &&
          client.email.isNotEmpty &&
          client.email.toLowerCase() == email.toLowerCase()) {
        conflicts.add('Email matches client: ${client.name}');
      }
    }

    // Check against opposing parties in hearings
    for (final hearing in hearingBox.values) {
      if (hearing.opposingParty.isEmpty) continue;
      if (name.isNotEmpty &&
          hearing.opposingParty
              .toLowerCase()
              .contains(name.toLowerCase())) {
        conflicts
            .add('Name matches opposing party in: ${hearing.caseTitle}');
      }
    }

    return {
      'hasConflict': conflicts.isNotEmpty,
      'conflicts': conflicts,
    };
  }
}
