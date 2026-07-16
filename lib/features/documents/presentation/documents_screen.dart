import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/database/hive_service.dart';
import '../../../core/utils/file_utils.dart';
import '../../../shared/models/document.dart';
import '../../../shared/models/client.dart';

enum _DocFilter { all, notes, attachments }

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late final Box<Document> _documentsBox;
  late final Box<Client> _clientsBox;
  final TextEditingController _searchCtrl = TextEditingController();
  _DocFilter _filter = _DocFilter.all;

  @override
  void initState() {
    super.initState();
    _documentsBox = HiveService.documentsBox;
    _clientsBox = HiveService.clientsBox;
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Document> _filtered() {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _documentsBox.values.where((doc) {
      final matchesFilter = _filter == _DocFilter.all
          ? true
          : _filter == _DocFilter.notes
              ? !doc.hasAttachment
              : doc.hasAttachment;
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return doc.title.toLowerCase().contains(query) ||
          doc.content.toLowerCase().contains(query) ||
          doc.getClientName().toLowerCase().contains(query) ||
          (doc.fileName?.toLowerCase().contains(query) ?? false);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _addOrEditDocument([Document? document]) async {
    final isEdit = document != null;
    final titleController =
        TextEditingController(text: isEdit ? document.title : '');
    final contentController =
        TextEditingController(text: isEdit ? document.content : '');
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
                    initialValue: selectedClientKey,
                    hint: const Text('Select Client'),
                    items: _clientsBox.values.map((client) {
                      return DropdownMenuItem(
                        value: client.key.toString(),
                        child: Text(client.fullName),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedClientKey = value),
                    decoration: InputDecoration(
                      labelText: 'Client',
                      filled: true,
                      fillColor: Colors.blue.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Document Title',
                      hintText: 'e.g. Retainer Agreement',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    decoration:
                        const InputDecoration(labelText: 'Notes / Content'),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          currentFileName ?? 'No file attached',
                          style: TextStyle(
                              color: currentFileName != null
                                  ? Colors.green.shade700
                                  : Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Attach'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000080),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final result = await FilePicker.platform
                              .pickFiles(type: FileType.any);
                          if (result != null) {
                            final savedPath =
                                await FileUtils.saveFileFromPicker(result);
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
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedClientKey == null
                  ? null
                  : () {
                      final title = titleController.text.trim().isEmpty
                          ? 'Untitled'
                          : titleController.text.trim();
                      if (isEdit) {
                        document
                          ..title = title
                          ..content = contentController.text
                          ..filePath = currentFilePath
                          ..fileName = currentFileName
                          ..updatedAt = DateTime.now()
                          ..save();
                      } else {
                        _documentsBox.add(Document(
                          clientKey: selectedClientKey!,
                          title: title,
                          content: contentController.text,
                          filePath: currentFilePath,
                          fileName: currentFileName,
                        ));
                      }
                      Navigator.pop(context);
                      setState(() {});
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteDocument(Document doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text('Delete "${doc.title}"?\nThis cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      doc.delete();
      setState(() {});
    }
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
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(document.getClientName(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080))),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                  'Created: ${document.createdAt.toLocal().toString().split('.')[0]}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (document.updatedAt != null)
                Text(
                    'Updated: ${document.updatedAt!.toLocal().toString().split('.')[0]}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              if (document.hasAttachment) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.attach_file,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(document.fileName!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.green))),
                  ],
                ),
              ],
              if (document.content.isNotEmpty) ...[
                const Divider(height: 24),
                Text(document.content),
              ],
              if (document.content.isEmpty && !document.hasAttachment) ...[
                const Divider(height: 24),
                const Text('No content',
                    style: TextStyle(color: Colors.grey)),
              ],
            ],
          ),
        ),
        actions: [
          if (document.hasAttachment)
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                FileUtils.openFile(document.filePath!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Opening ${document.fileName}')),
                );
              },
            ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addOrEditDocument(document);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000080),
              foregroundColor: Colors.white,
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = _filtered();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents & Notes',
            style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Color(0xFF000080)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by title, client, content, file…',
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF000080)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.blue.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _chip('All', _DocFilter.all),
                _chip('Notes', _DocFilter.notes),
                _chip('Attachments', _DocFilter.attachments),
                Text('${docs.length} found',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),

          // List
          Expanded(
            child: docs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchCtrl.text.isNotEmpty
                              ? Icons.search_off
                              : Icons.folder_open,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchCtrl.text.isNotEmpty
                              ? 'No documents match your search'
                              : 'No documents yet',
                          style: const TextStyle(fontSize: 18),
                        ),
                        if (_searchCtrl.text.isEmpty)
                          const Text(
                              'Tap + to create a note or attach a file'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final dateStr = doc.createdAt
                          .toLocal()
                          .toString()
                          .split(' ')[0];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          leading: Icon(
                            doc.hasAttachment
                                ? Icons.attach_file
                                : Icons.description,
                            color: doc.hasAttachment
                                ? Colors.green.shade700
                                : const Color(0xFF000080),
                          ),
                          title: Text(doc.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${doc.getClientName()} • $dateStr'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit,
                                color: Color(0xFF000080), size: 20),
                            onPressed: () => _addOrEditDocument(doc),
                          ),
                          onTap: () => _viewDocument(doc),
                          onLongPress: () => _deleteDocument(doc),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _clientsBox.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _addOrEditDocument(),
              backgroundColor: const Color(0xFF000080),
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _chip(String label, _DocFilter value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: const Color(0xFF000080),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF000080),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
