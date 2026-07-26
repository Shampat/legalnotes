import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/database/hive_service.dart';
import '../../../shared/models/client.dart';

class AddEditClientScreen extends StatefulWidget {
  final Client? client;
  const AddEditClientScreen({super.key, this.client});

  @override
  State<AddEditClientScreen> createState() => _AddEditClientScreenState();
}

class _AddEditClientScreenState extends State<AddEditClientScreen> {
  late bool isEdit;
  late TextEditingController firstNameCtrl;
  late TextEditingController lastNameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController dobCtrl;
  late TextEditingController companyCtrl;
  late TextEditingController matterCtrl;

  String clientStatus = 'prospective';
  DateTime? consultationDate;
  bool retainerSigned = false;
  bool nonEngagementLetterSent = false;

  bool firstNameError = false;
  bool dobError = false;
  bool lastNameError = false;
  bool phoneError = false;
  bool matterError = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey firstNameKey = GlobalKey();
  final GlobalKey dobKey = GlobalKey();
  final GlobalKey lastNameKey = GlobalKey();
  final GlobalKey phoneKey = GlobalKey();
  final GlobalKey matterKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    isEdit = client != null;

    firstNameCtrl = TextEditingController(text: client?.firstName ?? '');
    lastNameCtrl = TextEditingController(text: client?.lastName ?? '');
    phoneCtrl = TextEditingController(text: client?.phone ?? '');
    emailCtrl = TextEditingController(text: client?.email ?? '');
    addressCtrl = TextEditingController(text: client?.address ?? '');
    dobCtrl = TextEditingController(text: client?.dateOfBirth ?? '');
    companyCtrl = TextEditingController(text: client?.companyName ?? '');
    matterCtrl = TextEditingController(text: client?.matterDescription ?? '');

    clientStatus = client?.clientStatus ?? 'prospective';
    consultationDate = client?.consultationDate ?? DateTime.now();
    retainerSigned = client?.retainerSigned ?? false;
    nonEngagementLetterSent = client?.nonEngagementLetterSent ?? false;
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    addressCtrl.dispose();
    dobCtrl.dispose();
    companyCtrl.dispose();
    matterCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _save() {
    setState(() {
      firstNameError = firstNameCtrl.text.trim().isEmpty;
      lastNameError = lastNameCtrl.text.trim().isEmpty;
      phoneError = phoneCtrl.text.trim().isEmpty;
      matterError = matterCtrl.text.trim().isEmpty;
      dobError = dobCtrl.text.trim().isEmpty;
    });

    GlobalKey? firstErrorKey;
    if (firstNameError) {
      firstErrorKey = firstNameKey;
    } else if (lastNameError) {
      firstErrorKey = lastNameKey;
    } else if (phoneError) {
      firstErrorKey = phoneKey;
    } else if (matterError) {
      firstErrorKey = matterKey;
    } else if (dobError) {
      firstErrorKey = dobKey;
    }

    if (firstErrorKey != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required (*) fields')),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = firstErrorKey!.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.2,
          );
        }
      });
      return;
    }

    if (isEdit) {
      final client = widget.client!;
      client
        ..firstName = firstNameCtrl.text.trim()
        ..lastName = lastNameCtrl.text.trim()
        ..name = '${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}'.trim()
        ..phone = phoneCtrl.text.trim()
        ..email = emailCtrl.text.trim()
        ..address = addressCtrl.text.trim()
        ..matterDescription = matterCtrl.text.trim()
        ..dateOfBirth = dobCtrl.text.trim().isEmpty ? null : dobCtrl.text.trim()
        ..companyName = companyCtrl.text.trim().isEmpty ? null : companyCtrl.text.trim()
        ..clientStatus = clientStatus
        ..consultationDate = consultationDate
        ..retainerSigned = retainerSigned
        ..nonEngagementLetterSent = nonEngagementLetterSent
        ..save();
    } else {
      HiveService.clientsBox.add(Client(
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        matterDescription: matterCtrl.text.trim(),
        dateOfBirth: dobCtrl.text.trim().isEmpty ? null : dobCtrl.text.trim(),
        companyName: companyCtrl.text.trim().isEmpty ? null : companyCtrl.text.trim(),
        clientStatus: clientStatus,
        consultationDate: consultationDate,
        retainerSigned: retainerSigned,
        nonEngagementLetterSent: nonEngagementLetterSent,
      ));
    }
    Navigator.pop(context, true);
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    bool initiallyExpanded = true,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          backgroundColor: color.withValues(alpha: 0.12),
          collapsedBackgroundColor: color.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _customField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool required = false,
    bool hasError = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
    Key? fieldKey,
  }) {
    return Container(
      key: fieldKey,
      decoration: BoxDecoration(
        color: hasError ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError ? Colors.red.shade400 : Colors.grey.shade300,
          width: hasError ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasError ? Colors.red.shade700 : const Color(0xFF000080),
                ),
              ),
              if (required)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
            ],
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Required',
                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Client' : 'Add New Client',
          style: const TextStyle(color: Colors.white),
        ),
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
      ),
      body: SafeArea(
        child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fields marked with * are required — used to run conflict checks.',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                  ),
                ),
              ],
            ),
          ),
          _sectionCard(
            title: 'Personal Info',
            icon: Icons.person,
            color: Colors.indigo,
            children: [
              _customField(
                fieldKey: firstNameKey,
                controller: firstNameCtrl,
                label: 'First Name',
                hint: 'e.g. John',
                required: true,
                hasError: firstNameError,
                onChanged: (_) {
                  if (firstNameError) setState(() => firstNameError = false);
                },
              ),
              const SizedBox(height: 10),
              _customField(
                fieldKey: lastNameKey,
                controller: lastNameCtrl,
                label: 'Last Name',
                hint: 'e.g. Smith',
                required: true,
                hasError: lastNameError,
                onChanged: (_) {
                  if (lastNameError) setState(() => lastNameError = false);
                },
              ),
              const SizedBox(height: 10),
              _customField(
                fieldKey: phoneKey,
                controller: phoneCtrl,
                label: 'Phone',
                keyboardType: TextInputType.phone,
                required: true,
                hasError: phoneError,
                onChanged: (_) {
                  if (phoneError) setState(() => phoneError = false);
                },
              ),
              const SizedBox(height: 10),
              _customField(
                controller: emailCtrl,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              _customField(
                controller: addressCtrl,
                label: 'Address',
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              InkWell(
                key: dobKey,
                onTap: () async {
                  DateTime initial;
                  try {
                    initial = dobCtrl.text.trim().isNotEmpty
                        ? DateFormat('yyyy-MM-dd').parseStrict(dobCtrl.text.trim())
                        : DateTime(1990, 1, 1);
                  } catch (_) {
                    initial = DateTime(1990, 1, 1);
                  }
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      dobCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                      dobError = false;
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: dobError ? Colors.red.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: dobError ? Colors.red.shade400 : Colors.grey.shade300,
                      width: dobError ? 1.5 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Date of Birth',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: dobError ? Colors.red.shade700 : const Color(0xFF000080),
                            ),
                          ),
                          Text(' *',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16,
                              color: dobError ? Colors.red.shade400 : const Color(0xFF000080)),
                          const SizedBox(width: 8),
                          Text(
                            dobCtrl.text.trim().isEmpty ? 'Tap to select' : dobCtrl.text.trim(),
                            style: TextStyle(
                              fontSize: 15,
                              color: dobCtrl.text.trim().isEmpty
                                  ? Colors.grey.shade500
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      if (dobError)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Required',
                              style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _sectionCard(
            title: 'Case Details',
            icon: Icons.gavel,
            color: Colors.teal,
            children: [
              _customField(
                controller: companyCtrl,
                label: 'Company Name (if applicable)',
              ),
              const SizedBox(height: 10),
              _customField(
                fieldKey: matterKey,
                controller: matterCtrl,
                label: 'Matter Description',
                hint: 'Purpose of visit / legal matter',
                maxLines: 3,
                required: true,
                hasError: matterError,
                onChanged: (_) {
                  if (matterError) setState(() => matterError = false);
                },
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: consultationDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => consultationDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.teal),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Consultation Date: ${consultationDate != null ? DateFormat('dd MMM yyyy').format(consultationDate!) : 'Not set'}',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _sectionCard(
            title: 'Status',
            icon: Icons.flag,
            color: Colors.orange,
            children: [
              CheckboxListTile(
                title: const Text('Retainer Signed'),
                subtitle: Text(
                  retainerSigned
                      ? 'Client is now retained'
                      : nonEngagementLetterSent
                          ? 'Not applicable'
                          : 'Tick if retainer has been signed',
                  style: const TextStyle(fontSize: 11),
                ),
                value: retainerSigned,
                onChanged: nonEngagementLetterSent
                    ? null
                    : (val) {
                        setState(() {
                          retainerSigned = val!;
                          clientStatus = retainerSigned ? 'retained' : 'prospective';
                        });
                      },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Non-Engagement Letter Sent'),
                subtitle: Text(
                  nonEngagementLetterSent
                      ? 'Client was not retained'
                      : retainerSigned
                          ? 'Not applicable'
                          : 'Tick if non-engagement letter was sent',
                  style: const TextStyle(fontSize: 11),
                ),
                value: nonEngagementLetterSent,
                onChanged: retainerSigned
                    ? null
                    : (val) {
                        setState(() {
                          nonEngagementLetterSent = val!;
                          clientStatus = nonEngagementLetterSent ? 'former' : 'prospective';
                        });
                      },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'Update' : 'Add',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
      ),
    );
  }
}
