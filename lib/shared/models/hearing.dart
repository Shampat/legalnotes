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
  // 'completed', 'adjourned', 'appeal', 'order_received', 'further_action'
  String? outcomeStatus;
  @HiveField(8)
  String? outcomeNote;
  @HiveField(9)
  String? nextAction;
  @HiveField(10)
  DateTime? nextActionDueDate;
  @HiveField(11)
  // If this hearing was created as an appeal of another hearing, this
  // points back to the original hearing's key, for traceability.
  int? linkedFromHearingKey;

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
    this.nextAction,
    this.nextActionDueDate,
    this.linkedFromHearingKey,
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
  bool get isAppealed => outcomeStatus == 'appeal';
  bool get isOrderReceived => outcomeStatus == 'order_received';
  bool get isFurtherActionRequired => outcomeStatus == 'further_action';
  bool get hasOutcome => outcomeStatus != null && outcomeStatus!.isNotEmpty;

  String get outcomeLabel {
    switch (outcomeStatus) {
      case 'completed':
        return 'Completed';
      case 'adjourned':
        return 'Adjourned';
      case 'appeal':
        return 'Appealed';
      case 'order_received':
        return 'Order Received';
      case 'further_action':
        return 'Further Action Required';
      default:
        return '';
    }
  }

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
