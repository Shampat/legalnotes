import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'clients': clients,
        'hearings': hearings,
        'payments': payments,
        'documents': documents,
        'communicationLogs': logs,
        'settings': settings,
      };

      final json = const JsonEncoder.withIndent('  ').convert(backup);
      final dir = await getTemporaryDirectory();
      final date = DateTime.now().toString().split(' ')[0];
      final file = File('${dir.path}/legalnotes_backup_$date.json');
      await file.writeAsString(json);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'LegalNotes Backup - $date',
          subject: 'LegalNotes Backup',
        ),
      );

      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Import data from a JSON backup file
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

      // Restore settings
      if (backup['settings'] != null) {
        final settings = backup['settings'] as Map<String, dynamic>;
        await HiveService.settingsBox.put(
            'officeName', settings['officeName'] ?? 'Jolly Law Office');
        await HiveService.settingsBox
            .put('taxRate', (settings['taxRate'] as num?)?.toDouble() ?? 0.0);
      }

      // Restore clients
      await HiveService.clientsBox.clear();
      for (final c in (backup['clients'] as List)) {
        String firstName = c['firstName'] as String? ?? '';
        String lastName = c['lastName'] as String? ?? '';
        if (firstName.isEmpty && lastName.isEmpty && c['name'] != null) {
          final parts = (c['name'] as String).split(' ');
          firstName = parts.first;
          lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        }
        final client = Client(
          firstName: firstName,
          lastName: lastName,
          phone: c['phone'] ?? '',
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
        await HiveService.clientsBox.put(c['key'], client);
      }

      // Restore hearings
      await HiveService.hearingsBox.clear();
      for (final h in (backup['hearings'] as List)) {
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
          clientKey: h['clientKey'],
          dateTime: DateTime.parse(h['dateTime']),
          court: h['court'] ?? '',
          notes: h['notes'] ?? '',
          opposingParty: h['opposingParty'] ?? '',
          opposingPartiesList: opposingPartiesList,
        );
        await HiveService.hearingsBox.put(h['key'], hearing);
      }

      // Restore payments
      await HiveService.paymentsBox.clear();
      for (final p in (backup['payments'] as List)) {
        final payment = Payment(
          clientKey: p['clientKey'],
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
        await HiveService.paymentsBox.put(p['key'], payment);
      }

      // Restore documents
      await HiveService.documentsBox.clear();
      for (final d in (backup['documents'] as List)) {
        final doc = Document(
          clientKey: d['clientKey'],
          title: d['title'],
          content: d['content'] ?? '',
          fileName: d['fileName'],
          createdAt: DateTime.parse(d['createdAt']),
        );
        await HiveService.documentsBox.put(d['key'], doc);
      }

      // Restore communication logs
      await HiveService.communicationLogsBox.clear();
      for (final l in (backup['communicationLogs'] as List)) {
        final log = CommunicationLog(
          clientKey: l['clientKey'],
          note: l['note'],
          channel: l['channel'],
          status: l['status'] ?? 'connected',
          createdAt: DateTime.parse(l['createdAt']),
        );
        await HiveService.communicationLogsBox.put(l['key'], log);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
