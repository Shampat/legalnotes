import 'package:flutter/material.dart';
import 'app/app_shell.dart';
import 'core/services/database/hive_service.dart';
import 'features/dashboard/presentation/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const LegalNotesApp());
}

class LegalNotesApp extends StatelessWidget {
  const LegalNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingDone = HiveService.settingsBox
        .get('onboardingDone', defaultValue: false) as bool;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Legal Notes',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      initialRoute: onboardingDone ? '/home' : '/onboarding',
      routes: {
        '/home': (_) => const AppShell(),
        '/onboarding': (_) => const OnboardingScreen(),
      },
    );
  }
}
