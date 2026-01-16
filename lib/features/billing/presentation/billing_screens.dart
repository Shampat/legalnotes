import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/client.dart';
import '../../../shared/models/payment.dart';

// ---------------------- Billing Screen ----------------------
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
            appBar: AppBar(title: const Text('Billing')),
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
                            final clientPayments = paymentsBox.values
                                .where((p) => p.clientKey == client.key)
                                .toList();
                            final totalPaid = clientPayments.fold(0.0, (sum, p) => sum + p.amount);
                            final balanceDue = client.totalInvoiced - totalPaid;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'Total Invoiced: \$${client.totalInvoiced.toStringAsFixed(2)}\n'
                                  'Total Paid: \$${totalPaid.toStringAsFixed(2)}\n'
                                  'Balance Due: \$${balanceDue.toStringAsFixed(2)}',
                                ),
                                trailing: Icon(
                                  balanceDue > 0 ? Icons.warning_amber : Icons.check_circle,
                                  color: balanceDue > 0 ? Colors.red : Colors.green,
                                ),
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

// ---------------------- Client Billing Detail Screen ----------------------
class ClientBillingDetailScreen extends StatefulWidget {
  final int clientKey;
  const ClientBillingDetailScreen({super.key, required this.clientKey});

  @override
  State<ClientBillingDetailScreen> createState() => _ClientBillingDetailScreenState();
}

class _ClientBillingDetailScreenState extends State<ClientBillingDetailScreen> {
  late Client client;
  late Box<Payment> paymentsBox;

  @override
  void initState() {
    super.initState();
    client = HiveService.clientsBox.get(widget.clientKey)!;
    paymentsBox = HiveService.paymentsBox;
  }

  void _editTotalInvoiced() async {
    final controller = TextEditingController(text: client.totalInvoiced.toStringAsFixed(2));
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Total Invoiced'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Total Invoiced Amount (\$)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              client.totalInvoiced = amount;
              client.save();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCSV() async {
    final payments = paymentsBox.values.where((p) => p.clientKey == widget.clientKey).toList();
    List<List<dynamic>> csvData = [['Date', 'Amount', 'Description', 'Status']];
    for (var p in payments) {
      csvData.add([
        p.paidDate?.toString() ?? 'N/A',
        p.amount.toStringAsFixed(2),
        p.description,
        p.paidDate != null ? 'Paid' : 'Pending',
      ]);
    }
    final csvString = const ListToCsvConverter().convert(csvData);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/billing_${client.name.replaceAll(' ', '_')}.csv';
    final file = File(path);
    await file.writeAsString(csvString);
    await Share.shareXFiles([XFile(path)], text: 'Billing history for ${client.name}');
  }

  void _addOrEditPayment([Payment? payment]) async {
    final isEdit = payment != null;
    final amountController = TextEditingController(text: isEdit ? payment.amount.toStringAsFixed(2) : '');
    final descriptionController = TextEditingController(text: isEdit ? payment.description : '');
    DateTime? paidDate = isEdit ? payment.paidDate : null;
    DateTime dueDate = isEdit ? payment.dueDate : DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Payment' : 'Add Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
              ListTile(
                title: Text('Paid Date: ${paidDate != null ? paidDate.toLocal().toString().split(' ')[0] : 'Not Paid'}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: paidDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => paidDate = picked);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (isEdit) {
                payment!
                  ..amount = amount
                  ..description = descriptionController.text
                  ..paidDate = paidDate
                  ..save();
              } else {
                final newPayment = Payment(amount: amount, description: descriptionController.text, clientKey: widget.clientKey, dueDate: dueDate, paidDate: paidDate);
                paymentsBox.add(newPayment);
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _deletePayment(Payment payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment?'),
        content: Text('Delete \$${payment.amount.toStringAsFixed(2)} payment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Yes')),
        ],
      ),
    );
    if (confirm == true) {
      payment.delete();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: paymentsBox.listenable(),
      builder: (_, Box<Payment> box, __) {
        final payments = box.values.where((p) => p.clientKey == widget.clientKey).toList()
          ..sort((a, b) => (b.paidDate ?? b.dueDate).compareTo(a.paidDate ?? a.dueDate));
        final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
        final balanceDue = client.totalInvoiced - totalPaid;

        return Scaffold(
          appBar: AppBar(
            title: Text('${client.name} - Billing'),
            actions: [
              IconButton(icon: const Icon(Icons.download), onPressed: _exportToCSV),
              IconButton(icon: const Icon(Icons.edit), onPressed: _editTotalInvoiced),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.teal[50],
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Total Invoiced: \$${client.totalInvoiced.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Total Paid: \$${totalPaid.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.green)),
                    const SizedBox(height: 8),
                    Text('Balance Due: \$${balanceDue.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: balanceDue > 0 ? Colors.red : Colors.green)),
                  ],
                ),
              ),
              Expanded(
                child: payments.isEmpty
                    ? const Center(child: Text('No payments recorded\nTap + to add a payment'))
                    : ListView.builder(
                        itemCount: payments.length,
                        itemBuilder: (_, i) {
                          final p = payments[i];
                          return Dismissible(
                            key: Key(p.key.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                            confirmDismiss: (_) async => await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Payment?'),
                                content: Text('Delete \$${p.amount.toStringAsFixed(2)}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                                  ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Yes')),
                                ],
                              ),
                            ) ?? false,
                            onDismissed: (_) => p.delete(),
                            child: ListTile(
                              title: Text(p.description.isEmpty ? 'Payment' : p.description),
                              subtitle: Text('Amount: \$${p.amount.toStringAsFixed(2)}\nReceived: ${p.paidDate?.toLocal().toString().split(' ')[0] ?? 'Not Paid'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _addOrEditPayment(p)),
                                  const Icon(Icons.check_circle, color: Colors.green),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addOrEditPayment(),
            child: const Icon(Icons.add),
            tooltip: 'Add Payment',
          ),
        );
      },
    );
  }
}
