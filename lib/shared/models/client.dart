import 'package:hive/hive.dart';
part 'client.g.dart';

@HiveType(typeId: 0)
class Client extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  String phone;
  @HiveField(2)
  String email;
  @HiveField(3)
  String address;
  @HiveField(4)
  DateTime createdAt;
  @HiveField(5)
  double totalInvoiced;
  @HiveField(6)
  String clientStatus;
  @HiveField(7)
  String matterDescription;
  @HiveField(8)
  DateTime? consultationDate;
  @HiveField(9)
  bool retainerSigned;
  @HiveField(10)
  bool nonEngagementLetterSent;
  @HiveField(11)
  String? dateOfBirth;
  @HiveField(12)
  String? companyName;
  @HiveField(13)
  String firstName;
  @HiveField(14)
  String lastName;
  @HiveField(15)
  bool isArchived;
  @HiveField(16)
  double invoiceTaxRate;
  @HiveField(17)
  String? licensePlate;
  @HiveField(18)
  String? ticketNumber;
  @HiveField(19)
  String? fileNumber;
  @HiveField(20)
  String? driversLicence;

  Client({
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email = '',
    this.address = '',
    DateTime? createdAt,
    this.totalInvoiced = 0.0,
    this.clientStatus = 'prospective',
    this.matterDescription = '',
    this.consultationDate,
    this.retainerSigned = false,
    this.nonEngagementLetterSent = false,
    this.dateOfBirth,
    this.companyName,
    this.isArchived = false,
    this.invoiceTaxRate = 0.0,
    this.licensePlate,
    this.ticketNumber,
    this.fileNumber,
    this.driversLicence,
  })  : name = '$firstName $lastName',
        createdAt = createdAt ?? DateTime.now();

  String get fullName => '$firstName $lastName'.trim();

  bool get isNonEngagementOverdue {
    if (clientStatus != 'prospective') return false;
    if (nonEngagementLetterSent) return false;
    if (consultationDate == null) return false;
    return DateTime.now().isAfter(consultationDate!.add(const Duration(hours: 24)));
  }

  bool get isNonEngagementUrgent {
    if (clientStatus != 'prospective') return false;
    if (nonEngagementLetterSent) return false;
    if (consultationDate == null) return false;
    final deadline = consultationDate!.add(const Duration(hours: 24));
    final diff = deadline.difference(DateTime.now());
    return diff.inHours <= 4 && !diff.isNegative;
  }

  DateTime? get nonEngagementDeadline {
    if (consultationDate == null) return null;
    return consultationDate!.add(const Duration(hours: 24));
  }

  String get normalizedPlate => (licensePlate ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  String get normalizedTicket => (ticketNumber ?? '').trim().toLowerCase();
}
