import 'dart:io';
import 'package:file_picker/file_picker.dart';  // ← This was missing!
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static Future<String?> saveFileFromPicker(FilePickerResult result) async {
    if (result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.bytes == null && file.path == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final documentsDir = Directory('${appDir.path}/attachments');
    await documentsDir.create(recursive: true);

    final fileName = file.name;
    final filePath = '${documentsDir.path}/$fileName';

    // Avoid overwriting - add timestamp if exists
    String finalPath = filePath;
    int counter = 1;
    while (await File(finalPath).exists()) {
      final ext = path.extension(fileName);
      final nameWithoutExt = path.basenameWithoutExtension(fileName);
      final newName = '${nameWithoutExt}_$counter$ext';
      finalPath = '${documentsDir.path}/$newName';
      counter++;
    }

    if (file.bytes != null) {
      await File(finalPath).writeAsBytes(file.bytes!);
    } else if (file.path != null) {
      await File(file.path!).copy(finalPath);
    }

    return finalPath;
  }

  static Future<void> openFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      print('File ready to open: $filePath');
      // Future: use open_file_x package to actually open it
    }
  }
}
