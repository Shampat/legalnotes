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
  State<ClientBillingDetailScreen> createState() =>
      _ClientBillingDetailScreenState();
}

class _ClientBillingDetailScreenState
    extends State<ClientBillingDetailScreen> {
  late Client client;
  late Box<Payment> paymentsBox;

  @override
  void initState() {
    super.initState();
    client = HiveService.clientsBox.get(widget.clientKey)!;
    paymentsBox = HiveService.paymentsBox;
  }

  void _editTotalInvoiced() async {
    final amountCtrl = TextEditingController(
        text: client.totalInvoiced > 0
            ? client.totalInvoiced.toStringAsFixed(2)
            : '');
    final taxRateCtrl = TextEditingController(
        text: client.invoiceTaxRate > 0
            ? client.invoiceTaxRate.toString()
            : '');

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Invoice'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Amount',
                      hintText: '0.00',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: taxRateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tax % (leave empty if no tax)',
                      hintText: 'e.g. 13',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  if ((double.tryParse(taxRateCtrl.text) ?? 0) > 0 &&
                      (double.tryParse(amountCtrl.text) ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _summaryRow('Amount',
                                '\$${(double.tryParse(amountCtrl.text) ?? 0).toStringAsFixed(2)}',
                                Colors.black87),
                            const SizedBox(height: 4),
                            _summaryRow(
                                'Tax (${taxRateCtrl.text}%)',
                                '\$${((double.tryParse(amountCtrl.text) ?? 0) * (double.tryParse(taxRateCtrl.text) ?? 0) / 100).toStringAsFixed(2)}',
                                Colors.orange.shade700),
                            const Divider(height: 12),
                            _summaryRow(
                                'Total',
                                '\$${((double.tryParse(amountCtrl.text) ?? 0) * (1 + (double.tryParse(taxRateCtrl.text) ?? 0) / 100)).toStringAsFixed(2)}',
                                Colors.green,
                                bold: true),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080)),
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                final taxRate = double.tryParse(taxRateCtrl.text) ?? 0.0;
                client.totalInvoiced = amount;
                client.invoiceTaxRate = taxRate;
                client.save();
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Save',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _addOrEditPayment([Payment? payment]) async {
    final isEdit = payment != null;
    final amountCtrl = TextEditingController(
        text: isEdit ? payment.amount.toStringAsFixed(2) : "");
    final descriptionCtrl =
        TextEditingController(text: isEdit ? payment.description : "");
    DateTime paidDate =
        isEdit ? (payment.paidDate ?? DateTime.now()) : DateTime.now();
    String modeOfPayment = isEdit ? payment.modeOfPayment : 'bank_transfer';
    final existingRetainerPayments = paymentsBox.values.where((p) =>
        p.clientKey == widget.clientKey &&
        p.isRetainer &&
        (!isEdit || p.key != payment.key));
    final existingRetainer =
        existingRetainerPayments.isNotEmpty ? existingRetainerPayments.first : null;
    final isFirstPaymentForClient = paymentsBox.values
        .where((p) => p.clientKey == widget.clientKey)
        .isEmpty;
    bool isRetainer = isEdit
        ? payment.isRetainer
        : (existingRetainer == null && isFirstPaymentForClient);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? "Edit Payment" : "Add Payment"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      hintText: "0.00",
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  if (client.invoiceTaxRate > 0 &&
                      (double.tryParse(amountCtrl.text) ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Builder(builder: (context) {
                        final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                        final rate = client.invoiceTaxRate;
                        final taxPortion = amt * rate / (100 + rate);
                        final principalPortion = amt - taxPortion;
                        return Text(
                          'Includes ~\$${taxPortion.toStringAsFixed(2)} tax (${rate.toStringAsFixed(0)}%) '
                          '\u00b7 \$${principalPortion.toStringAsFixed(2)} toward invoice',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                              fontStyle: FontStyle.italic),
                        );
                      }),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionCtrl,
                    decoration:
                        const InputDecoration(labelText: "Description"),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: modeOfPayment,
                    decoration: InputDecoration(
                      labelText: 'Mode of Payment',
                      filled: true,
                      fillColor: Colors.blue.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'card', child: Text('Card')),
                      DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                      DropdownMenuItem(value: 'mobile_payment', child: Text('Mobile Payment')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => modeOfPayment = val!),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: paidDate,
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 365 * 3)),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => paidDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blue.shade50,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Color(0xFF000080)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "Date: ${paidDate.toLocal().toString().split(" ")[0]}",
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    title: const Text("Mark as Retainer / Deposit",
                        style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                        existingRetainer != null
                            ? "Retainer already recorded on ${existingRetainer.paidDate?.toLocal().toString().split(' ')[0] ?? 'an earlier date'}"
                            : "First payment received to begin work",
                        style: TextStyle(
                            fontSize: 11,
                            color: existingRetainer != null
                                ? Colors.red.shade400
                                : Colors.grey)),
                    value: isRetainer,
                    onChanged: existingRetainer != null
                        ? null
                        : (val) =>
                            setDialogState(() => isRetainer = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel",
                    style: TextStyle(fontSize: 13))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13)),
              onPressed: () {
                final amount =
                    double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please enter a valid amount")),
                  );
                  return;
                }
                if (isEdit) {
                  payment
                    ..amount = amount
                    ..description = descriptionCtrl.text.trim()
                    ..paidDate = paidDate
                    ..modeOfPayment = modeOfPayment
                    ..isRetainer = isRetainer
                    ..save();
                } else {
                  paymentsBox.add(Payment(
                    clientKey: widget.clientKey,
                    amount: amount,
                    description: descriptionCtrl.text.trim(),
                    paidDate: paidDate,
                    dueDate: paidDate,
                    modeOfPayment: modeOfPayment,
                    isRetainer: isRetainer,
                  ));
                }
                Navigator.pop(context);
                setState(() {});
              },
              child: Text(
                isEdit ? "Update" : "Add Payment",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _exportToCSV() async {
    final payments = paymentsBox.values
        .where((p) => p.clientKey == widget.clientKey)
        .toList();
    final csvData = [
      ["Date", "Amount", "Tax", "Total", "Description"],
      ...payments.map((p) => [
            p.paidDate?.toLocal().toString().split(" ")[0] ?? "N/A",
            p.amount.toStringAsFixed(2),
            p.taxAmount.toStringAsFixed(2),
            p.totalAmount.toStringAsFixed(2),
            p.description,
          ]),
    ];
    final csvString = const ListToCsvConverter().convert(csvData);
    final directory = await getTemporaryDirectory();
    final path =
        "${directory.path}/billing_${client.fullName.replaceAll(" ", "_")}.csv";
    final file = File(path);
    await file.writeAsString(csvString);
    await SharePlus.instance.share(ShareParams(
        files: [XFile(path)],
        text: "Billing history for ${client.fullName}"));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: paymentsBox.listenable(),
      builder: (_, Box<Payment> box, __) {
        final payments = box.values
            .where((p) => p.clientKey == widget.clientKey)
            .toList()
          ..sort((a, b) => (b.paidDate ?? b.dueDate)
              .compareTo(a.paidDate ?? a.dueDate));

        final totalPaid =
            payments.fold(0.0, (sum, p) => sum + p.totalAmount);
        final invoiceTaxAmount =
            client.totalInvoiced * (client.invoiceTaxRate / 100);
        final totalInvoicedWithTax = client.totalInvoiced + invoiceTaxAmount;
        final balanceDue = totalInvoicedWithTax - totalPaid;
        final taxCollectedSoFar = totalInvoicedWithTax > 0
            ? (invoiceTaxAmount * (totalPaid / totalInvoicedWithTax))
                .clamp(0.0, invoiceTaxAmount)
            : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: Text("${client.fullName} - Billing",
                style: const TextStyle(color: Colors.white)),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Color(0xFF000080)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: _exportToCSV,
                tooltip: "Export to CSV",
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
            children: [
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.42,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade50, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('INVOICE SUMMARY',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 1.2)),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18,
                              color: Color(0xFF000080)),
                          tooltip: 'Edit Total Invoiced',
                          onPressed: _editTotalInvoiced,
                        ),
                      ],
                    ),
                    const Divider(),
                    _summaryRow('Amount Quoted/Invoiced (pre-tax)',
                        '\$${client.totalInvoiced.toStringAsFixed(2)}',
                        Colors.black87),
                    if (client.invoiceTaxRate > 0) ...[
                      const SizedBox(height: 4),
                      _summaryRow(
                          'Tax on Invoice (${client.invoiceTaxRate.toStringAsFixed(0)}%)',
                          '\$${invoiceTaxAmount.toStringAsFixed(2)}',
                          Colors.orange.shade700),
                      const SizedBox(height: 4),
                      _summaryRow('Total Invoiced (incl. tax)',
                          '\$${totalInvoicedWithTax.toStringAsFixed(2)}',
                          Colors.black87, bold: true),
                    ],
                    const SizedBox(height: 8),
                    _summaryRow('Subtotal Received',
                        '\$${payments.fold(0.0, (s, p) => s + p.amount).toStringAsFixed(2)}',
                        Colors.black54),
                    const SizedBox(height: 4),
                    _summaryRow('Tax Collected',
                        '\$${taxCollectedSoFar.toStringAsFixed(2)}',
                        Colors.orange.shade700),
                    const SizedBox(height: 4),
                    _summaryRow('Total Received (inc. tax)',
                        '\$${totalPaid.toStringAsFixed(2)}',
                        Colors.green, bold: true),
                    const Divider(),
                    _summaryRow('Balance Due',
                        '\$${balanceDue.toStringAsFixed(2)}',
                        balanceDue > 0 ? Colors.red : Colors.green,
                        bold: true, fontSize: 18),
                  ],
                ),
                ),
              ),
              Expanded(
                child: payments.isEmpty
                    ? const Center(
                        child: Text(
                            "No payments recorded\nTap + to add a payment",
                            textAlign: TextAlign.center),
                      )
                    : Builder(builder: (context) {
                        final chronological = payments.reversed.toList();
                        final paymentNumber = <dynamic, int>{};
                        final runningBalance = <dynamic, double>{};
                        double running = 0.0;
                        for (var idx = 0; idx < chronological.length; idx++) {
                          running += chronological[idx].totalAmount;
                          paymentNumber[chronological[idx].key] = idx + 1;
                          runningBalance[chronological[idx].key] =
                              totalInvoicedWithTax - running;
                        }
                        return ListView.builder(
                        itemCount: payments.length,
                        itemBuilder: (_, i) {
                          final p = payments[i];
                          final pNumber = paymentNumber[p.key] ?? (i + 1);
                          final pBalance = runningBalance[p.key] ?? 0.0;
                          return Dismissible(
                            key: Key(p.key.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete,
                                  color: Colors.white),
                            ),
                            confirmDismiss: (_) async =>
                                await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Delete Payment?"),
                                content: Text(
                                    "Delete \$${p.amount.toStringAsFixed(2)}?"),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("No")),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: const Text("Yes"),
                                  ),
                                ],
                              ),
                            ) ??
                                false,
                            onDismissed: (_) {
                              p.delete();
                              setState(() {});
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: i % 2 == 0
                                      ? [Colors.blue.shade50, Colors.white]
                                      : [Colors.teal.shade50, Colors.white],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Payment $pNumber',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14),
                                              ),
                                              if (p.isRetainer) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.indigo.shade50,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: Colors.indigo.shade200),
                                                  ),
                                                  child: Text('Retainer',
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.indigo.shade700,
                                                          fontWeight: FontWeight.w600)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (p.description.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(p.description,
                                                style: const TextStyle(
                                                    fontSize: 12, color: Colors.black87)),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${p.totalAmount.toStringAsFixed(2)} received',
                                            style: const TextStyle(
                                                color: Color(0xFF000080),
                                                fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Balance remaining: \$${pBalance.toStringAsFixed(2)}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: pBalance > 0
                                                    ? Colors.red.shade600
                                                    : Colors.green.shade700,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today,
                                                  size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                p.paidDate?.toLocal().toString().split(' ')[0] ?? 'No date',
                                                style: const TextStyle(
                                                    fontSize: 12, color: Colors.grey),
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(Icons.payment,
                                                  size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                p.modeOfPayment.replaceAll('_', ' '),
                                                style: const TextStyle(
                                                    fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Color(0xFF000080), size: 20),
                                      onPressed: () => _addOrEditPayment(p),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                      }),
              ),
            ],
          ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addOrEditPayment(),
            backgroundColor: const Color(0xFF000080),
            tooltip: "Add Payment",
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value, Color color,
      {bool bold = false, double fontSize = 15}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black54,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ),
        const SizedBox(width: 8),
        Text(value,
            style: TextStyle(
                fontSize: fontSize,
                color: color,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
      ],
    );
  }
}
