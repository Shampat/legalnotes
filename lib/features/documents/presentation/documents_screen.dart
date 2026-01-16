import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/database/hive_service.dart';
import '../../../core/utils/file_utils.dart';
import '../../../shared/models/document.dart';
import '../../../shared/models/client.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late final Box<Document> _documentsBox;
  late final Box<Client> _clientsBox;

  @override
  void initState() {
    super.initState();
    _documentsBox = HiveService.documentsBox;
    _clientsBox = HiveService.clientsBox;
  }

  void _addOrEditDocument([Document? document]) async {
    final isEdit = document != null;
    final titleController = TextEditingController(text: isEdit ? document.title : 'New Note');
    final contentController = TextEditingController(text: isEdit ? document.content : '');
    String? selectedClientKey = isEdit ? document.clientKey : null;
    String? currentFilePath = isEdit ? document.filePath : null;
    String? currentFileName = isEdit ? document.fileName : null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Document' : 'New Document'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedClientKey,
                    hint: const Text('Select Client'),
                    items: _clientsBox.values.map((client) {
                      return DropdownMenuItem(
                        value: client.key.toString(),
                        child: Text(client.name),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => selectedClientKey = value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(labelText: 'Content / Notes'),
                    maxLines: 8,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          currentFileName ?? 'No file attached',
                          style: TextStyle(color: currentFileName != null ? Colors.green : Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Attach'),
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.any,
                            allowMultiple: false,
                          );
                          if (result != null) {
                            final savedPath = await FileUtils.saveFileFromPicker(result);
                            if (savedPath != null) {
                              setDialogState(() {
                                currentFilePath = savedPath;
                                currentFileName = result.files.first.name;
                              });
                            }
                          }
                        },
                      ),
                      if (currentFileName != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () => setDialogState(() {
                            currentFilePath = null;
                            currentFileName = null;
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedClientKey == null ? null : () {
                if (isEdit) {
                  document!.title = titleController.text.trim().isEmpty ? 'Untitled' : titleController.text.trim();
                  document.content = contentController.text;
                  document.filePath = currentFilePath;
                  document.fileName = currentFileName;
                  document.updatedAt = DateTime.now();
                  document.save();
                } else {
                  final newDoc = Document(
                    clientKey: selectedClientKey!,
                    title: titleController.text.trim().isEmpty ? 'Untitled' : titleController.text.trim(),
                    content: contentController.text,
                    filePath: currentFilePath,
                    fileName: currentFileName,
                  );
                  _documentsBox.add(newDoc);
                }
                Navigator.pop(context);
                setState(() {});
              },
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewDocument(Document document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(document.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Client: ${document.getClientName()}'),
              Text('Created: ${document.createdAt.toLocal().toString().split('.')[0]}'),
              if (document.updatedAt != null)
                Text('Updated: ${document.updatedAt!.toLocal().toString().split('.')[0]}'),
              if (document.hasAttachment)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(document.fileName!, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              const Divider(height: 32),
              if (document.content.isNotEmpty) Text(document.content),
              if (document.content.isEmpty && !document.hasAttachment) const Text('No content'),
            ],
          ),
        ),
        actions: [
          if (document.hasAttachment)
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open File'),
              onPressed: () {
                FileUtils.openFile(document.filePath!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening ${document.fileName}')),
                );
              },
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addOrEditDocument(document);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final documents = _documentsBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Documents & Notes')),
      body: documents.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No documents yet', style: TextStyle(fontSize: 18)),
                  Text('Tap + to create a note or attach a file'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                final dateStr = doc.createdAt.toLocal().toString().split(' ')[0];

                return ListTile(
                  leading: Icon(
                    doc.hasAttachment ? Icons.attach_file : Icons.description,
                    color: doc.hasAttachment ? Colors.green : null,
                  ),
                  title: Text(doc.title),
                  subtitle: Flexible(  // ← This forces the text to fit between leading & trailing
                    child: Text(
                      '${doc.getClientName()} • $dateStr',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  trailing: doc.hasAttachment 
                      ? const Icon(Icons.attach_file, color: Colors.green)
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _viewDocument(doc),
                  onLongPress: () {
                    doc.delete();
                    setState(() {});
                  },
                );
              },
            ),
      floatingActionButton: _clientsBox.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _addOrEditDocument(),
              child: const Icon(Icons.add),
            ),
    );
  }
}
