import 'package:hive/hive.dart';

part 'payment.g.dart';

@HiveType(typeId: 2)
class Payment extends HiveObject {
  @HiveField(0)
  int clientKey;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime dueDate;

  @HiveField(4)
  DateTime? paidDate;

  Payment({
    required this.clientKey,
    required this.amount,
    required this.description,
    required this.dueDate,
    this.paidDate,
  });
}
