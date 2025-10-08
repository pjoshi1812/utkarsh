import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStudentManagementScreen extends StatefulWidget {
  const AdminStudentManagementScreen({super.key});

  @override
  State<AdminStudentManagementScreen> createState() => _AdminStudentManagementScreenState();
}

class _AdminStudentManagementScreenState extends State<AdminStudentManagementScreen> {
  final _standards = const ['8th', '9th', '10th', '11th', '12th'];
  String _selected = '8th';
  final _statuses = const ['All', 'approved', 'pending', 'rejected'];
  String _status = 'approved';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'Student Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.30,
              child: Image.asset('assets/bg_math.png', fit: BoxFit.cover),
            ),
          ),
          Column(
            children: [
              _filterBar(),
              Expanded(child: _studentsList()),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        onPressed: _showAddDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
    );
  }

  Widget _filterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text('Standard:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selected,
            items: _standards.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _selected = v ?? _selected),
          ),
          const Spacer(),
          // in _filterBar(), replace the existing Status UI block
          const Text('Status:'),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _status,
            items: _statuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
        ],
      ),
    );
  }

  Widget _studentsList() {
    Query query = FirebaseFirestore.instance
    .collection('enrollments')
    .where('course', isEqualTo: _selected);

      if (_status != 'All') {
        query = query.where('status', isEqualTo: _status);
      }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('No students found for this standard.', style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['studentName'] ?? 'Unknown').toString();
            final email = (data['email'] ?? '').toString();
            final contact = (data['studentContact'] ?? '').toString();

            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (email.isNotEmpty) Text('Email: $email'),
                    if (contact.isNotEmpty) Text('Contact: $contact'),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => _handleRowAction(v, doc.id, data),
                  itemBuilder: (_) {
                    final isApproved = (data['status'] ?? '') == 'approved';
                    return [
                      if (!isApproved)
                        const PopupMenuItem(
                          value: 'approve',
                          child: ListTile(
                            leading: Icon(Icons.check, color: Colors.green),
                            title: Text('Approve'),
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete), title: Text('Delete')),
                      ),
                    ];
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleRowAction(String action, String docId, Map<String, dynamic> data) {
    if (action == 'edit') {
      _showEditDialog(docId, data);
    } else if (action == 'delete') {
      _confirmDelete(docId);
    } else if (action == 'approve') {
      FirebaseFirestore.instance
          .collection('enrollments')
          .doc(docId)
          .update({'status': 'approved'}).then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student approved')),
          );
        }
      });
    }
  }

  Future<void> _confirmDelete(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete student'),
        content: const Text('This will permanently remove the student record. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('enrollments').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      }
    }
  }

  Future<void> _showAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtl = TextEditingController();
    final contactCtl = TextEditingController();
    final whatsappCtl = TextEditingController();
    final emailCtl = TextEditingController();
    final schoolCtl = TextEditingController();
    final parentNameCtl = TextEditingController();
    final parentContactCtl = TextEditingController();
    final parentWhatsappCtl = TextEditingController();
    final parentEmailCtl = TextEditingController();
    final addressCtl = TextEditingController();
    final occCtl = TextEditingController();
    final prevMarksCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Student'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tf(nameCtl, 'Student Name', required_: true),
                _tf(contactCtl, 'Student Contact', required_: true),
                _tf(whatsappCtl, 'Student WhatsApp'),
                _tf(emailCtl, 'Student Email'),
                _tf(schoolCtl, 'School/College'),
                _tf(addressCtl, 'Address'),
                _tf(parentNameCtl, 'Parent Name', required_: true),
                _tf(parentContactCtl, 'Parent Contact', required_: true),
                _tf(parentWhatsappCtl, 'Parent WhatsApp'),
                _tf(parentEmailCtl, 'Parent Email'),
                _tf(occCtl, 'Occupation'),
                _tf(prevMarksCtl, 'Previous Maths Marks'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final data = {
                'studentType': 'New admission',
                'studentName': nameCtl.text.trim(),
                'studentContact': contactCtl.text.trim(),
                'studentWhatsApp': whatsappCtl.text.trim(),
                'address': addressCtl.text.trim(),
                'email': emailCtl.text.trim(),
                'schoolCollege': schoolCtl.text.trim(),
                'parentName': parentNameCtl.text.trim(),
                'parentContact': parentContactCtl.text.trim(),
                'parentWhatsApp': parentWhatsappCtl.text.trim(),
                'occupation': occCtl.text.trim(),
                'parentEmail': parentEmailCtl.text.trim(),
                'course': _selected,
                'previousMathsMarks': prevMarksCtl.text.trim(),
                'status': 'approved',
                'enrollmentDate': FieldValue.serverTimestamp(),
              };
              await FirebaseFirestore.instance.collection('enrollments').add(data);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student added')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(String docId, Map<String, dynamic> data) async {
    final formKey = GlobalKey<FormState>();
    final nameCtl = TextEditingController(text: data['studentName'] ?? '');
    final contactCtl = TextEditingController(text: data['studentContact'] ?? '');
    final whatsappCtl = TextEditingController(text: data['studentWhatsApp'] ?? '');
    final emailCtl = TextEditingController(text: data['email'] ?? '');
    final schoolCtl = TextEditingController(text: data['schoolCollege'] ?? '');
    final parentNameCtl = TextEditingController(text: data['parentName'] ?? '');
    final parentContactCtl = TextEditingController(text: data['parentContact'] ?? '');
    final parentWhatsappCtl = TextEditingController(text: data['parentWhatsApp'] ?? '');
    final parentEmailCtl = TextEditingController(text: data['parentEmail'] ?? '');
    final addressCtl = TextEditingController(text: data['address'] ?? '');
    final occCtl = TextEditingController(text: data['occupation'] ?? '');
    final prevMarksCtl = TextEditingController(text: data['previousMathsMarks'] ?? '');

    String course = (data['course'] ?? _selected).toString();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Student'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tf(nameCtl, 'Student Name', required_: true),
                _tf(contactCtl, 'Student Contact', required_: true),
                _tf(whatsappCtl, 'Student WhatsApp'),
                _tf(emailCtl, 'Student Email'),
                _tf(schoolCtl, 'School/College'),
                _tf(addressCtl, 'Address'),
                _tf(parentNameCtl, 'Parent Name', required_: true),
                _tf(parentContactCtl, 'Parent Contact', required_: true),
                _tf(parentWhatsappCtl, 'Parent WhatsApp'),
                _tf(parentEmailCtl, 'Parent Email'),
                _tf(occCtl, 'Occupation'),
                _tf(prevMarksCtl, 'Previous Maths Marks'),
                Row(
                  children: [
                    const Text('Standard: '),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: course,
                      items: _standards.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => course = v ?? course,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final patch = {
                'studentName': nameCtl.text.trim(),
                'studentContact': contactCtl.text.trim(),
                'studentWhatsApp': whatsappCtl.text.trim(),
                'address': addressCtl.text.trim(),
                'email': emailCtl.text.trim(),
                'schoolCollege': schoolCtl.text.trim(),
                'parentName': parentNameCtl.text.trim(),
                'parentContact': parentContactCtl.text.trim(),
                'parentWhatsApp': parentWhatsappCtl.text.trim(),
                'occupation': occCtl.text.trim(),
                'parentEmail': parentEmailCtl.text.trim(),
                'previousMathsMarks': prevMarksCtl.text.trim(),
                'course': course,
              };
              await FirebaseFirestore.instance.collection('enrollments').doc(docId).update(patch);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _tf(TextEditingController ctl, String label, {bool required_ = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) {
          if (!required_) return null;
          if (v == null || v.trim().isEmpty) return '$label is required';
          return null;
        },
      ),
    );
  }
}