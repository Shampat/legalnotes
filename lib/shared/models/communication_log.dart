import 'package:hive/hive.dart';
part 'communication_log.g.dart';

@HiveType(typeId: 4)
class CommunicationLog extends HiveObject {
  @HiveField(0)
  int clientKey;

  @HiveField(1)
  String note;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  String channel; // 'call', 'email', 'whatsapp', 'note'

  @HiveField(4)
  String status; // 'connected', 'not_connected', 'voicemail', 'pending'

  CommunicationLog({
    required this.clientKey,
    required this.note,
    required this.channel,
    this.status = 'connected',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
