import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMCQResultsScreen extends StatefulWidget {
  const AdminMCQResultsScreen({super.key});

  @override
  State<AdminMCQResultsScreen> createState() => _AdminMCQResultsScreenState();
}

class _AdminMCQResultsScreenState extends State<AdminMCQResultsScreen> {
  String _selectedTest = 'All Tests';
  List<String> _testTitles = ['All Tests'];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTestTitles();
    _loadResults();
  }

  Future<void> _loadTestTitles() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('content')
              .where('type', isEqualTo: 'mcq')
              .get();

      setState(() {
        _testTitles =
            ['All Tests'] +
            snapshot.docs.map((doc) => doc.data()['title'] as String).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance.collection('test_results');

      if (_selectedTest != 'All Tests') {
        query = query.where('testTitle', isEqualTo: _selectedTest);
      }

      final snapshot = await query.get();

      setState(() {
        _results =
            snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              }).toList()
              ..sort((a, b) {
                // Sort by submission date in code
                final aDate =
                    (a['submittedAt'] as Timestamp?)?.toDate() ??
                    DateTime(1970);
                final bDate =
                    (b['submittedAt'] as Timestamp?)?.toDate() ??
                    DateTime(1970);
                return bDate.compareTo(aDate);
              });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading results: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'MCQ Test Results',
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
                children: [
                  // Filter Section
                  Container(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filter by Test',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedTest,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.green[700]!),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items:
                              _testTitles.map((title) {
                                return DropdownMenuItem(
                                  value: title,
                                  child: Text(title),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTest = value!;
                            });
                            _loadResults();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Results Section
                  Expanded(
                    child: Container(
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
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[700],
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.analytics,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Test Results',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_results.length} results',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child:
                                _isLoading
                                    ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                    : _results.isEmpty
                                    ? const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.quiz,
                                            size: 80,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No results found',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _results.length,
                                      itemBuilder: (context, index) {
                                        return _buildResultCard(
                                          _results[index],
                                        );
                                      },
                                    ),
                          ),
                        ],
                      ),
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

  Widget _buildResultCard(Map<String, dynamic> result) {
    final score = result['score'] as int? ?? 0;
    final totalMarks = result['totalMarks'] as int? ?? 1;
    final percentage = result['percentage'] as int? ?? 0;
    final submittedAt =
        (result['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final timeTaken = result['timeTaken'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getScoreColor(percentage),
          child: Text(
            '$percentage%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          result['studentEmail'] ?? 'Unknown Student',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test: ${result['testTitle'] ?? 'Unknown Test'}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber[600]),
                const SizedBox(width: 4),
                Text('$score/$totalMarks marks'),
                const SizedBox(width: 16),
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${timeTaken} min'),
                const SizedBox(width: 16),
                Icon(Icons.school, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(result['standard'] ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Submitted: ${_formatDate(submittedAt)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              _viewDetailedResult(result);
            } else if (value == 'delete') {
              _deleteResult(result['id']);
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _viewDetailedResult(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Test Result Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Student: ${result['studentEmail'] ?? 'Unknown'}'),
                  const SizedBox(height: 8),
                  Text('Test: ${result['testTitle'] ?? 'Unknown'}'),
                  const SizedBox(height: 8),
                  Text(
                    'Score: ${result['score']}/${result['totalMarks']} (${result['percentage']}%)',
                  ),
                  const SizedBox(height: 8),
                  Text('Time Taken: ${result['timeTaken']} minutes'),
                  const SizedBox(height: 8),
                  Text('Standard: ${result['standard'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Subject: ${result['subject'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text(
                    'Submitted: ${_formatDate((result['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now())}',
                  ),

                  if (result['answers'] != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Answers:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...(result['answers'] as Map<String, dynamic>).entries.map((
                      entry,
                    ) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Q${int.parse(entry.key) + 1}: ${entry.value}',
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _deleteResult(String resultId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Result'),
            content: const Text(
              'Are you sure you want to delete this test result?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await FirebaseFirestore.instance
                        .collection('test_results')
                        .doc(resultId)
                        .delete();
                    _loadResults();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Result deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting result: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}