import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _selectedDate = DateTime.now();
  String _selectedCourse = '9th';
  bool _isLoading = false;
  bool _isSaving = false;

  final List<String> _courses = const ['8th', '9th', '10th', '11th', '12th'];
  final List<_AttendanceStatus> _statusOptions = const [
    _AttendanceStatus('present', 'Present', Colors.green),
    _AttendanceStatus('absent', 'Absent', Colors.red),
    _AttendanceStatus('pre-leave', 'Pre-Leave', Colors.orange),
  ];

  // Loaded students for the selected course (approved enrollments)
  List<_Student> _students = <_Student>[];

  // parentUid -> statusKey
  final Map<String, String> _statuses = <String, String>{};

  String get _dateKey {
    final d = _selectedDate;
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 1, 1, 1);
    final DateTime lastDate = DateTime(now.year + 1, 12, 31);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
      if (_students.isNotEmpty) {
        await _loadExistingAttendance();
      }
    }
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _students = <_Student>[];
      _statuses.clear();
    });
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('enrollments')
          .where('status', isEqualTo: 'approved')
          .where('course', isEqualTo: _selectedCourse)
          .get();

      final List<_Student> students = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _Student(
          enrollmentId: doc.id,
          parentUid: (data['parentUid'] as String?) ?? '',
          name: (data['studentName'] as String?) ?? 'Unknown',
          course: (data['course'] as String?) ?? '',
        );
      }).where((s) => s.parentUid.isNotEmpty).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _students = students;
      });

      await _loadExistingAttendance();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load students: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadExistingAttendance() async {
    // Pre-fill statuses for the selected date and course
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('attendance')
          .where('course', isEqualTo: _selectedCourse)
          .where('dateKey', isEqualTo: _dateKey)
          .get();

      final Map<String, String> loaded = <String, String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final uid = (data['parentUid'] as String?) ?? '';
        final status = (data['status'] as String?) ?? 'present';
        if (uid.isNotEmpty) loaded[uid] = status;
      }

      setState(() {
        // default to 'present' if not recorded yet
        _statuses.clear();
        for (final s in _students) {
          _statuses[s.parentUid] = loaded[s.parentUid] ?? 'present';
        }
      });
    } catch (e) {
      // Ignore errors; leave defaults
    }
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students to save for this class/date.')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final WriteBatch batch = _firestore.batch();
      final User? admin = FirebaseAuth.instance.currentUser;
      final DateTime now = DateTime.now();

      for (final s in _students) {
        final String status = _statuses[s.parentUid] ?? 'present';
        final String docId = '${_selectedCourse}_$_dateKey${s.parentUid}';
        final DocumentReference docRef = _firestore.collection('attendance').doc(docId);
        batch.set(docRef, <String, dynamic>{
          'course': _selectedCourse,
          'date': Timestamp.fromDate(_selectedDate),
          'dateKey': _dateKey,
          'parentUid': s.parentUid,
          'enrollmentId': s.enrollmentId,
          'studentName': s.name,
          'status': status, // present | absent | pre-leave
          'markedAt': Timestamp.fromDate(now),
          if (admin != null) 'markedBy': admin.email ?? admin.uid,
        }, SetOptions(merge: true));
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save attendance: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.30,
              child: Image.asset('assets/bg_math.png', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSelectorsCard(),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else if (_students.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'Select class and date, then tap "Load Students"',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    )
                  else
                    Expanded(child: _buildStudentList()),
                  const SizedBox(height: 12),
                  if (_students.isNotEmpty)
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.event, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Select Date & Class',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, color: Colors.green),
                  label: Text(
                    _dateKey,
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCourse,
                    decoration: const InputDecoration(
                      labelText: 'Class/Standard',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.school, color: Colors.green),
                    ),
                    items: _courses
                        .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedCourse = value;
                        _students = <_Student>[];
                        _statuses.clear();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadStudents,
              icon: const Icon(Icons.people),
              label: const Text('Load Students', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return Container(
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
      child: ListView.separated(
        itemCount: _students.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final s = _students[index];
          final String current = _statuses[s.parentUid] ?? 'present';
          return ListTile(
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('UID: ${s.parentUid.substring(0, s.parentUid.length > 8 ? 8 : s.parentUid.length)}...'),
            trailing: _buildStatusChips(s.parentUid, current),
          );
        },
      ),
    );
  }

  Widget _buildStatusChips(String parentUid, String current) {
    return Wrap(
      spacing: 8,
      children: _statusOptions.map((opt) {
        final bool selected = current == opt.key;
        return ChoiceChip(
          label: Text(opt.label),
          selected: selected,
          selectedColor: opt.color.withOpacity(0.2),
          labelStyle: TextStyle(
            color: selected ? opt.color : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          onSelected: (val) {
            setState(() {
              _statuses[parentUid] = opt.key;
            });
          },
        );
      }).toList(),
    );
  }
}

class _Student {
  final String enrollmentId;
  final String parentUid;
  final String name;
  final String course;

  _Student({
    required this.enrollmentId,
    required this.parentUid,
    required this.name,
    required this.course,
  });
}

class _AttendanceStatus {
  final String key; // 'present' | 'absent' | 'pre-leave'
  final String label;
  final Color color;
  const _AttendanceStatus(this.key, this.label, this.color);
}