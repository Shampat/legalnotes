import 'package:hive_flutter/hive_flutter.dart';
import '../../../shared/models/client.dart';
import '../../../shared/models/hearing.dart';
import '../../../shared/models/payment.dart';
import '../../../shared/models/document.dart';

class HiveService {
  static const String clientsBoxName = 'clients';
  static const String hearingsBoxName = 'hearings';
  static const String paymentsBoxName = 'payments';
  static const String documentsBoxName = 'documents';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(ClientAdapter());
    Hive.registerAdapter(HearingAdapter());
    Hive.registerAdapter(PaymentAdapter());
    Hive.registerAdapter(DocumentAdapter());

    await Future.wait([
      Hive.openBox<Client>(clientsBoxName),
      Hive.openBox<Hearing>(hearingsBoxName),
      Hive.openBox<Payment>(paymentsBoxName),
      Hive.openBox<Document>(documentsBoxName),
    ]);
  }

  static Box<Client> get clientsBox => Hive.box<Client>(clientsBoxName);
  static Box<Hearing> get hearingsBox => Hive.box<Hearing>(hearingsBoxName);
  static Box<Payment> get paymentsBox => Hive.box<Payment>(paymentsBoxName);
  static Box<Document> get documentsBox => Hive.box<Document>(documentsBoxName);
}
