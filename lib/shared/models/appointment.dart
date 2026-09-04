
import 'package:hive/hive.dart';
part 'appointment.g.dart';

@HiveType(typeId: 6)
class Appointment extends HiveObject {
  @HiveField(0)
  int clientKey;
  @HiveField(1)
  String title;
  @HiveField(2)
  String? location;
  @HiveField(3)
  DateTime dateTime;
  @HiveField(4)
  String? notes;
  @HiveField(5)
  bool isDone;

  Appointment({
    required this.clientKey,
    required this.title,
    this.location,
    required this.dateTime,
    this.notes,
    this.isDone = false,
  });
}
