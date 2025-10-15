import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MCQTestScreen extends StatefulWidget {
  final Map<String, dynamic> testData;

  const MCQTestScreen({super.key, required this.testData});

  @override
  State<MCQTestScreen> createState() => _MCQTestScreenState();
}

class _MCQTestScreenState extends State<MCQTestScreen> {
  List<Map<String, dynamic>> _questions = [];
  Map<int, String> _userAnswers = {};
  bool _isLoading = true;
  bool _isSubmitted = false;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _totalMarks = 0;
  DateTime? _startTime;
  Duration? _timeRemaining;
  Timer? _timer;

  int _parseMarks(dynamic value, {int fallback = 1}) {
    if (value is int) return value;
    if (value is String) {
      final v = int.tryParse(value.trim());
      if (v != null) return v;
    }
    return fallback;
  }

  Future<void> _testFirebaseConnection() async {
    try {
      await FirebaseFirestore.instance
          .collection('test_results')
          .limit(1)
          .get();
    } catch (e) {
    }
  }

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection(); // Test Firebase connection first
    _loadTest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTest() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get questions from test data
      final questions = List<Map<String, dynamic>>.from(
        widget.testData['questions'] ?? [],
      );

      setState(() {
        _questions = questions;
        _totalMarks = questions.fold(
          0,
          (sum, q) => sum + _parseMarks(q['marks'], fallback: 1),
        );
        _isLoading = false;
        _startTime = DateTime.now();
      });

      // Start timer if time limit is set
      final timeLimit = widget.testData['timeLimit'] as int?;
      if (timeLimit != null) {
        _timeRemaining = Duration(minutes: timeLimit);
        _startTimer();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining != null && _timeRemaining!.inSeconds > 0) {
        setState(() {
          _timeRemaining = Duration(seconds: _timeRemaining!.inSeconds - 1);
        });
      } else {
        _timer?.cancel();
        _submitTest();
      }
    });
  }

  void _submitTest() {
    if (_isSubmitted) return;

    setState(() {
      _isSubmitted = true;
    });

    _timer?.cancel();

    // Calculate score
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final userAnswer = _userAnswers[i];
      final correctAnswer = question['correctAnswer'] as String?;

      if (userAnswer == correctAnswer) {
        score += _parseMarks(question['marks'], fallback: 1);
      }
    }

    setState(() {
      _score = score;
    });

    // Save result to Firestore
    _saveTestResult(score);
  }

  Future<void> _saveTestResult(int score) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      // Calculate percentage correctly
      final percentage =
          _totalMarks > 0 ? (score / _totalMarks * 100).round() : 0;

      // Collect explanations and complete question data for all questions
      Map<String, String> explanations = {};
      Map<String, Map<String, dynamic>> questionDetails = {};

      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final explanation = question['explanation'] as String?;
        if (explanation != null && explanation.isNotEmpty) {
          explanations[i.toString()] = explanation;
        }

        // Store complete question details for detailed result view
        questionDetails[i.toString()] = {
          'question': question['question'] ?? '',
          'options': question['options'] ?? {},
          'correctAnswer': question['correctAnswer'] ?? '',
          'marks': question['marks'] ?? 0,
          'explanation': question['explanation'] ?? '',
        };
      }

      // Convert integer keys to strings for Firestore compatibility
      Map<String, String> answersForFirestore = {};
      _userAnswers.forEach((key, value) {
        answersForFirestore[key.toString()] = value;
      });

      // Ensure all fields are properly typed
      final resultData = {
        'testId': widget.testData['id']?.toString() ?? '',
        'testTitle': widget.testData['title']?.toString() ?? '',
        'studentId': user.uid,
        'studentEmail': user.email ?? '',
        'testType': 'MCQ',
        'score': score,
        'totalMarks': _totalMarks,
        'percentage': percentage,
        'answers': answersForFirestore,
        'explanations': explanations,
        'questionDetails':
            questionDetails, // Complete question data for detailed view
        'submittedAt': Timestamp.now(),
        'publishedAt': Timestamp.now(),
        'timeTaken': DateTime.now().difference(_startTime!).inMinutes,
        'standard': widget.testData['standard']?.toString() ?? '',
        'testStandard': widget.testData['standard']?.toString() ?? '',
        'board': widget.testData['board']?.toString() ?? '',
        'testBoard': widget.testData['board']?.toString() ?? '',
        'subject': widget.testData['subject']?.toString() ?? '',
      };

      await FirebaseFirestore.instance
          .collection('test_results')
          .add(resultData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test submitted successfully! Your results are now visible in "My Results" tab.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving result: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isSubmitted) {
      return _buildResultScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testData['title'] ?? 'MCQ Test'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          if (_timeRemaining != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Text(
                  '${_timeRemaining!.inMinutes}:${(_timeRemaining!.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
          ),

          // Question counter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_parseMarks(_questions[_currentQuestionIndex]['marks'], fallback: 1)} marks',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.amber[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Question content
          Expanded(child: _buildQuestionCard()),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed:
                      _currentQuestionIndex > 0 ? _previousQuestion : null,
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _currentQuestionIndex == _questions.length - 1
                        ? 'Submit'
                        : 'Next',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    if (_questions.isEmpty)
      return const Center(child: Text('No questions available'));

    final question = _questions[_currentQuestionIndex];
    final options = question['options'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question['question'] ?? 'No question text',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Options
            ...options.entries.map((entry) {
              final optionKey = entry.key;
              final optionText = entry.value as String;
              final isSelected =
                  _userAnswers[_currentQuestionIndex] == optionKey;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: isSelected ? 3 : 1,
                  color: isSelected ? Colors.green[50] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color:
                          isSelected ? Colors.green[300]! : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _userAnswers[_currentQuestionIndex] = optionKey;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Option Label (A, B, C, D)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? Colors.green[600]
                                      : Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                optionKey,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Option Text
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                color:
                                    isSelected
                                        ? Colors.green[800]
                                        : Colors.black87,
                              ),
                            ),
                          ),
                          // Radio Button
                          Radio<String>(
                            value: optionKey,
                            groupValue: _userAnswers[_currentQuestionIndex],
                            onChanged: (value) {
                              setState(() {
                                _userAnswers[_currentQuestionIndex] = value!;
                              });
                            },
                            activeColor: Colors.green[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = _totalMarks > 0 ? (_score / _totalMarks * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      percentage >= 70 ? Icons.celebration : Icons.school,
                      size: 80,
                      color: percentage >= 70 ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      percentage >= 70 ? 'Congratulations!' : 'Good Try!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 10),
                    Text(
                      'Your Score: $_score / $_totalMarks',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Percentage: $percentage%',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 30),
                    if (_questions.isNotEmpty) ...[
                      const Text(
                        'Answer Explanations:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          final question = _questions[index];
                          final userAnswer = _userAnswers[index];
                          final correctAnswer = question['correctAnswer'] as String?;
                          final isCorrect = userAnswer == correctAnswer;
                          final explanation = question['explanation'] as String?;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isCorrect ? Colors.green[50] : Colors.red[50],
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCorrect ? Colors.green : Colors.red,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                'Your answer: ${userAnswer ?? 'Not answered'}',
                                style: TextStyle(
                                  color: isCorrect ? Colors.green[700] : Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Correct answer: $correctAnswer'),
                                  if (explanation != null && explanation.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Explanation: $explanation',
                                      style: const TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitTest();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }
}
