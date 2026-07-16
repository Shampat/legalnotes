import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/client.dart';
import '../../../shared/models/payment.dart';
import 'client_billing_detail_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService.clientsBox.listenable(),
      builder: (_, Box<Client> clientBox, __) =>
          ValueListenableBuilder(
        valueListenable: HiveService.paymentsBox.listenable(),
        builder: (_, Box<Payment> paymentsBox, __) {
          final query = _searchCtrl.text.trim().toLowerCase();
          final allClients = clientBox.values.toList();

          final filtered = query.isEmpty
              ? allClients
              : allClients.where((c) =>
                  c.name.toLowerCase().contains(query) ||
                  c.phone.toLowerCase().contains(query)).toList();

          // Summary totals
          double totalInvoiced = 0;
          double totalPaid = 0;
          for (final c in allClients) {
            final paid = paymentsBox.values
                .where((p) => p.clientKey == c.key)
                .fold(0.0, (sum, p) => sum + p.amount);
            totalInvoiced += c.totalInvoiced;
            totalPaid += paid;
          }
          final totalOutstanding = totalInvoiced - totalPaid;

          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Billing',
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
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
                // Summary banner
                Container(
                  width: double.infinity,
                  color: Colors.indigo.shade50,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _summaryTile("Invoiced", '\$${totalInvoiced.toStringAsFixed(2)}', Colors.indigo)),
                      _vDivider(),
                      Expanded(child: _summaryTile("Collected", '\$${totalPaid.toStringAsFixed(2)}', Colors.green)),
                      _vDivider(),
                      Expanded(child: _summaryTile("Outstanding", '\$${totalOutstanding.toStringAsFixed(2)}', totalOutstanding > 0 ? Colors.red : Colors.green)),
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search clients by name or phone…',
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.indigo),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.indigo.shade50,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Client list
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No clients found'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final client = filtered[i];
                            final paid = paymentsBox.values
                                .where((p) => p.clientKey == client.key)
                                .fold(0.0, (sum, p) => sum + p.amount);
                            final balance =
                                client.totalInvoiced - paid;
                            final hasBalance = balance > 0;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: hasBalance
                                      ? Colors.red.shade200
                                      : Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              elevation: 2,
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: hasBalance
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                  child: Text(
                                    client.fullName.isNotEmpty
                                        ? client.fullName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  client.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        _billingChip(
                                            'Invoiced',
                                            '\$${client.totalInvoiced.toStringAsFixed(2)}',
                                            Colors.indigo),
                                        _billingChip(
                                            'Paid',
                                            '\$${paid.toStringAsFixed(2)}',
                                            Colors.green),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Balance Due: \$${balance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: hasBalance
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  hasBalance
                                      ? Icons.warning_amber
                                      : Icons.check_circle,
                                  color: hasBalance
                                      ? Colors.red
                                      : Colors.green,
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ClientBillingDetailScreen(
                                      clientKey: client.key as int,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _vDivider() {
    return Container(height: 36, width: 1, color: Colors.indigo.shade100);
  }

  Widget _billingChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
