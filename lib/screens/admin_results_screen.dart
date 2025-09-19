import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminResultsScreen extends StatefulWidget {
  const AdminResultsScreen({super.key});

  @override
  State<AdminResultsScreen> createState() => _AdminResultsScreenState();
}

class _AdminResultsScreenState extends State<AdminResultsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // Common filters
  String _selectedStandard = 'Select Standard';
  String _selectedSubject = 'Select Subject';

  // MCQ specific
  String _selectedMcqExam = 'Select Exam';
  List<String> _standards = const ['8th','9th','10th','11th','12th'];
  final List<String> _subjects = const ['Mathematics','Algebra','Geometry','CET'];
  List<Map<String, dynamic>> _mcqExams = [];
  Map<String, dynamic>? _activeMcqExam; // selected exam doc data + id

  // Descriptive specific
  String _selectedDescExam = 'Select Exam';
  List<Map<String, dynamic>> _descExams = [];
  final Map<String, TextEditingController> _marksControllers = {};
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _marksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'Results Manager',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.quiz), text: 'MCQ Results'),
            Tab(icon: Icon(Icons.edit_note), text: 'Descriptive Results'),
          ],
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMcqTab(),
                _buildDescriptiveTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== MCQ TAB =====================
  Widget _buildMcqTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFilters(onChanged: () {
            setState(() {
              _selectedMcqExam = 'Select Exam';
              _activeMcqExam = null;
            });
            _loadMcqExams();
          }),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 380,
              child: DropdownButtonFormField<String>(
                value: _selectedMcqExam,
                decoration: _ddDecoration('MCQ Exam'),
                items: [
                  const DropdownMenuItem(
                    value: 'Select Exam',
                    child: Text('Select Exam'),
                  ),
                  ..._mcqExams.map((e) => DropdownMenuItem(
                    value: e['id'] as String,
                    child: Text(e['title'] ?? 'Untitled'),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedMcqExam = value ?? 'Select Exam';
                    _activeMcqExam = _mcqExams.firstWhere(
                      (ex) => ex['id'] == value,
                      orElse: () => {},
                    );
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _activeMcqExam == null
                ? _buildHint('Select exam to view attempts')
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('enrollments')
                        .where('course', isEqualTo: _selectedStandard)
                        .where('status', isEqualTo: 'approved')
                        .snapshots(),
                    builder: (context, studentsSnap) {
                      if (studentsSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (studentsSnap.hasError) {
                        return Center(child: Text('Error: ${studentsSnap.error}'));
                      }
                      final students = studentsSnap.data?.docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        data['id'] = d.id;
                        return data;
                      }).toList() ?? [];
                      if (students.isEmpty) {
                        return _buildHint('No approved students for this standard');
                      }
                      // Load attempts once for the selected exam
                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('test_results')
                            .where('testId', isEqualTo: _activeMcqExam!['id'])
                            .get(),
                        builder: (context, resultsSnap) {
                          if (resultsSnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (resultsSnap.hasError) {
                            return Center(child: Text('Error: ${resultsSnap.error}'));
                          }
                          final attempts = <String, Map<String, dynamic>>{}; // key: studentEmail
                          for (final d in resultsSnap.data?.docs ?? []) {
                            final rd = d.data() as Map<String, dynamic>;
                            attempts[rd['studentEmail'] ?? ''] = {...rd, 'id': d.id};
                          }
                          return ListView.builder(
                            itemCount: students.length,
                            itemBuilder: (context, index) {
                              final s = students[index];
                              final email = s['email'] as String? ?? '';
                              final attempt = attempts[email];
                              return _buildMcqStudentRow(s, attempt);
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMcqAttemptCard(Map<String, dynamic> result) {
    final score = result['score'] as int? ?? 0;
    final total = result['totalMarks'] as int? ?? 1;
    final percent = result['percentage'] as int? ?? 0;
    final submittedAt = (result['submittedAt'] as Timestamp?)?.toDate();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: percent >= 80 ? Colors.green : percent >= 60 ? Colors.orange : Colors.red,
          child: Text('$percent%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        title: Text(result['studentEmail'] ?? 'Unknown'),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Score: $score/$total'),
          if (submittedAt != null) Text('Attempted: ${_fmt(submittedAt)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ]),
        trailing: IconButton(
          icon: const Icon(Icons.visibility),
          onPressed: () => _showAttemptDetails(result),
        ),
      ),
    );
  }

  void _showAttemptDetails(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result['testTitle'] ?? 'Attempt Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student: ${result['studentEmail'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('Subject: ${result['subject'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Score: ${result['score']}/${result['totalMarks']} (${result['percentage']}%)'),
              const SizedBox(height: 8),
              if (result['submittedAt'] != null)
                Text('Attempted: ${_fmt((result['submittedAt'] as Timestamp).toDate())}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildMcqStudentRow(Map<String, dynamic> student, Map<String, dynamic>? attempt) {
    final email = student['email'] as String? ?? '';
    final name = student['studentName'] as String? ?? email;
    if (attempt == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white, size: 18)),
          title: Text(name),
          subtitle: Text(email),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
            child: const Text('Not attempted', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }
    return _buildMcqAttemptCard(attempt);
  }

  Future<void> _loadMcqExams() async {
    if (!_isStdSubSelected()) return;
    
    try {
      // First try with targetStandards array field
      final qsArray = await FirebaseFirestore.instance
          .collection('content')
          .where('type', isEqualTo: 'mcq')
          .where('targetStandards', arrayContains: _selectedStandard)
          .where('subject', isEqualTo: _selectedSubject)
          .get();
      
      // If no results with array query, try with standard field
      if (qsArray.docs.isEmpty) {
        final qsField = await FirebaseFirestore.instance
            .collection('content')
            .where('type', isEqualTo: 'mcq')
            .where('standard', isEqualTo: _selectedStandard)
            .where('subject', isEqualTo: _selectedSubject)
            .get();
            
        setState(() {
          _mcqExams = qsField.docs.map((d) => ({...d.data(), 'id': d.id})).toList()
            ..sort((a, b) {
              final aDate = (a['uploadDate'] as Timestamp?)?.toDate() ?? DateTime(1970);
              final bDate = (b['uploadDate'] as Timestamp?)?.toDate() ?? DateTime(1970);
              return bDate.compareTo(aDate);
            });
        });
      } else {
        setState(() {
          _mcqExams = qsArray.docs.map((d) => ({...d.data(), 'id': d.id})).toList()
            ..sort((a, b) {
              final aDate = (a['uploadDate'] as Timestamp?)?.toDate() ?? DateTime(1970);
              final bDate = (b['uploadDate'] as Timestamp?)?.toDate() ?? DateTime(1970);
              return bDate.compareTo(aDate);
            });
        });
      }
      
      // Debug info
      print('Loaded ${_mcqExams.length} MCQ exams for $_selectedStandard - $_selectedSubject');
      for (final exam in _mcqExams) {
        print(' - ${exam['title']} (${exam['id']})');
      }
    } catch (e) {
      print('Error loading MCQ exams: $e');
      setState(() {
        _mcqExams = [];
      });
    }
  }

  // ===================== DESCRIPTIVE TAB =====================
  Widget _buildDescriptiveTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFilters(onChanged: () {
            setState(() {
              _selectedDescExam = 'Select Exam';
            });
            _loadDescExams();
          }),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 380,
              child: DropdownButtonFormField<String>(
                value: _selectedDescExam,
                decoration: _ddDecoration('Descriptive Exam'),
                items: [
                  const DropdownMenuItem(
                    value: 'Select Exam',
                    child: Text('Select Exam'),
                  ),
                  ..._descExams.map((e) => DropdownMenuItem(
                    value: e['id'] as String,
                    child: Text(e['title'] ?? 'Untitled'),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDescExam = value ?? 'Select Exam';
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: !_isStdSubSelected() || _selectedDescExam == 'Select Exam'
                ? _buildHint('Select exam to enter marks')
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('enrollments')
                        .where('course', isEqualTo: _selectedStandard)
                        .where('status', isEqualTo: 'approved')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final students = snapshot.data?.docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        data['id'] = d.id;
                        return data;
                      }).toList() ?? [];
                      if (students.isEmpty) {
                        return _buildHint('No approved students for this standard');
                      }
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: students.length,
                              itemBuilder: (context, index) {
                                final s = students[index];
                                final email = s['email'] as String? ?? '';
                                _marksControllers.putIfAbsent(email, () => TextEditingController());
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: CircleAvatar(child: Text('${index + 1}')),
                                    title: Text(s['studentName'] ?? email),
                                    subtitle: Text(email),
                                    trailing: SizedBox(
                                      width: 140,
                                      child: TextField(
                                        controller: _marksControllers[email],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Marks',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isPublishing ? null : _publishDescriptiveResults,
                              icon: _isPublishing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.publish),
                              label: const Text('Publish Results'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDescExams() async {
    if (!_isStdSubSelected()) return;
    
    try {
      // First try with targetStandards array field
      final qsArray = await FirebaseFirestore.instance
          .collection('content')
          .where('type', isEqualTo: 'descriptive')
          .where('targetStandards', arrayContains: _selectedStandard)
          .where('subject', isEqualTo: _selectedSubject)
          .get();
      
      // If no results with array query, try with standard field
      if (qsArray.docs.isEmpty) {
        final qsField = await FirebaseFirestore.instance
            .collection('content')
            .where('type', isEqualTo: 'descriptive')
            .where('standard', isEqualTo: _selectedStandard)
            .where('subject', isEqualTo: _selectedSubject)
            .get();
            
        setState(() {
          _descExams = qsField.docs.map((d) => ({...d.data(), 'id': d.id})).toList()
            ..sort((a, b) {
              final aDate = (a['uploadDate'] as Timestamp?)?.toDate() ?? DateTime(1970);
              final bDate = (b['uploadDate'] as Timestamp?)?.toDate() ?? DateTime(1970);
              return bDate.compareTo(aDate);
            });
        });
      } else {
        setState(() {
          _descExams = qsArray.docs.map((d) => ({...d.data(), 'id': d.id})).toList()
            ..sort((a, b) {
              final aDate = (a['uploadDate'] as Timestamp?)?.toDate() ?? DateTime(1970);
              final bDate = (b['uploadDate'] as Timestamp?)?.toDate() ?? DateTime(1970);
              return bDate.compareTo(aDate);
            });
        });
      }
      
      // Debug info
      print('Loaded ${_descExams.length} descriptive exams for $_selectedStandard - $_selectedSubject');
    } catch (e) {
      print('Error loading descriptive exams: $e');
      setState(() {
        _descExams = [];
      });
    }
  }

  Future<void> _publishDescriptiveResults() async {
    if (_selectedDescExam == 'Select Exam') return;
    setState(() {
      _isPublishing = true;
    });
    try {
      // load exam meta
      final examDoc = await FirebaseFirestore.instance.collection('content').doc(_selectedDescExam).get();
      if (!examDoc.exists) throw Exception('Exam not found');
      final exam = examDoc.data()!;
      final totalMarks = (exam['totalMarks'] as int?) ?? 0;

      // get students of standard
      final studentsSnap = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('course', isEqualTo: _selectedStandard)
          .where('status', isEqualTo: 'approved')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final d in studentsSnap.docs) {
        final data = d.data();
        final email = data['email'] as String? ?? '';
        if (email.isEmpty) continue;
        final controller = _marksControllers[email];
        final text = controller?.text.trim() ?? '';
        if (text.isEmpty) continue; // skip if no marks entered
        final obtained = int.tryParse(text);
        if (obtained == null) continue;

        final resultRef = FirebaseFirestore.instance.collection('test_results').doc();
        batch.set(resultRef, {
          'testId': examDoc.id,
          'testTitle': exam['title'] ?? 'Descriptive Exam',
          'studentId': data['parentUid'] ?? '',
          'studentEmail': email,
          'score': obtained,
          'totalMarks': totalMarks,
          'percentage': totalMarks > 0 ? ((obtained / totalMarks) * 100).round() : 0,
          'submittedAt': Timestamp.now(),
          'standard': _selectedStandard,
          'testStandard': _selectedStandard,
          'board': exam['board'] ?? '',
          'testBoard': exam['board'] ?? '',
          'subject': exam['subject'] ?? _selectedSubject,
          // No questionDetails for descriptive so student view will show as Descriptive
        });
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Results published successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing results: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  // ===================== COMMON UI =====================
  Widget _buildFilters({required VoidCallback onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              value: _selectedStandard,
              decoration: _ddDecoration('Standard'),
              items: [
                const DropdownMenuItem(value: 'Select Standard', child: Text('Select Standard')),
                ..._standards.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              ],
              onChanged: (v) {
                _selectedStandard = v ?? 'Select Standard';
                onChanged();
              },
            ),
          ),
          SizedBox(
            width: 280,
            child: DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: _ddDecoration('Subject'),
              items: [
                const DropdownMenuItem(value: 'Select Subject', child: Text('Select Subject')),
                ..._subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              ],
              onChanged: (v) {
                _selectedSubject = v ?? 'Select Subject';
                onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isStdSubSelected() {
    return _selectedStandard != 'Select Standard' && _selectedSubject != 'Select Subject';
  }

  InputDecoration _ddDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  Widget _buildHint(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}