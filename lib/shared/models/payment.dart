import 'package:hive/hive.dart';
part 'payment.g.dart';

@HiveType(typeId: 2)
class Payment extends HiveObject {
  @HiveField(0)
  int clientKey;

  @HiveField(1)
  double amount; // pre-tax amount

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime dueDate;

  @HiveField(4)
  DateTime? paidDate;

  @HiveField(5)
  bool taxApplicable;

  @HiveField(6)
  double taxRate;

  @HiveField(7)
  String modeOfPayment; // 'cash', 'bank_transfer', 'card', 'cheque', 'other'
  @HiveField(8)
  bool isRetainer;

  Payment({
    required this.clientKey,
    required this.amount,
    required this.description,
    required this.dueDate,
    this.paidDate,
    this.taxApplicable = false,
    this.taxRate = 0.0,
    this.modeOfPayment = 'bank_transfer',
    this.isRetainer = false,
  });

  /// Tax amount
  double get taxAmount => taxApplicable ? amount * (taxRate / 100) : 0.0;

  /// Total including tax
  double get totalAmount => amount + taxAmount;
}
