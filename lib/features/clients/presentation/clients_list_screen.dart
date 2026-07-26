import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/client.dart';
import 'client_detail_screen.dart';
import 'add_edit_client_screen.dart';
import 'import_clients_screen.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  late final Box<Client> _clientsBox;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _clientsBox = HiveService.clientsBox;
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _addOrEditClient([Client? client]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditClientScreen(client: client),
      ),
    );
    if (result == true) setState(() {});
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'retained':
        return Colors.green.shade700;
      case 'former':
        return Colors.grey.shade600;
      default:
        return Colors.orange.shade700;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'retained':
        return Icons.check_circle;
      case 'former':
        return Icons.archive;
      default:
        return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final clients = _clientsBox.values
        .where((c) =>
            query.isEmpty ||
            c.fullName.toLowerCase().contains(query) ||
            c.phone.toLowerCase().contains(query) ||
            c.email.toLowerCase().contains(query) ||
            c.matterDescription.toLowerCase().contains(query))
        .toList();

    // Sort: overdue prospective first, then urgent, then rest
    clients.sort((a, b) {
      if (a.isNonEngagementOverdue && !b.isNonEngagementOverdue) {
        return -1;
      }
      if (!a.isNonEngagementOverdue && b.isNonEngagementOverdue) {
        return 1;
      }
      if (a.isNonEngagementUrgent && !b.isNonEngagementUrgent) {
        return -1;
      }
      return a.name.compareTo(b.name);
    });

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search clients...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
              )
            : const Text('Clients',
                style: TextStyle(color: Colors.white)),
        centerTitle: !_showSearch,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF000020), Color(0xFF000080)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (_showSearch)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _showSearch = false);
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.upload_file, color: Colors.white),
              tooltip: 'Import Clients',
              onPressed: () async {
                final imported = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ImportClientsScreen()),
                );
                if (imported == true) setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => setState(() => _showSearch = true),
            ),
          ],
        ],
      ),
      body: clients.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline,
                      size: 80, color: Color(0xFF000080)),
                  const SizedBox(height: 16),
                  Text(
                    query.isNotEmpty
                        ? 'No clients match "$query"'
                        : 'No clients yet',
                    style: const TextStyle(
                        fontSize: 18, color: Color(0xFF000080)),
                  ),
                  if (query.isNotEmpty)
                    TextButton(
                      onPressed: () => _searchCtrl.clear(),
                      child: const Text('Clear search'),
                    )
                  else
                    const Text('Tap + to add your first client',
                        style: TextStyle(color: Color(0xFF000080))),
                ],
              ),
            )
          : ListView.builder(
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                final isOverdue = client.isNonEngagementOverdue;
                final isUrgent = client.isNonEngagementUrgent;

                return Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: isOverdue
                          ? Colors.red
                          : isUrgent
                              ? Colors.orange
                              : const Color(0xFF000080),
                      width: isOverdue || isUrgent ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  color: isOverdue
                      ? Colors.red.shade50
                      : isUrgent
                          ? Colors.orange.shade50
                          : null,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor:
                          _statusColor(client.clientStatus),
                      child: Text(
                        client.fullName.isNotEmpty
                            ? client.fullName[0].toUpperCase()
                            : '?',
                        style:
                            const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      client.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000080)),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_statusIcon(client.clientStatus),
                                size: 14,
                                color: _statusColor(client.clientStatus)),
                            const SizedBox(width: 4),
                            Text(
                              client.clientStatus.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _statusColor(client.clientStatus),
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(client.phone,
                            style: const TextStyle(
                                color: Color(0xFF000040))),
                        if (client.matterDescription.isNotEmpty)
                          Text(
                            client.matterDescription,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (isOverdue)
                          const Text(
                            '⚠️ Non-engagement letter OVERDUE',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.bold),
                          ),
                        if (isUrgent && !isOverdue)
                          const Text(
                            '⚠️ Non-engagement letter due soon',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFF000080)),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ClientDetailScreen(client: client)),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditClient(),
        backgroundColor: const Color(0xFF000040),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
