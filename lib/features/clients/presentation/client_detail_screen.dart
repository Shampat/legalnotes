import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/services/database/hive_service.dart';
import 'add_edit_client_screen.dart';
import '../../../shared/models/client.dart';
import '../../../shared/models/communication_log.dart';

class ClientDetailScreen extends StatefulWidget {
  final Client client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  List<CommunicationLog> _logs() {
    return HiveService.communicationLogsBox.values
        .where((l) => l.clientKey == widget.client.key as int)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $url')),
        );
      }
    }
  }

  Future<void> _handleContact(String channel) async {
    final client = widget.client;

    if (channel == 'call') {
      await _launch('tel:${client.phone}');
    } else if (channel == 'email') {
      await _launch('mailto:${client.email}');
    } else if (channel == 'whatsapp') {
      final phone = client.phone.replaceAll(RegExp(r'[^\d]'), '');
      await _launch('https://wa.me/$phone');
    }

    if (!mounted) return;

    final options = channel == 'call'
        ? ['Connected', 'Not Connected', 'Left Voicemail']
        : ['Sent', 'Did Not Send'];

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(
          channel == 'call'
              ? 'How did the call go?'
              : channel == 'email'
                  ? 'Was the email sent?'
                  : 'Was the WhatsApp message sent?',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((opt) => ListTile(
                    title: Text(opt),
                    leading:
                        const Icon(Icons.circle_outlined, size: 20),
                    onTap: () => Navigator.pop(context, opt),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel — Do Not Log'),
          ),
        ],
      ),
    );

    if (result == null || result == 'cancel') return;

    String status;
    String note;
    if (result == 'Connected' || result == 'Sent') {
      status = 'connected';
      note = channel == 'call'
          ? 'Call connected'
          : channel == 'email'
              ? 'Email sent'
              : 'WhatsApp message sent';
    } else if (result == 'Left Voicemail') {
      status = 'voicemail';
      note = 'Left voicemail';
    } else {
      status = 'not_connected';
      note = channel == 'call'
          ? 'Call attempted — not connected'
          : channel == 'email'
              ? 'Email attempted — not sent'
              : 'WhatsApp attempted — not sent';
    }

    HiveService.communicationLogsBox.add(
      CommunicationLog(
        clientKey: widget.client.key as int,
        note: note,
        channel: channel,
        status: status,
      ),
    );
    setState(() {});
  }

  void _sendNonEngagementLetter() async {
    final client = widget.client;
    final date = DateFormat('MMMM d, yyyy').format(DateTime.now());
    final consultDate = client.consultationDate != null
        ? DateFormat('MMMM d, yyyy').format(client.consultationDate!)
        : 'recent date';

    final subject = Uri.encodeComponent(
        'Non-Engagement Letter - ${client.name}');
    final body = Uri.encodeComponent('''Dear ${client.name},

Thank you for consulting with our office on $consultDate regarding ${client.matterDescription.isEmpty ? 'your legal matter' : client.matterDescription}.

After careful consideration, we regret to inform you that we are unable to represent you in this matter at this time. This letter confirms that no solicitor-client relationship has been established between yourself and our office.

We encourage you to seek legal advice elsewhere as soon as possible, as time limits may apply to your matter.

Please be advised that this letter is being sent to you on $date.

Yours truly,

${HiveService.settingsBox.get('officeName', defaultValue: 'Our Law Office')}
''');

    final emailUrl =
        'mailto:${client.email}?subject=$subject&body=$body';
    await _launch(emailUrl);

    // Mark as sent
    client.nonEngagementLetterSent = true;
    await client.save();
    setState(() {});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Non-engagement letter opened in email app')),
    );
  }

  void _addManualNote() async {
    final ctrl = TextEditingController();
    String selectedChannel = 'note';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Communication Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'What was discussed?',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedChannel,
                items: const [
                  DropdownMenuItem(
                      value: 'note', child: Text('📝 Note')),
                  DropdownMenuItem(
                      value: 'call', child: Text('📞 Call')),
                  DropdownMenuItem(
                      value: 'email', child: Text('📧 Email')),
                  DropdownMenuItem(
                      value: 'whatsapp',
                      child: Text('💬 WhatsApp')),
                ],
                onChanged: (val) =>
                    setDialogState(() => selectedChannel = val!),
                decoration:
                    const InputDecoration(labelText: 'Channel'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080)),
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  HiveService.communicationLogsBox.add(
                    CommunicationLog(
                      clientKey: widget.client.key as int,
                      note: ctrl.text.trim(),
                      channel: selectedChannel,
                      status: 'connected',
                    ),
                  );
                  setState(() {});
                }
                Navigator.pop(context);
              },
              child: const Text('Save',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteLog(CommunicationLog log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Note?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      log.delete();
      setState(() {});
    }
  }

  IconData _channelIcon(String channel) {
    switch (channel) {
      case 'call':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'whatsapp':
        return Icons.chat;
      default:
        return Icons.note;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'connected':
        return Colors.green;
      case 'voicemail':
        return Colors.orange;
      case 'not_connected':
        return Colors.grey;
      default:
        return Colors.indigo;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'connected':
        return 'Connected';
      case 'voicemail':
        return 'Voicemail';
      case 'not_connected':
        return 'Not Connected';
      default:
        return '';
    }
  }

  Color _clientStatusColor(String status) {
    switch (status) {
      case 'retained':
        return Colors.green.shade700;
      case 'former':
        return Colors.grey.shade600;
      default:
        return Colors.orange.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = _logs();
    final client = widget.client;
    final isOverdue = client.isNonEngagementOverdue;
    final isUrgent = client.isNonEngagementUrgent;

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name,
            style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit Client',
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditClientScreen(client: client),
                ),
              );
              if (updated == true && mounted) setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete Client',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Client?'),
                  content: Text('Delete "\${widget.client.fullName}"?\nThis cannot be undone.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                widget.client.delete();
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF000020), Color(0xFF000080)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF000040),
        onPressed: _addManualNote,
        tooltip: 'Add Note',
        child: const Icon(Icons.note_add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Non-engagement alert
            if (isOverdue || isUrgent)
              Card(
                color: isOverdue
                    ? Colors.red.shade50
                    : Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                      color: isOverdue ? Colors.red : Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(Icons.warning,
                      color:
                          isOverdue ? Colors.red : Colors.orange),
                  title: Text(
                    isOverdue
                        ? 'Non-Engagement Letter OVERDUE!'
                        : 'Non-Engagement Letter Due Soon',
                    style: TextStyle(
                        color:
                            isOverdue ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    client.nonEngagementDeadline != null
                        ? 'Deadline: ${DateFormat('dd MMM yyyy • hh:mm a').format(client.nonEngagementDeadline!)}'
                        : '',
                  ),
                  trailing: client.email.isNotEmpty
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: isOverdue
                                  ? Colors.red
                                  : Colors.orange),
                          onPressed: _sendNonEngagementLetter,
                          child: const Text('Send',
                              style:
                                  TextStyle(color: Colors.white)),
                        )
                      : const Text('No email on file',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey)),
                ),
              ),

            if (isOverdue || isUrgent) const SizedBox(height: 12),

            // Client info card
            Card(
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                    color: Color(0xFF000080), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          _clientStatusColor(client.clientStatus),
                      child: Text(
                        client.name.isNotEmpty
                            ? client.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 28, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(client.name,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000080))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _clientStatusColor(client.clientStatus)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        client.clientStatus.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11,
                            color: _clientStatusColor(
                                client.clientStatus),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (client.phone.isNotEmpty)
                      Text(client.phone,
                          style:
                              const TextStyle(color: Colors.grey)),
                    if (client.email.isNotEmpty)
                      Text(client.email,
                          style:
                              const TextStyle(color: Colors.grey)),
                    if (client.companyName != null &&
                        client.companyName!.isNotEmpty)
                      Text(client.companyName!,
                          style: const TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic)),
                    if (client.address.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(client.address,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ),
                    if (client.matterDescription.isNotEmpty) ...[
                      const Divider(height: 16),
                      Text(
                        'Matter: ${client.matterDescription}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF000080)),
                      ),
                    ],
                    if (client.consultationDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Consultation: ${DateFormat('dd MMM yyyy').format(client.consultationDate!)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (client.retainerSigned)
                          const Chip(
                            label: Text('Retainer Signed',
                                style: TextStyle(fontSize: 11)),
                            backgroundColor: Color(0xFFE8F5E9),
                          ),
                        const SizedBox(width: 8),
                        if (client.nonEngagementLetterSent)
                          const Chip(
                            label: Text('Letter Sent',
                                style: TextStyle(fontSize: 11)),
                            backgroundColor: Color(0xFFFFF3E0),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                      children: [
                        _actionBtn(
                          icon: Icons.phone,
                          label: 'Call',
                          color: Colors.green,
                          onTap: client.phone.isNotEmpty
                              ? () => _handleContact('call')
                              : null,
                        ),
                        _actionBtn(
                          icon: Icons.email,
                          label: 'Email',
                          color: Colors.indigo,
                          onTap: client.email.isNotEmpty
                              ? () => _handleContact('email')
                              : null,
                        ),
                        _actionBtn(
                          icon: Icons.chat,
                          label: 'WhatsApp',
                          color: Colors.teal,
                          onTap: client.phone.isNotEmpty
                              ? () => _handleContact('whatsapp')
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Communication log header
            Row(
              children: [
                const Text('Communication Log',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000080))),
                const Spacer(),
                Text('${logs.length} entries',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),

            logs.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No communication logged yet',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    itemBuilder: (_, i) {
                      final log = logs[i];
                      final isNotConnected =
                          log.status == 'not_connected';
                      final statusColor =
                          _statusColor(log.status);

                      return Opacity(
                        opacity: isNotConnected ? 0.5 : 1.0,
                        child: Card(
                          margin:
                              const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8),
                            side: BorderSide(
                                color: statusColor
                                    .withValues(alpha: 0.4),
                                width: 1),
                          ),
                          child: ListTile(
                            leading: Icon(
                              _channelIcon(log.channel),
                              color: statusColor,
                            ),
                            title: Text(
                              log.note,
                              style: TextStyle(
                                decoration: isNotConnected
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isNotConnected
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  DateFormat(
                                          'dd MMM yyyy • hh:mm a')
                                      .format(log.createdAt),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey),
                                ),
                                const SizedBox(width: 8),
                                if (log.status != 'connected')
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _statusLabel(log.status),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: statusColor,
                                          fontWeight:
                                              FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red, size: 18),
                              onPressed: () => _deleteLog(log),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              radius: 28,
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
