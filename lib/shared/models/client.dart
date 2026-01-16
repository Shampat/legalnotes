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
  double totalInvoiced = 0.0;  // Total billed to this client

  Client({
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    DateTime? createdAt,
    this.totalInvoiced = 0.0,
  }) : createdAt = createdAt ?? DateTime.now();
}
