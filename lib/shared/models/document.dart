import 'package:hive/hive.dart';
import 'client.dart';

part 'document.g.dart';

@HiveType(typeId: 3)
class Document extends HiveObject {
  @HiveField(0)
  String clientKey;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime? updatedAt;

  @HiveField(5)
  String? filePath;  // Local file path of attachment (null = no file)

  @HiveField(6)
  String? fileName;  // Original file name

  Document({
    required this.clientKey,
    required this.title,
    required this.content,
    this.filePath,
    this.fileName,
    DateTime? createdAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = null;

  String getClientName() {
    final clientBox = Hive.box<Client>('clients');
    final client = clientBox.get(clientKey);
    return client?.name ?? 'Unknown Client';
  }

  bool get hasAttachment => filePath != null && filePath!.isNotEmpty;

  @override
  String toString() {
    return '$title (${createdAt.toLocal().toString().split(' ')[0]})';
  }
}
