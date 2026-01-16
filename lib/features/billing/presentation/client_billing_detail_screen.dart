import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/client.dart';
import '../../../shared/models/payment.dart';

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

  void _addPartialPayment() async {
    final amountCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    DateTime? paidDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Partial Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: descriptionCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 6),
            ListTile(
              title: Text('Paid Date: ${paidDate?.toLocal().toString().split(' ')[0] ?? 'Select Paid Date'}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  paidDate = date;
                  setState(() {}); // Update dialog
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0.0;
              final payment = Payment(
                clientKey: widget.clientKey,
                amount: amount,
                description: descriptionCtrl.text.trim(),
                paidDate: paidDate,
                dueDate: DateTime.now(), // Required field
              );
              paymentsBox.add(payment);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Add Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCSV() async {
    final payments = paymentsBox.values.where((p) => p.clientKey == widget.clientKey).toList();

    List<List<dynamic>> csvData = [
      ['Date', 'Amount', 'Description', 'Status'],
    ];

    for (var p in payments) {
      csvData.add([
        p.paidDate?.toLocal().toString().split(' ')[0] ?? 'N/A',
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: paymentsBox.listenable(),
      builder: (_, Box<Payment> paymentsBox, __) {
        final payments = paymentsBox.values.where((p) => p.clientKey == widget.clientKey).toList()
          ..sort((a, b) => (b.paidDate ?? b.dueDate).compareTo(a.paidDate ?? a.dueDate));

        final totalPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
        final balanceDue = client.totalInvoiced - totalPaid;

        return Scaffold(
          appBar: AppBar(
            title: Text('${client.name} - Billing'),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _exportToCSV,
                tooltip: 'Export to CSV',
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _editTotalInvoiced,
                tooltip: 'Edit Total Invoiced',
              ),
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
                    Text('Balance Due: \$${balanceDue.toStringAsFixed(2)}', 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: balanceDue > 0 ? Colors.red : Colors.green)),
                  ],
                ),
              ),
              Expanded(
                child: payments.isEmpty
                    ? const Center(child: Text('No payments recorded\nTap + to add partial payment'))
                    : ListView.builder(
                        itemCount: payments.length,
                        itemBuilder: (_, i) {
                          final p = payments[i];
                          return Dismissible(
                            key: Key(p.key.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Payment?'),
                                  content: Text('Delete \$${p.amount.toStringAsFixed(2)}?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Yes'),
                                    ),
                                  ],
                                ),
                              ) ?? false;
                            },
                            onDismissed: (direction) {
                              p.delete();
                              setState(() {});
                            },
                            child: ListTile(
                              title: Text(p.description.isEmpty ? 'Payment' : p.description),
                              subtitle: Text('Amount: \$${p.amount.toStringAsFixed(2)}\nPaid Date: ${p.paidDate?.toLocal().toString().split(' ')[0] ?? 'Not Paid'}'),
                              trailing: const Icon(Icons.check_circle, color: Colors.green),
                              onTap: () async {
                                // Edit payment
                                final amountCtrl = TextEditingController(text: p.amount.toStringAsFixed(2));
                                final descriptionCtrl = TextEditingController(text: p.description);
                                DateTime? editPaidDate = p.paidDate;
                                await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Edit Payment'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: amountCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(labelText: 'Amount'),
                                        ),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: descriptionCtrl,
                                          decoration: const InputDecoration(labelText: 'Description'),
                                        ),
                                        const SizedBox(height: 6),
                                        ListTile(
                                          title: Text('Paid Date: ${editPaidDate?.toLocal().toString().split(' ')[0] ?? 'Select Paid Date'}'),
                                          trailing: const Icon(Icons.calendar_today),
                                          onTap: () async {
                                            final date = await showDatePicker(
                                              context: context,
                                              initialDate: editPaidDate ?? DateTime.now(),
                                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                              lastDate: DateTime(2030),
                                            );
                                            if (date != null) {
                                              editPaidDate = date;
                                              setState(() {});
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                      ElevatedButton(
                                        onPressed: () {
                                          p.amount = double.tryParse(amountCtrl.text) ?? p.amount;
                                          p.description = descriptionCtrl.text.trim();
                                          p.paidDate = editPaidDate;
                                          p.save();
                                          Navigator.pop(context);
                                          setState(() {});
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addPartialPayment,
            child: const Icon(Icons.add),
            tooltip: 'Add Partial Payment',
          ),
        );
      },
    );
  }
}
