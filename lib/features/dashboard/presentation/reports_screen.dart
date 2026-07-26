import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/client.dart';
import '../../../shared/models/hearing.dart';
import '../../conflict_check/domain/conflict_check_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final clients = HiveService.clientsBox.values.toList();
    final hearings = HiveService.hearingsBox.values.toList();
    final payments = HiveService.paymentsBox.values.toList();

    // Billing totals (tax-inclusive throughout for consistency)
    double totalInvoicedWithTax = 0;
    double totalPaid = 0;
    double totalTaxCollected = 0;
    for (final c in clients) {
      final clientPayments = payments.where((p) => p.clientKey == c.key).toList();
      final paid = clientPayments.fold(0.0, (sum, p) => sum + p.totalAmount);
      final clientInvoiceTaxAmount = c.totalInvoiced * (c.invoiceTaxRate / 100);
      final clientInvoicedWithTax = c.totalInvoiced + clientInvoiceTaxAmount;
      final clientTaxCollected = clientInvoicedWithTax > 0
          ? (clientInvoiceTaxAmount * (paid / clientInvoicedWithTax))
              .clamp(0.0, clientInvoiceTaxAmount)
          : 0.0;
      totalInvoicedWithTax += clientInvoicedWithTax;
      totalPaid += paid;
      totalTaxCollected += clientTaxCollected;
    }
    final totalOutstanding = totalInvoicedWithTax - totalPaid;

    // Hearing stats
    final upcomingHearings =
        hearings.where((h) => h.dateTime.isAfter(now)).toList();
    final overdueHearings = hearings
        .where((h) => h.dateTime.isBefore(now) &&
            h.dateTime.isAfter(now.subtract(const Duration(days: 30))))
        .toList();

    // Conflict count
    int conflictCount = 0;
    for (final h in hearings) {
      if (h.opposingParty.trim().isEmpty) continue;
      conflictCount += ConflictCheckService
          .checkOpposingPartyConflict(h.opposingParty)
          .length;
    }

    // Client activity
    final clientActivity = clients.map((c) {
      final clientHearings = hearings
          .where((h) => h.clientKey == c.key)
          .toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      final lastHearing =
          clientHearings.isNotEmpty ? clientHearings.first : null;
      final paid = payments
          .where((p) => p.clientKey == c.key)
          .fold(0.0, (sum, p) => sum + p.amount);
      final balance = c.totalInvoiced - paid;
      return {
        'client': c,
        'lastHearing': lastHearing,
        'balance': balance,
      };
    }).toList()
      ..sort((a, b) =>
          (b['balance'] as double).compareTo(a['balance'] as double));

    void shareReport() {
      final buf = StringBuffer();
      buf.writeln('=== LEGAL OFFICE REPORT ===');
      buf.writeln(
          'Generated: ${DateFormat('dd MMM yyyy').format(now)}\n');

      buf.writeln('--- BILLING SUMMARY ---');
      buf.writeln(
          'Total Invoiced (incl. tax): \$${totalInvoicedWithTax.toStringAsFixed(2)}');
      buf.writeln('Total Collected: \$${totalPaid.toStringAsFixed(2)}');
      buf.writeln(
          'Outstanding: \$${totalOutstanding.toStringAsFixed(2)}\n');

      buf.writeln('--- HEARINGS ---');
      buf.writeln('Total: ${hearings.length}');
      buf.writeln('Upcoming: ${upcomingHearings.length}');
      buf.writeln('Recent (30d): ${overdueHearings.length}\n');

      buf.writeln('--- CONFLICTS ---');
      buf.writeln('Potential Conflicts: $conflictCount\n');

      buf.writeln('--- CLIENT ACTIVITY ---');
      for (final ca in clientActivity) {
        final c = ca['client'] as Client;
        final lh = ca['lastHearing'] as Hearing?;
        final bal = ca['balance'] as double;
        buf.writeln(c.fullName);
        buf.writeln(
            '  Last Hearing: ${lh != null ? DateFormat('dd MMM yyyy').format(lh.dateTime) : 'None'}');
        buf.writeln(
            '  Balance Due: \$${bal.toStringAsFixed(2)}');
      }

      SharePlus.instance.share(ShareParams(text: buf.toString(), subject: 'Legal Office Report'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Office Reports',
            style: TextStyle(color: Colors.white)),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Share Report',
            onPressed: shareReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Text(
              'Generated: ${DateFormat('dd MMM yyyy • hh:mm a').format(now)}',
              style:
                  const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Billing Summary
            _sectionHeader('💰 Billing Summary'),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _billingRow('Total Invoiced (incl. tax)',
                        '\$${totalInvoicedWithTax.toStringAsFixed(2)}',
                        Colors.indigo),
                    const Divider(),
                    _billingRow('Total Collected',
                        '\$${totalPaid.toStringAsFixed(2)}',
                        Colors.green),
                    const Divider(),
                    _billingRow('Tax Collected',
                        '\$${totalTaxCollected.toStringAsFixed(2)}',
                        Colors.orange),
                    const Divider(),
                    _billingRow(
                        'Outstanding',
                        '\$${totalOutstanding.toStringAsFixed(2)}',
                        totalOutstanding > 0
                            ? Colors.red
                            : Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Hearing Stats
            _sectionHeader('⚖️ Hearing Statistics'),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: [
                    _statTile('Total', hearings.length,
                        Colors.indigo),
                    _vDivider(),
                    _statTile('Upcoming',
                        upcomingHearings.length, Colors.orange),
                    _vDivider(),
                    _statTile(
                        'Recent (30d)',
                        overdueHearings.length,
                        Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Conflicts
            _sectionHeader('⚠️ Conflict Summary'),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: conflictCount > 0
                      ? Colors.red.shade200
                      : Colors.green.shade200,
                  width: 1,
                ),
              ),
              elevation: 2,
              child: ListTile(
                leading: Icon(
                  conflictCount > 0
                      ? Icons.warning
                      : Icons.verified,
                  color: conflictCount > 0
                      ? Colors.red
                      : Colors.green,
                  size: 32,
                ),
                title: Text(
                  conflictCount > 0
                      ? '$conflictCount Potential Conflict${conflictCount > 1 ? 's' : ''} Detected'
                      : 'No Conflicts Detected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: conflictCount > 0
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                subtitle: Text(
                  '${clients.length} clients · ${hearings.length} hearings checked',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Client Activity
            _sectionHeader('👤 Client Activity'),
            ...clientActivity.map((ca) {
              final c = ca['client'] as Client;
              final lh = ca['lastHearing'] as Hearing?;
              final bal = ca['balance'] as double;
              final hasBalance = bal > 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: hasBalance
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: hasBalance
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    child: Text(
                      c.fullName.isNotEmpty
                          ? c.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white),
                    ),
                  ),
                  title: Text(c.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Last Hearing: ${lh != null ? DateFormat('dd MMM yyyy').format(lh.dateTime) : 'None'}\n'
                    'Balance Due: \$${bal.toStringAsFixed(2)}',
                  ),
                  isThreeLine: true,
                  trailing: Icon(
                    hasBalance
                        ? Icons.warning_amber
                        : Icons.check_circle,
                    color:
                        hasBalance ? Colors.red : Colors.green,
                  ),
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF000080),
        ),
      ),
    );
  }

  Widget _billingRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15, color: Colors.black87)),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _statTile(String label, int value, Color color) {
    return Column(
      children: [
        Text('$value',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color)),
        const SizedBox(height: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _vDivider() {
    return Container(
        height: 40, width: 1, color: Colors.grey.shade200);
  }
}
