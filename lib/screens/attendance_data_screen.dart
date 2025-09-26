import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceDataScreen extends StatefulWidget {
  const AttendanceDataScreen({super.key});

  @override
  State<AttendanceDataScreen> createState() => _AttendanceDataScreenState();
}

class _AttendanceDataScreenState extends State<AttendanceDataScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _selectedDate = DateTime.now();
  String _selectedCourse = '9th';
  bool _isLoading = false;

  final List<String> _courses = const ['8th', '9th', '10th', '11th', '12th'];

  // Attendance data
  List<_AttendanceRecord> _attendanceRecords = <_AttendanceRecord>[];

  String get _dateKey {
    final d = _selectedDate;
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Widget _legendChip(String label, MaterialColor color) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color.withOpacity(0.15),
      side: BorderSide(color: color.withOpacity(0.5)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
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
      await _loadAttendanceData();
    }
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoading = true;
      _attendanceRecords.clear();
    });

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('attendance')
          .where('course', isEqualTo: _selectedCourse)
          .where('dateKey', isEqualTo: _dateKey)
          .get();

      final List<_AttendanceRecord> records = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _AttendanceRecord(
          id: doc.id,
          studentName: (data['studentName'] as String?) ?? 'Unknown',
          course: (data['course'] as String?) ?? '',
          status: (data['status'] as String?) ?? 'present',
          date: (data['date'] as Timestamp?)?.toDate() ?? _selectedDate,
          markedAt: (data['markedAt'] as Timestamp?)?.toDate(),
          markedBy: (data['markedBy'] as String?) ?? 'Unknown',
        );
      }).toList();

      // Sort by student name for better organization
      records.sort((a, b) => a.studentName.compareTo(b.studentName));

      setState(() {
        _attendanceRecords = records;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load attendance data: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'pre-leave':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'pre-leave':
        return 'Pre-Leave';
      default:
        return 'Unknown';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'Attendance Data',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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
                  else if (_attendanceRecords.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No attendance data found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select a different date or class',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(child: _buildAttendanceList()),
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
              const Icon(Icons.analytics, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'View Attendance Data',
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
                      });
                      _loadAttendanceData();
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
              onPressed: _isLoading ? null : _loadAttendanceData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Data', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildAttendanceList() {
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
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Attendance Records (${_attendanceRecords.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    _buildSummaryChip(),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _legendChip('Present', Colors.green),
                    _legendChip('Absent', Colors.red),
                    _legendChip('Pre-Leave', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _attendanceRecords.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = _attendanceRecords[index];
                return _buildAttendanceCard(record);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip() {
    final presentCount = _attendanceRecords.where((r) => r.status == 'present').length;
    final absentCount = _attendanceRecords.where((r) => r.status == 'absent').length;
    final preLeaveCount = _attendanceRecords.where((r) => r.status == 'pre-leave').length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'P: $presentCount | A: $absentCount | PL: $preLeaveCount',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(_AttendanceRecord record) {
    final statusColor = _getStatusColor(record.status);
    final statusLabel = _getStatusLabel(record.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(
            record.status == 'present' ? Icons.check :
            record.status == 'absent' ? Icons.close : Icons.schedule,
            color: statusColor,
          ),
        ),
        title: Text(
          record.studentName,
          style: const TextStyle(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double itemMaxWidth = constraints.maxWidth * 0.48;
              return Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: itemMaxWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Class: ${record.course}',
                            style: TextStyle(color: Colors.grey[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (record.markedAt != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: itemMaxWidth),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Marked: ${_formatDateTime(record.markedAt!)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Chip(
            label: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            backgroundColor: statusColor.withOpacity(0.1),
            side: BorderSide(color: statusColor),
          ),
        ),
        onTap: () => _showAttendanceDetails(record),
      ),
    );
  }

  void _showAttendanceDetails(_AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Student Name', record.studentName),
              _buildDetailRow('Class', record.course),
              _buildDetailRow('Date', _formatDate(record.date)),
              _buildDetailRow('Status', _getStatusLabel(record.status)),
              if (record.markedAt != null)
                _buildDetailRow('Marked At', _formatDateTime(record.markedAt!)),
              _buildDetailRow('Marked By', record.markedBy),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _AttendanceRecord {
  final String id;
  final String studentName;
  final String course;
  final String status;
  final DateTime date;
  final DateTime? markedAt;
  final String markedBy;

  _AttendanceRecord({
    required this.id,
    required this.studentName,
    required this.course,
    required this.status,
    required this.date,
    this.markedAt,
    required this.markedBy,
  });
}
