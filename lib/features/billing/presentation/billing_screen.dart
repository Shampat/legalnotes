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
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService.clientsBox.listenable(),
      builder: (_, Box<Client> clientBox, __) => ValueListenableBuilder(
        valueListenable: HiveService.paymentsBox.listenable(),
        builder: (_, Box<Payment> paymentsBox, __) {
          final allClients = clientBox.values.toList();
          final filteredClients = _searchQuery.isEmpty
              ? allClients
              : allClients.where((client) {
                  final query = _searchQuery.toLowerCase();
                  return client.name.toLowerCase().contains(query) ||
                         client.phone.toLowerCase().contains(query);
                }).toList();

          return Scaffold(
            appBar: AppBar(
              title: const Text('Billing'),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search clients by name or phone...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                Expanded(
                  child: filteredClients.isEmpty
                      ? const Center(child: Text('No clients found'))
                      : ListView.builder(
                          itemCount: filteredClients.length,
                          itemBuilder: (_, i) {
                            final client = filteredClients[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'Total Invoiced: \$${client.totalInvoiced.toStringAsFixed(2)}',
                                ),
                                trailing: Icon(Icons.arrow_forward),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClientBillingDetailScreen(clientKey: client.key as int),
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
}
