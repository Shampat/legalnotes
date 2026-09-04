import 'package:hive_flutter/hive_flutter.dart';
import '../../../shared/models/client.dart';
import '../../../shared/models/hearing.dart';
import '../../../shared/models/payment.dart';
import '../../../shared/models/document.dart';
import '../../../shared/models/communication_log.dart';
import '../../../shared/models/appointment.dart';

class HiveService {
  static const String clientsBoxName = 'clients';
  static const String hearingsBoxName = 'hearings';
  static const String paymentsBoxName = 'payments';
  static const String documentsBoxName = 'documents';
  static const String appointmentsBoxName = 'appointments';
  static const String communicationLogsBoxName = 'communication_logs';
  static const String settingsBoxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // FORCE register all adapters - ignore if already registered
    try { Hive.registerAdapter(ClientAdapter()); } catch (_) {}
    try { Hive.registerAdapter(OpposingPartyAdapter()); } catch (_) {}
    try { Hive.registerAdapter(HearingAdapter()); } catch (_) {}
    try { Hive.registerAdapter(PaymentAdapter()); } catch (_) {}
    try { Hive.registerAdapter(AppointmentAdapter()); } catch (_) {}
    try { Hive.registerAdapter(DocumentAdapter()); } catch (_) {}
    try { Hive.registerAdapter(CommunicationLogAdapter()); } catch (_) {}

    // Close any boxes opened without adapter
    try { await Hive.close(); } catch (_) {}

    await Hive.openBox<Client>(clientsBoxName);
    await Hive.openBox<Hearing>(hearingsBoxName);
    await Hive.openBox<Payment>(paymentsBoxName);
    await Hive.openBox<Document>(documentsBoxName);
    await Hive.openBox<Appointment>(appointmentsBoxName);
    await Hive.openBox<CommunicationLog>(communicationLogsBoxName);
    await Hive.openBox(settingsBoxName);

    print('HIVE INIT DONE - All adapters registered');
  }

  static Box<Client> get clientsBox => Hive.box<Client>(clientsBoxName);
  static Box<Hearing> get hearingsBox => Hive.box<Hearing>(hearingsBoxName);
  static Box<Payment> get paymentsBox => Hive.box<Payment>(paymentsBoxName);
  static Box<Document> get documentsBox => Hive.box<Document>(documentsBoxName);
  static Box<Appointment> get appointmentsBox => Hive.box<Appointment>(appointmentsBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
  static Box<CommunicationLog> get communicationLogsBox => Hive.box<CommunicationLog>(communicationLogsBoxName);
}
