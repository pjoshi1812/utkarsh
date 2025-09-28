import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminResultsScreen extends StatefulWidget {
  const AdminResultsScreen({super.key});

  @override
  State<AdminResultsScreen> createState() => _AdminResultsScreenState();
}

class _AdminResultsScreenState extends State<AdminResultsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Common filters
  String _selectedStandard = 'Select Standard';
  String _selectedSubject = 'Select Subject';

  // MCQ specific
  String _selectedMcqExam = 'Select Exam';
  List<String> _standards = const ['8th', '9th', '10th', '11th', '12th'];
  final List<String> _subjects = const [
    'Mathematics',
    'Algebra',
    'Geometry',
    'CET',
  ];
  List<Map<String, dynamic>> _mcqExams = [];
  Map<String, dynamic>? _activeMcqExam; // selected exam doc data + id

  // Descriptive specific
  String _selectedDescExam = 'Select Exam';
  List<Map<String, dynamic>> _descExams = [];
  final Map<String, TextEditingController> _marksControllers = {};
  bool _isPublishing = false;
  // Descriptive search/filter
  final TextEditingController _descSearchController = TextEditingController();
  String _descSearchQuery = '';

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
    _descSearchController.dispose();
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
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
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
              children: [_buildMcqTab(), _buildDescriptiveTab()],
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
              child: !_isStdSubSelected() || _mcqExams.isEmpty
                  ? const SizedBox()
                  : DropdownButtonFormField<String>(
                      value: _mcqExams.any((e) => e['id'] == _selectedMcqExam)
                          ? _selectedMcqExam
                          : 'Select Exam',
                      decoration: _ddDecoration('MCQ Exam'),
                      items: [
                        const DropdownMenuItem(
                          value: 'Select Exam',
                          child: Text('Select Exam'),
                        ),
                        ..._mcqExams.map(
                          (e) => DropdownMenuItem(
                            value: e['id'] as String,
                            child: Text(e['title'] ?? 'Untitled'),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedMcqExam = value ?? 'Select Exam';
                          _activeMcqExam = (value != null && value != 'Select Exam')
                              ? _mcqExams.firstWhere(
                                  (ex) => ex['id'] == value,
                                  orElse: () => {},
                                )
                              : null;
                        });
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: !_isStdSubSelected() || _activeMcqExam == null
                ? _buildHint('Select standard, subject and exam to view attempts')
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('test_results')
                        .where('testId', isEqualTo: _activeMcqExam!['id'])
                        .snapshots(),
                    builder: (context, resultsSnap) {
                      if (resultsSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (resultsSnap.hasError) {
                        return Center(child: Text('Error: ${resultsSnap.error}'));
                      }
                      final attempts = resultsSnap.data?.docs
                              .map((d) => ({
                                    ...d.data() as Map<String, dynamic>,
                                    'id': d.id
                                  }))
                              .toList() ??
                          [];

                      // Sort client-side by submittedAt desc (avoid composite index).
                      attempts.sort((a, b) {
                        final ad = (a['submittedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
                        final bd = (b['submittedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
                        return bd.compareTo(ad);
                      });

                      // Show ONLY selected standard + subject results
                      final filtered = attempts.where((a) {
                        final std = a['standard'] ?? a['testStandard'];
                        final sub = a['subject'];
                        return std == _selectedStandard && sub == _selectedSubject;
                      }).toList();

                      if (filtered.isEmpty) {
                        return _buildHint('No attempts yet for this exam');
                      }
                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final a = filtered[index];
                          final submittedAt =
                              (a['submittedAt'] as Timestamp?)?.toDate();
                          final email = a['studentEmail'] ?? 'Unknown';
                          final score = a['score'] ?? 0;
                          final total = a['totalMarks'] ?? 0;
                          final percent = a['percentage'] ?? 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              isThreeLine: true,
                              leading: CircleAvatar(
                                backgroundColor: percent >= 80
                                    ? Colors.green
                                    : percent >= 60
                                        ? Colors.orange
                                        : Colors.red,
                                child: Text(
                                  '$percent%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Marks: $score/$total',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (submittedAt != null)
                                    Text(
                                      'Attempted: ${_fmt(submittedAt)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () => _showAttemptDetails(a),
                              ),
                            ),
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

  void _showAttemptDetails(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(result['testTitle'] ?? 'Attempt Details'),
          content: FutureBuilder<Map<String, dynamic>>(
            future: () async {
              final Map<String, dynamic> answers =
                  Map<String, dynamic>.from(result['answers'] ?? {});
              Map<String, dynamic> qDetails =
                  Map<String, dynamic>.from(result['questionDetails'] ?? {});
              if (qDetails.isEmpty && (result['testId'] != null)) {
                try {
                  final doc = await FirebaseFirestore.instance
                      .collection('content')
                      .doc(result['testId'] as String)
                      .get();
                  final data = doc.data() as Map<String, dynamic>?;
                  if (data != null) {
                    final questions =
                        List<Map<String, dynamic>>.from(data['questions'] ?? []);
                    final Map<String, dynamic> temp = {};
                    for (int i = 0; i < questions.length; i++) {
                      final q = questions[i];
                      temp['$i'] = {
                        'question': q['question'] ?? '',
                        'options': q['options'] ?? {},
                        'correctAnswer': q['correctAnswer'] ?? '',
                        'marks': q['marks'] ?? 0,
                        'explanation': q['explanation'] ?? '',
                      };
                    }
                    qDetails = temp;
                  }
                } catch (_) {}
              }
              return {'answers': answers, 'qDetails': qDetails};
            }(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  width: 320,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final Map<String, dynamic> answers =
                  Map<String, dynamic>.from(snapshot.data!['answers']);
              final Map<String, dynamic> qDetails =
                  Map<String, dynamic>.from(snapshot.data!['qDetails']);
              final sortedKeys = qDetails.keys.toList()
                ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student: ${result['studentEmail'] ?? 'Unknown'}'),
                    const SizedBox(height: 8),
                    Text('Subject: ${result['subject'] ?? 'N/A'}'),
                    const SizedBox(height: 8),
                    Text(
                      'Score: ${result['score']}/${result['totalMarks']} (${result['percentage']}%)',
                    ),
                    const SizedBox(height: 8),
                    if (result['submittedAt'] != null)
                      Text(
                        'Attempted: ${_fmt((result['submittedAt'] as Timestamp).toDate())}',
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Question-wise Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...sortedKeys.map((k) {
                      final idx = int.tryParse(k) ?? 0;
                      final Map<String, dynamic> q =
                          Map<String, dynamic>.from(qDetails[k] as Map);
                      final String questionText =
                          q['question']?.toString() ?? '';
                      final Map<String, dynamic> options =
                          Map<String, dynamic>.from(q['options'] ?? {});
                      final String correct =
                          q['correctAnswer']?.toString() ?? '';
                      final int marks = q['marks'] is int
                          ? q['marks'] as int
                          : int.tryParse('${q['marks']}') ?? 0;
                      final String studentAns =
                          (answers[k]?.toString() ?? 'Not answered');
                      final bool isCorrect = studentAns == correct;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: isCorrect ? Colors.green[50] : Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q${idx + 1} (${marks} marks)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(questionText),
                              const SizedBox(height: 8),
                              ...options.entries.map((e) {
                                final optKey = e.key.toString();
                                final optText = e.value.toString();
                                final bool isOptCorrect = optKey == correct;
                                final bool isOptChosen = optKey == studentAns;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: isOptCorrect
                                              ? Colors.green[600]
                                              : isOptChosen
                                                  ? Colors.orange[600]
                                                  : Colors.grey[400],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            optKey,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          optText,
                                          style: TextStyle(
                                            color: isOptCorrect
                                                ? Colors.green[800]
                                                : isOptChosen
                                                    ? Colors.orange[800]
                                                    : Colors.black87,
                                            fontWeight: isOptCorrect ||
                                                    isOptChosen
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 6),
                              Text('Student Answer: $studentAns'),
                              Text('Correct Answer: $correct'),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ===================== DESCRIPTIVE TAB =====================
  Widget _buildDescriptiveTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFilters(
            onChanged: () {
              setState(() {
                _selectedDescExam = 'Select Exam';
              });
              _loadDescExams();
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 380,
              child: _descExams.isEmpty
                  ? const SizedBox()
                  : DropdownButtonFormField<String>(
                      value: _descExams.any((e) => e['id'] == _selectedDescExam)
                          ? _selectedDescExam
                          : 'Select Exam',
                      decoration: _ddDecoration('Descriptive Exam'),
                      items: [
                        const DropdownMenuItem(
                          value: 'Select Exam',
                          child: Text('Select Exam'),
                        ),
                        ..._descExams.map(
                          (e) => DropdownMenuItem(
                            value: e['id'] as String,
                            child: Text(e['title'] ?? 'Untitled'),
                          ),
                        ),
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
          // Search bar for descriptive students
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 380,
              child: TextField(
                controller: _descSearchController,
                decoration: const InputDecoration(
                  labelText: 'Search student (name or email)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _descSearchQuery = v.trim().toLowerCase()),
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
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }
                      final students = snapshot.data?.docs.map((d) {
                            final data = d.data() as Map<String, dynamic>;
                            data['id'] = d.id;
                            return data;
                          }).toList() ??
                          [];
                      if (students.isEmpty) {
                        return _buildHint(
                          'No approved students for this standard',
                        );
                      }
                      // Listen to already submitted results for this descriptive exam
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('test_results')
                            .where('testId', isEqualTo: _selectedDescExam)
                            .snapshots(),
                        builder: (context, resSnap) {
                          if (resSnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (resSnap.hasError) {
                            return Center(child: Text('Error: ${resSnap.error}'));
                          }
                          final resultDocs = resSnap.data?.docs ?? [];
                          final Map<String, Map<String, dynamic>> submittedByEmail = {
                            for (final d in resultDocs)
                              (d.data() as Map<String, dynamic>)['studentEmail'] ?? '':
                                  ({...d.data() as Map<String, dynamic>, 'id': d.id})
                          }..remove('');

                          // Apply search filter
                          final q = _descSearchQuery;
                          final filteredStudents = q.isEmpty
                              ? students
                              : students.where((s) {
                                  final name = (s['studentName'] ?? '').toString().toLowerCase();
                                  final email = (s['email'] ?? '').toString().toLowerCase();
                                  return name.contains(q) || email.contains(q);
                                }).toList();

                          return Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredStudents.length,
                                  itemBuilder: (context, index) {
                                    final s = filteredStudents[index];
                                    final email = s['email'] as String? ?? '';
                                    final name = s['studentName'] as String? ?? email;
                                    _marksControllers.putIfAbsent(
                                      email,
                                      () => TextEditingController(),
                                    );

                                    final existing = submittedByEmail[email];
                                    if (existing != null) {
                                      final score = existing['score'] ?? 0;
                                      final total = existing['totalMarks'] ?? 0;
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        child: ListTile(
                                          leading: const CircleAvatar(
                                            child: Icon(Icons.check, color: Colors.white),
                                            backgroundColor: Colors.green,
                                          ),
                                          title: Text(name),
                                          subtitle: Text('$email\nSubmitted: $score/$total'),
                                          isThreeLine: true,
                                          trailing: IconButton(
                                            tooltip: 'Edit marks',
                                            icon: const Icon(Icons.edit),
                                            onPressed: () async {
                                              final ctrl = TextEditingController(text: '$score');
                                              await showDialog(
                                                context: context,
                                                builder: (ctx) {
                                                  return AlertDialog(
                                                    title: const Text('Edit Marks'),
                                                    content: TextField(
                                                      controller: ctrl,
                                                      keyboardType: TextInputType.number,
                                                      decoration: const InputDecoration(
                                                        labelText: 'Marks obtained',
                                                        border: OutlineInputBorder(),
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(ctx),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          final newText = ctrl.text.trim();
                                                          final newScore = int.tryParse(newText);
                                                          if (newScore == null) return;
                                                          final totalMarks = existing['totalMarks'] ?? 0;
                                                          final percent = totalMarks > 0
                                                              ? ((newScore / totalMarks) * 100).round()
                                                              : 0;
                                                          await FirebaseFirestore.instance
                                                              .collection('test_results')
                                                              .doc(existing['id'] as String)
                                                              .update({
                                                            'score': newScore,
                                                            'percentage': percent,
                                                            'submittedAt': Timestamp.now(),
                                                          });
                                                          if (mounted) Navigator.pop(ctx);
                                                        },
                                                        child: const Text('Save'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    }

                                    // Not yet submitted: allow entering marks
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          child: Text('${index + 1}'),
                                        ),
                                        title: Text(name),
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
                                  onPressed: _isPublishing
                                      ? null
                                      : _publishDescriptiveResults,
                                  icon: _isPublishing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.publish),
                                  label: const Text('Publish Results (only for unsubmitted)'),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
      final docs = qsArray.docs.isEmpty
          ? (await FirebaseFirestore.instance
                  .collection('content')
                  .where('type', isEqualTo: 'mcq')
                  .where('standard', isEqualTo: _selectedStandard)
                  .where('subject', isEqualTo: _selectedSubject)
                  .get())
              .docs
          : qsArray.docs;

      setState(() {
        _mcqExams =
            docs.map((d) => ({...d.data(), 'id': d.id})).toList()
              ..sort((a, b) {
                final aDate = (a['uploadDate'] as Timestamp?)?.toDate() ??
                    DateTime(1970);
                final bDate = (b['uploadDate'] as Timestamp?)?.toDate() ??
                    DateTime(1970);
                return bDate.compareTo(aDate);
              });
        // Ensure dropdown value is valid for the new list
        final hasSelected = _mcqExams.any((e) => e['id'] == _selectedMcqExam);
        if (!hasSelected) {
          _selectedMcqExam = 'Select Exam';
          _activeMcqExam = null;
        }
      });

      // Debug info
      // ignore: avoid_print
      print(
        'Loaded ${_mcqExams.length} MCQ exams for $_selectedStandard - $_selectedSubject',
      );
      for (final exam in _mcqExams) {
        // ignore: avoid_print
        print(' - ${exam['title']} (${exam['id']})');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading MCQ exams: $e');
      setState(() {
        _mcqExams = [];
      });
    }
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

      final docs = qsArray.docs.isEmpty
          ? (await FirebaseFirestore.instance
                  .collection('content')
                  .where('type', isEqualTo: 'descriptive')
                  .where('standard', isEqualTo: _selectedStandard)
                  .where('subject', isEqualTo: _selectedSubject)
                  .get())
              .docs
          : qsArray.docs;

      setState(() {
        _descExams =
            docs.map((d) => ({...d.data(), 'id': d.id})).toList()
              ..sort((a, b) {
                final aDate = (a['uploadDate'] as Timestamp?)?.toDate() ??
                    DateTime(1970);
                final bDate = (b['uploadDate'] as Timestamp?)?.toDate() ??
                    DateTime(1970);
                return bDate.compareTo(aDate);
              });
      });

      // Debug info
      // ignore: avoid_print
      print(
        'Loaded ${_descExams.length} descriptive exams for $_selectedStandard - $_selectedSubject',
      );
    } catch (e) {
      // ignore: avoid_print
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
      final examDoc = await FirebaseFirestore.instance
          .collection('content')
          .doc(_selectedDescExam)
          .get();
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

        final resultRef =
            FirebaseFirestore.instance.collection('test_results').doc();
        batch.set(resultRef, {
          'testId': examDoc.id,
          'testTitle': exam['title'] ?? 'Descriptive Exam',
          'studentId': data['parentUid'] ?? '',
          'studentEmail': email,
          'score': obtained,
          'totalMarks': totalMarks,
          'percentage':
              totalMarks > 0 ? ((obtained / totalMarks) * 100).round() : 0,
          'submittedAt': Timestamp.now(),
          'standard': _selectedStandard,
          'testStandard': _selectedStandard,
          'board': exam['board'] ?? '',
          'testBoard': exam['board'] ?? '',
          'subject': exam['subject'] ?? _selectedSubject,
        });
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Results published successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error publishing results: $e'),
            backgroundColor: Colors.red,
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
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
                const DropdownMenuItem(
                  value: 'Select Standard',
                  child: Text('Select Standard'),
                ),
                ..._standards
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
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
                const DropdownMenuItem(
                  value: 'Select Subject',
                  child: Text('Select Subject'),
                ),
                ..._subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
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
    return _selectedStandard != 'Select Standard' &&
        _selectedSubject != 'Select Subject';
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