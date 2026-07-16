import 'package:hive/hive.dart';
import 'client.dart';

part 'hearing.g.dart';

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

  Hearing({
    required this.caseTitle,
    required this.clientKey,
    required this.dateTime,
    this.court = '',
    this.notes = '',
    this.opposingParty = '',
  });

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
