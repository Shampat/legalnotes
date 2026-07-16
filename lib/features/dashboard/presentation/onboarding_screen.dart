import 'package:flutter/material.dart';
import '../../../core/services/database/hive_service.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Color(0xFF000080)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.gavel, size: 60, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  "Welcome to LegalNotes",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your professional law office management tool",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 40),
                _infoCard(
                  icon: Icons.person_add,
                  title: "New to the app?",
                  body: "Start by adding clients as they walk in. Every new client is recorded as Prospective until a retainer is signed.",
                ),
                const SizedBox(height: 16),
                _infoCard(
                  icon: Icons.folder_open,
                  title: "Migrating from physical files or spreadsheets?",
                  body: "You can manually add past clients or import them from a CSV file. Go to Clients to get started.",
                ),
                const SizedBox(height: 16),
                _infoCard(
                  icon: Icons.warning_amber,
                  title: "Important — Conflict Check",
                  body: "Conflict checking only works against clients already in this app. If you have years of physical records not yet imported, those will NOT be checked automatically. Import past clients to enable full conflict checking.",
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF000080),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      HiveService.settingsBox.put("onboardingDone", true);
                      Navigator.pushReplacementNamed(context, "/home");
                    },
                    child: const Text(
                      "Get Started",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
