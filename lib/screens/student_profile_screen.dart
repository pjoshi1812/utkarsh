import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _enrollment;
  DocumentReference<Map<String, dynamic>>? _enrollmentRef;
  String? _photoUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadEnrollment();
  }

  Future<void> _loadEnrollment() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }
      final q = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('parentUid', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        final doc = q.docs.first;
        setState(() {
          _enrollment = doc.data();
          _enrollmentRef = doc.reference;
          _photoUrl = (_enrollment?['profilePhotoUrl'] as String?)?.trim();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _enrollmentRef == null) return;

    try {
      setState(() => _uploading = true);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _uploading = false);
        return;
      }
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read selected image.')),
        );
        return;
      }

      final ext = (file.extension ?? 'jpg').toLowerCase();
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.$ext');

      final metadata = SettableMetadata(contentType: 'image/$ext');
      await ref.putData(bytes, metadata);
      final url = await ref.getDownloadURL();

      await _enrollmentRef!.update({'profilePhotoUrl': url});
      setState(() {
        _photoUrl = url;
        _uploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated.')),
        );
      }
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'My Profile',
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
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_enrollment == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No approved enrollment found for your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _headerCard(),
                  const SizedBox(height: 20),
                  _sectionCard('Student Information', [
                    _kv('Name', _enrollment!['studentName']),
                    _kv('Course', _enrollment!['course']),
                    _kv('Contact', _enrollment!['studentContact']),
                    _kv('WhatsApp', _enrollment!['studentWhatsApp']),
                    _kv('Email', _enrollment!['email']),
                    _kv('School/College', _enrollment!['schoolCollege']),
                    _kv('Address', _enrollment!['address']),
                  ]),
                  const SizedBox(height: 20),
                  _sectionCard('Parent/Guardian', [
                    _kv('Name', _enrollment!['parentName']),
                    _kv('Contact', _enrollment!['parentContact']),
                    _kv('WhatsApp', _enrollment!['parentWhatsApp']),
                    _kv('Email', _enrollment!['parentEmail']),
                    _kv('Occupation', _enrollment!['occupation']),
                  ]),
                  const SizedBox(height: 20),
                  _sectionCard('Enrollment Details', [
                    _kv('Student Type', _enrollment!['studentType']),
                    _kv('Previous Maths Marks', _enrollment!['previousMathsMarks']),
                    _kv('Status', _enrollment!['status']),
                  ]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerCard() {
    final name = (_enrollment?['studentName'] ?? '').toString();
    final course = (_enrollment?['course'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.green[100],
                backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                    ? NetworkImage(_photoUrl!)
                    : null,
                child: (_photoUrl == null || _photoUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 48, color: Colors.green)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: ElevatedButton.icon(
                  onPressed: _uploading ? null : _pickAndUploadPhoto,
                  icon: _uploading
                      ? const SizedBox(
                          height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.edit, size: 16),
                  label: Text(_uploading ? 'Uploading...' : 'Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 4),
          Text('Course: $course', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Enrollment Approved ✓',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _kv(String label, dynamic value) {
    final v = (value ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 150,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.black87))),
          const SizedBox(width: 8),
          Expanded(child: Text(v.isEmpty ? '-' : v)),
        ],
      ),
    );
  }
}