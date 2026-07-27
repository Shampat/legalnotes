import 'package:hive/hive.dart';
import 'client.dart';
part 'hearing.g.dart';

@HiveType(typeId: 5)
class OpposingParty extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  String? phone;

  OpposingParty({required this.name, this.phone});
}

@HiveType(typeId: 1)
class Hearing extends HiveObject {
  @HiveField(0)
  String caseTitle;
  @HiveField(1)
  int clientKey;
  @HiveField(2)
  DateTime dateTime;
  @HiveField(3)
  String court;
  @HiveField(4)
  String notes;
  @HiveField(5)
  String opposingParty;
  @HiveField(6)
  List<OpposingParty>? opposingPartiesList;
  @HiveField(7)
  String? outcomeStatus; // null/empty = pending, 'completed', 'adjourned'
  @HiveField(8)
  String? outcomeNote;

  Hearing({
    required this.caseTitle,
    required this.clientKey,
    required this.dateTime,
    this.court = '',
    this.notes = '',
    this.opposingParty = '',
    this.opposingPartiesList,
    this.outcomeStatus,
    this.outcomeNote,
  });

  /// Unified accessor: uses the new multi-entry list if present,
  /// otherwise falls back to the legacy single opposingParty string.
  List<OpposingParty> get opposingParties {
    if (opposingPartiesList != null && opposingPartiesList!.isNotEmpty) {
      return opposingPartiesList!;
    }
    if (opposingParty.trim().isNotEmpty) {
      return [OpposingParty(name: opposingParty.trim())];
    }
    return [];
  }

  bool get isCompleted => outcomeStatus == 'completed';
  bool get isAdjourned => outcomeStatus == 'adjourned';
  bool get hasOutcome => isCompleted || isAdjourned;

  String getClientName() {
    final clientBox = Hive.box<Client>('clients');
    final client = clientBox.get(clientKey);
    return client?.fullName ?? 'Unknown Client';
  }

  @override
  String toString() {
    return '\$caseTitle - \${dateTime.toLocal().toString().split(' ')[0]}';
  }
}
