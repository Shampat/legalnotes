import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/client.dart';

class ImportClientsScreen extends StatefulWidget {
  const ImportClientsScreen({super.key});

  @override
  State<ImportClientsScreen> createState() => _ImportClientsScreenState();
}

const List<String> _appFields = [
  'firstName',
  'lastName',
  'phone',
  'email',
  'address',
  'dateOfBirth',
  'companyName',
  'matterDescription',
];

const Map<String, String> _fieldLabels = {
  'firstName': 'First Name *',
  'lastName': 'Last Name *',
  'phone': 'Phone *',
  'email': 'Email',
  'address': 'Address',
  'dateOfBirth': 'Date of Birth',
  'companyName': 'Company Name',
  'matterDescription': 'Matter Description',
};

class _ImportClientsScreenState extends State<ImportClientsScreen> {
  int _step = 0;
  List<String> _headers = [];
  List<List<dynamic>> _rows = [];
  final Map<String, String?> _mapping = {};
  List<Map<String, dynamic>> _preview = [];
  bool _importing = false;
  int _importedCount = 0;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;

    try {
      final content = await File(path).readAsString();
      final rows = const CsvToListConverter(eol: '\n').convert(content);
      if (rows.isEmpty) {
        _showError('The file appears to be empty.');
        return;
      }
      setState(() {
        _headers = rows.first.map((h) => h.toString().trim()).toList();
        _rows = rows.sublist(1);
        for (final field in _appFields) {
          _mapping[field] = _guessColumn(field);
        }
        _step = 1;
      });
    } catch (e) {
      _showError('Could not read this file. Please make sure it is a valid CSV.');
    }
  }

  String? _guessColumn(String field) {
    final candidates = {
      'firstName': ['first name', 'firstname', 'given name', 'first'],
      'lastName': ['last name', 'lastname', 'surname', 'family name', 'last'],
      'phone': ['phone', 'mobile', 'cell', 'telephone', 'phone number'],
      'email': ['email', 'e-mail', 'email address'],
      'address': ['address', 'home address', 'mailing address'],
      'dateOfBirth': ['dob', 'date of birth', 'birthday', 'birth date'],
      'companyName': ['company', 'company name', 'business name', 'organization'],
      'matterDescription': ['matter', 'matter description', 'notes', 'description'],
    };
    final options = candidates[field] ?? [];
    for (final header in _headers) {
      final h = header.toLowerCase().trim();
      if (options.contains(h)) return header;
    }
    return null;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String? _tryParseDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final formats = [
      RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$'), // yyyy-MM-dd
      RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$'), // MM/dd/yyyy or dd/MM/yyyy
      RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$'),
    ];
    for (final fmt in formats) {
      final m = fmt.firstMatch(trimmed);
      if (m != null) {
        try {
          if (fmt == formats[0]) {
            final y = int.parse(m.group(1)!);
            final mo = int.parse(m.group(2)!);
            final d = int.parse(m.group(3)!);
            DateTime(y, mo, d);
            return '${y.toString().padLeft(4, '0')}-${mo.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
          } else {
            final a = int.parse(m.group(1)!);
            final b = int.parse(m.group(2)!);
            final y = int.parse(m.group(3)!);
            final mo = a <= 12 ? a : b;
            final d = a <= 12 ? b : a;
            DateTime(y, mo, d);
            return '${y.toString().padLeft(4, '0')}-${mo.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
          }
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }

  void _buildPreview() {
    final existingClients = HiveService.clientsBox.values.toList();
    final preview = <Map<String, dynamic>>[];

    int colIndex(String? header) {
      if (header == null) return -1;
      return _headers.indexOf(header);
    }

    final firstNameIdx = colIndex(_mapping['firstName']);
    final lastNameIdx = colIndex(_mapping['lastName']);
    final phoneIdx = colIndex(_mapping['phone']);
    final emailIdx = colIndex(_mapping['email']);
    final addressIdx = colIndex(_mapping['address']);
    final dobIdx = colIndex(_mapping['dateOfBirth']);
    final companyIdx = colIndex(_mapping['companyName']);
    final matterIdx = colIndex(_mapping['matterDescription']);

    String cell(List<dynamic> row, int idx) {
      if (idx < 0 || idx >= row.length) return '';
      return row[idx]?.toString().trim() ?? '';
    }

    for (final row in _rows) {
      if (row.every((c) => c.toString().trim().isEmpty)) continue;

      final firstName = cell(row, firstNameIdx);
      final lastName = cell(row, lastNameIdx);
      final phone = cell(row, phoneIdx);
      final email = cell(row, emailIdx);
      final address = cell(row, addressIdx);
      final dobRaw = cell(row, dobIdx);
      final dob = dobRaw.isNotEmpty ? _tryParseDate(dobRaw) : null;
      final company = cell(row, companyIdx);
      final matter = cell(row, matterIdx);

      String? skipReason;
      if (phone.isEmpty) {
        skipReason = 'Missing phone number';
      } else {
        final phoneDigits = phone.replaceAll(RegExp(r'[^\d]'), '');
        final nameKey = '$firstName $lastName'.trim().toLowerCase();
        final isDuplicate = existingClients.any((c) {
          final existingPhoneDigits = c.phone.replaceAll(RegExp(r'[^\d]'), '');
          final existingNameKey = c.fullName.trim().toLowerCase();
          return (existingPhoneDigits.isNotEmpty &&
                  existingPhoneDigits == phoneDigits) ||
              (nameKey.isNotEmpty && existingNameKey == nameKey);
        });
        if (isDuplicate) skipReason = 'Possible duplicate';
      }

      preview.add({
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'address': address,
        'dateOfBirth': dob,
        'dobRaw': dobRaw,
        'companyName': company,
        'matterDescription': matter.isNotEmpty ? matter : 'Imported client — details pending',
        'skipReason': skipReason,
      });
    }

    setState(() {
      _preview = preview;
      _step = 2;
    });
  }

  Future<void> _confirmImport() async {
    setState(() => _importing = true);
    int count = 0;
    for (final row in _preview) {
      if (row['skipReason'] != null) continue;
      final client = Client(
        firstName: row['firstName'] as String,
        lastName: row['lastName'] as String,
        phone: row['phone'] as String,
        email: (row['email'] as String?) ?? '',
        address: (row['address'] as String?) ?? '',
        matterDescription: row['matterDescription'] as String,
        dateOfBirth: row['dateOfBirth'] as String?,
        companyName: (row['companyName'] as String?)?.isNotEmpty == true
            ? row['companyName'] as String
            : null,
      );
      await HiveService.clientsBox.add(client);
      count++;
    }
    setState(() {
      _importing = false;
      _importedCount = count;
      _step = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Clients', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
      body: SafeArea(child: _buildStep()),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildPickStep();
      case 1:
        return _buildMappingStep();
      case 2:
        return _buildPreviewStep();
      default:
        return _buildDoneStep();
    }
  }

  Widget _buildPickStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.upload_file, size: 64, color: Color(0xFF000080)),
            const SizedBox(height: 16),
            const Text(
              'Import clients from a CSV file exported from your laptop or another system.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open, color: Colors.white),
              label: const Text('Choose CSV File', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMappingStep() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.indigo.shade50,
          child: const Text(
            'Match each field below to a column from your file. Fields marked * are required.',
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _appFields.length,
            itemBuilder: (_, i) {
              final field = _appFields[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String?>(
                  initialValue: _mapping[field],
                  decoration: InputDecoration(
                    labelText: _fieldLabels[field],
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('— Not mapped —')),
                    ..._headers.map((h) => DropdownMenuItem<String?>(value: h, child: Text(h))),
                  ],
                  onChanged: (val) => setState(() => _mapping[field] = val),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_mapping['firstName'] == null ||
                    _mapping['lastName'] == null ||
                    _mapping['phone'] == null) {
                  _showError('Please map First Name, Last Name, and Phone at minimum.');
                  return;
                }
                _buildPreview();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Preview Import', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewStep() {
    final willImport = _preview.where((r) => r['skipReason'] == null).length;
    final willSkip = _preview.length - willImport;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.indigo.shade50,
          child: Text(
            '$willImport will be imported, $willSkip will be skipped.',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _preview.length,
            itemBuilder: (_, i) {
              final row = _preview[i];
              final skip = row['skipReason'] as String?;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: skip != null ? Colors.red.shade50 : Colors.green.shade50,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    skip != null ? Icons.cancel : Icons.check_circle,
                    color: skip != null ? Colors.red : Colors.green,
                    size: 20,
                  ),
                  title: Text('${row['firstName']} ${row['lastName']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(
                    skip ?? '${row['phone']}${(row['dateOfBirth'] as String?) != null ? ' • DOB: ${row['dateOfBirth']}' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: skip != null ? Colors.red.shade700 : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _importing ? null : () => setState(() => _step = 1),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _importing || willImport == 0 ? null : _confirmImport,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000080)),
                  child: _importing
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Import $willImport Client${willImport == 1 ? '' : 's'}',
                          style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoneStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text('$_importedCount client${_importedCount == 1 ? '' : 's'} imported successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000080)),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
