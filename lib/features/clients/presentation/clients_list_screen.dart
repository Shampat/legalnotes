import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/client.dart';
import '../../../shared/models/hearing.dart';
import '../../../shared/models/payment.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  late final Box<Client> _clientsBox;

  @override
  void initState() {
    super.initState();
    _clientsBox = HiveService.clientsBox;
  }

  void _addOrEditClient([Client? client]) {
    final isEdit = client != null;
    final nameController = TextEditingController(text: isEdit ? client.name : '');
    final phoneController = TextEditingController(text: isEdit ? client.phone : '');
    final emailController = TextEditingController(text: isEdit ? client.email : '');
    final addressController = TextEditingController(text: isEdit ? client.address : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Client' : 'Add New Client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newClient = Client(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim(),
                address: addressController.text.trim(),
              );

              if (isEdit) {
                client!
                  ..name = newClient.name
                  ..phone = newClient.phone
                  ..email = newClient.email
                  ..address = newClient.address
                  ..save();
              } else {
                _clientsBox.add(newClient);
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

  void _deleteClient(Client client) async {
    final hearings = HiveService.hearingsBox.values.where((h) => h.clientKey == (client.key as int)).toList();
    final payments = HiveService.paymentsBox.values.where((p) => p.clientKey == (client.key as int)).toList();
    final linkedCount = hearings.length + payments.length;

    if (linkedCount > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Client?'),
          content: Text('This client has $linkedCount linked items (${hearings.length} hearings, ${payments.length} payments).\nDelete client and all linked items?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete All'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    for (var h in hearings) h.delete();
    for (var p in payments) p.delete();
    client.delete();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final clients = _clientsBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: clients.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No clients yet', style: TextStyle(fontSize: 18)),
                  Text('Tap + to add your first client'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(client.name.isNotEmpty ? client.name[0].toUpperCase() : '?')),
                  title: Text(client.name),
                  subtitle: Text(client.phone),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteClient(client),
                  ),
                  onTap: () => _addOrEditClient(client),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditClient(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
