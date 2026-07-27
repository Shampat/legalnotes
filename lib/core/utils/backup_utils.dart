import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import '../services/database/hive_service.dart';
import '../../shared/models/client.dart';
import '../../shared/models/hearing.dart';
import '../../shared/models/payment.dart';
import '../../shared/models/document.dart';
import '../../shared/models/communication_log.dart';

class BackupUtils {
  /// Export all data to a JSON file and share it
  static Future<String?> exportBackup() async {
    try {
      final clients = HiveService.clientsBox.values.map((c) => {
            'key': c.key,
            'firstName': c.firstName,
            'lastName': c.lastName,
            'phone': c.phone,
            'email': c.email,
            'address': c.address,
            'totalInvoiced': c.totalInvoiced,
            'invoiceTaxRate': c.invoiceTaxRate,
            'clientStatus': c.clientStatus,
            'matterDescription': c.matterDescription,
            'consultationDate': c.consultationDate?.toIso8601String(),
            'retainerSigned': c.retainerSigned,
            'nonEngagementLetterSent': c.nonEngagementLetterSent,
            'dateOfBirth': c.dateOfBirth,
            'companyName': c.companyName,
            'createdAt': c.createdAt.toIso8601String(),
          }).toList();

      final hearings = HiveService.hearingsBox.values.map((h) => {
            'key': h.key,
            'caseTitle': h.caseTitle,
            'clientKey': h.clientKey,
            'dateTime': h.dateTime.toIso8601String(),
            'court': h.court,
            'notes': h.notes,
            'opposingParty': h.opposingParty,
            'opposingPartiesList': h.opposingPartiesList
                ?.map((op) => {'name': op.name, 'phone': op.phone})
                .toList(),
          }).toList();

      final payments = HiveService.paymentsBox.values.map((p) => {
            'key': p.key,
            'clientKey': p.clientKey,
            'amount': p.amount,
            'description': p.description,
            'dueDate': p.dueDate.toIso8601String(),
            'paidDate': p.paidDate?.toIso8601String(),
            'taxApplicable': p.taxApplicable,
            'taxRate': p.taxRate,
            'modeOfPayment': p.modeOfPayment,
            'isRetainer': p.isRetainer,
          }).toList();

      final documents = HiveService.documentsBox.values.map((d) => {
            'key': d.key,
            'clientKey': d.clientKey,
            'title': d.title,
            'content': d.content,
            'fileName': d.fileName,
            'createdAt': d.createdAt.toIso8601String(),
            'updatedAt': d.updatedAt?.toIso8601String(),
          }).toList();

      final logs = HiveService.communicationLogsBox.values.map((l) => {
            'key': l.key,
            'clientKey': l.clientKey,
            'note': l.note,
            'channel': l.channel,
            'status': l.status,
            'createdAt': l.createdAt.toIso8601String(),
          }).toList();

      final settings = {
        'officeName': HiveService.settingsBox
            .get('officeName', defaultValue: 'Jolly Law Office'),
        'taxRate': HiveService.settingsBox.get('taxRate', defaultValue: 0.0),
      };

      final backup = {
        'version': 3,
        'exportedAt': DateTime.now().toIso8601String(),
        'clients': clients,
        'hearings': hearings,
        'payments': payments,
        'documents': documents,
        'communicationLogs': logs,
        'settings': settings,
      };

      final json = const JsonEncoder.withIndent('  ').convert(backup);
      final date = DateTime.now().toString().split(' ')[0];
      final fileName = 'legalnotes_backup_$date.json';
      final bytes = utf8.encode(json);

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: fileName,
        bytes: bytes,
      );

      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          text: 'LegalNotes Backup - $date',
          subject: 'LegalNotes Backup',
        ),
      );

      return savedPath ?? tempFile.path;
    } catch (e) {
      return null;
    }
  }

  /// Export just the client contact list as a portable CSV file
  /// (name, phone, email, DOB, matter, etc.) — for taking data to another
  /// system, or as a simple human-readable record. Does NOT include
  /// hearings, payments, or communication history (see exportBackup for
  /// the full, app-native backup).
  static Future<String?> exportClientsCsv() async {
    try {
      final clients = HiveService.clientsBox.values.toList();
      final rows = <List<dynamic>>[
        [
          'First Name',
          'Last Name',
          'Phone',
          'Email',
          'Address',
          'Date of Birth',
          'Company Name',
          'Matter Description',
        ],
        ...clients.map((c) => [
              c.firstName,
              c.lastName,
              c.phone,
              c.email,
              c.address,
              c.dateOfBirth ?? '',
              c.companyName ?? '',
              c.matterDescription,
            ]),
      ];

      final csvString = const ListToCsvConverter().convert(rows);
      final date = DateTime.now().toString().split(' ')[0];
      final fileName = 'legalnotes_clients_$date.csv';
      final bytes = utf8.encode(csvString);

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Client List (CSV)',
        fileName: fileName,
        bytes: bytes,
      );

      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
          text: 'Client list export - $date',
          subject: 'LegalNotes Client List',
        ),
      );

      return savedPath ?? tempFile.path;
    } catch (e) {
      return null;
    }
  }

  /// Import (merge) data from a JSON backup file.
  /// This NEVER deletes or overwrites existing data — it only adds
  /// records from the backup that don't already exist.
  static Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return false;

      final filePath = result.files.first.path;
      if (filePath == null) return false;

      final json = await File(filePath).readAsString();
      final backup = jsonDecode(json) as Map<String, dynamic>;

      // Restore settings (safe to overwrite — single values, not records)
      if (backup['settings'] != null) {
        final settings = backup['settings'] as Map<String, dynamic>;
        if (HiveService.settingsBox.get('officeName') == null) {
          await HiveService.settingsBox.put(
              'officeName', settings['officeName'] ?? 'Jolly Law Office');
        }
        if (HiveService.settingsBox.get('taxRate') == null) {
          await HiveService.settingsBox.put(
              'taxRate', (settings['taxRate'] as num?)?.toDouble() ?? 0.0);
        }
      }

      // --- Merge clients ---
      // Map: backup's old key -> actual key used in this box (existing or newly added)
      final Map<int, int> clientKeyMap = {};
      final existingClients = HiveService.clientsBox.values.toList();

      String normalizedPhone(String p) => p.replaceAll(RegExp(r'[^\d]'), '');
      String normalizedName(String f, String l) =>
          '$f $l'.trim().toLowerCase();

      for (final c in (backup['clients'] as List)) {
        final oldKey = c['key'] as int;
        String firstName = c['firstName'] as String? ?? '';
        String lastName = c['lastName'] as String? ?? '';
        if (firstName.isEmpty && lastName.isEmpty && c['name'] != null) {
          final parts = (c['name'] as String).split(' ');
          firstName = parts.first;
          lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        }
        final phone = c['phone'] as String? ?? '';

        // Look for an existing matching client (by name or phone)
        Client? match;
        for (final ec in existingClients) {
          final samePhone = phone.isNotEmpty &&
              ec.phone.isNotEmpty &&
              normalizedPhone(ec.phone) == normalizedPhone(phone);
          final sameName = normalizedName(firstName, lastName) ==
              normalizedName(ec.firstName, ec.lastName);
          if (samePhone || sameName) {
            match = ec;
            break;
          }
        }

        if (match != null) {
          // Already exists — keep current data, just map the key
          clientKeyMap[oldKey] = match.key as int;
        } else {
          // New client — add fresh, let Hive assign a safe new key
          final client = Client(
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            email: c['email'] ?? '',
            address: c['address'] ?? '',
            totalInvoiced: (c['totalInvoiced'] as num?)?.toDouble() ?? 0.0,
            invoiceTaxRate: (c['invoiceTaxRate'] as num?)?.toDouble() ?? 0.0,
            clientStatus: c['clientStatus'] as String? ?? 'prospective',
            matterDescription: c['matterDescription'] as String? ?? '',
            consultationDate: c['consultationDate'] != null
                ? DateTime.parse(c['consultationDate'])
                : null,
            retainerSigned: c['retainerSigned'] as bool? ?? false,
            nonEngagementLetterSent:
                c['nonEngagementLetterSent'] as bool? ?? false,
            dateOfBirth: c['dateOfBirth'] as String?,
            companyName: c['companyName'] as String?,
            createdAt: c['createdAt'] != null
                ? DateTime.parse(c['createdAt'])
                : DateTime.now(),
          );
          final newKey = await HiveService.clientsBox.add(client);
          clientKeyMap[oldKey] = newKey;
        }
      }

      // --- Merge hearings (add-only, remap clientKey) ---
      for (final h in (backup['hearings'] as List)) {
        final oldClientKey = h['clientKey'] as int;
        final newClientKey = clientKeyMap[oldClientKey];
        if (newClientKey == null) continue; // orphaned reference, skip

        List<OpposingParty>? opposingPartiesList;
        if (h['opposingPartiesList'] != null) {
          opposingPartiesList = (h['opposingPartiesList'] as List)
              .map((op) => OpposingParty(
                    name: op['name'] as String,
                    phone: op['phone'] as String?,
                  ))
              .toList();
        }
        final hearing = Hearing(
          caseTitle: h['caseTitle'],
          clientKey: newClientKey,
          dateTime: DateTime.parse(h['dateTime']),
          court: h['court'] ?? '',
          notes: h['notes'] ?? '',
          opposingParty: h['opposingParty'] ?? '',
          opposingPartiesList: opposingPartiesList,
        );
        await HiveService.hearingsBox.add(hearing);
      }

      // --- Merge payments (add-only, remap clientKey) ---
      for (final p in (backup['payments'] as List)) {
        final oldClientKey = p['clientKey'] as int;
        final newClientKey = clientKeyMap[oldClientKey];
        if (newClientKey == null) continue;

        final payment = Payment(
          clientKey: newClientKey,
          amount: (p['amount'] as num).toDouble(),
          description: p['description'] ?? '',
          dueDate: DateTime.parse(p['dueDate']),
          paidDate: p['paidDate'] != null
              ? DateTime.parse(p['paidDate'])
              : null,
          taxApplicable: p['taxApplicable'] as bool? ?? false,
          taxRate: (p['taxRate'] as num?)?.toDouble() ?? 0.0,
          modeOfPayment: p['modeOfPayment'] as String? ?? 'bank_transfer',
          isRetainer: p['isRetainer'] as bool? ?? false,
        );
        await HiveService.paymentsBox.add(payment);
      }

      // --- Merge documents (add-only, remap clientKey) ---
      for (final d in (backup['documents'] as List)) {
        final oldClientKey = int.tryParse(d['clientKey'].toString());
        if (oldClientKey == null) continue;
        final newClientKey = clientKeyMap[oldClientKey];
        if (newClientKey == null) continue;

        final doc = Document(
          clientKey: newClientKey.toString(),
          title: d['title'],
          content: d['content'] ?? '',
          fileName: d['fileName'],
          createdAt: DateTime.parse(d['createdAt']),
        );
        await HiveService.documentsBox.add(doc);
      }

      // --- Merge communication logs (add-only, remap clientKey) ---
      for (final l in (backup['communicationLogs'] as List)) {
        final oldClientKey = l['clientKey'] as int;
        final newClientKey = clientKeyMap[oldClientKey];
        if (newClientKey == null) continue;

        final log = CommunicationLog(
          clientKey: newClientKey,
          note: l['note'],
          channel: l['channel'],
          status: l['status'] ?? 'connected',
          createdAt: DateTime.parse(l['createdAt']),
        );
        await HiveService.communicationLogsBox.add(log);
      }

      return true;
    } catch (e, stack) {
      // ignore: avoid_print
      print('IMPORT ERROR: $e');
      // ignore: avoid_print
      print('STACK: $stack');
      return false;
    }
  }
}
