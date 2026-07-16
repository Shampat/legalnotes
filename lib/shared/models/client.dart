import 'package:hive/hive.dart';
part 'client.g.dart';

@HiveType(typeId: 0)
class Client extends HiveObject {
  // Existing fields — DO NOT change field numbers
  @HiveField(0)
  String name; // kept for backward compatibility

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

  // New fields
  @HiveField(13)
  String firstName;

  @HiveField(14)
  String lastName;
  @HiveField(15)
  double invoiceTaxRate;

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
    this.invoiceTaxRate = 0.0,
  })  : name = '$firstName $lastName',
        createdAt = createdAt ?? DateTime.now();

  /// Full name getter
  String get fullName => '$firstName $lastName'.trim();

  /// Returns true if 24hr non-engagement deadline has passed
  bool get isNonEngagementOverdue {
    if (clientStatus != 'prospective') return false;
    if (nonEngagementLetterSent) return false;
    if (consultationDate == null) return false;
    return DateTime.now()
        .isAfter(consultationDate!.add(const Duration(hours: 24)));
  }

  /// Returns true if deadline is within 4 hours
  bool get isNonEngagementUrgent {
    if (clientStatus != 'prospective') return false;
    if (nonEngagementLetterSent) return false;
    if (consultationDate == null) return false;
    final deadline =
        consultationDate!.add(const Duration(hours: 24));
    final diff = deadline.difference(DateTime.now());
    return diff.inHours <= 4 && !diff.isNegative;
  }

  /// Deadline datetime for non-engagement letter
  DateTime? get nonEngagementDeadline {
    if (consultationDate == null) return null;
    return consultationDate!.add(const Duration(hours: 24));
  }
}
