import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/content_model.dart';
import 'content_viewer_screen.dart';

class AdminContentManagementScreen extends StatefulWidget {
  final Standard standard;
  final Board board;
  final ContentType contentType;
  final bool isEditMode;

  const AdminContentManagementScreen({
    super.key,
    required this.standard,
    required this.board,
    required this.contentType,
    required this.isEditMode,
  });

  @override
  State<AdminContentManagementScreen> createState() =>
      _AdminContentManagementScreenState();
}

class _AdminContentManagementScreenState
    extends State<AdminContentManagementScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _chapterNumberController = TextEditingController();
  final _chapterNameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _totalMarksController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final _instructionsController = TextEditingController();

  DateTime? _dueDate;
  String _selectedSubject = 'Mathematics';
  String? _selectedFileName;
  String? _selectedFilePath;
  Uint8List? _selectedFileBytes;
  List<String> _tags = [];
  final _tagController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  List<Map<String, dynamic>> _contentList = [];
  bool _isLoadingContent = false;
  late TabController _tabController;

  // Results filtering
  String _selectedResultSubject = 'All Subjects';
  String _selectedResultStudent = 'All Students';
  List<String> _availableResultSubjects = [];
  List<String> _availableResultStudents = [];

  // MCQ specific fields
  List<Map<String, dynamic>> _mcqQuestions = [];
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _explanationController = TextEditingController();
  String _selectedCorrectAnswer = 'A';
  int _questionMarks = 1;

  Future<void> _debugAllTestResults() async {
    try {
      print('=== DEBUGGING ALL TEST RESULTS ===');
      final snapshot =
          await FirebaseFirestore.instance.collection('test_results').get();

      print('Total test results in database: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('Result ID: ${doc.id}');
        print('  Student: ${data['studentEmail']}');
        print('  Test Title: ${data['testTitle']}');
        print('  Test Standard: ${data['testStandard']}');
        print('  Test Board: ${data['testBoard']}');
        print('  Subject: ${data['subject']}');
        print('  Score: ${data['score']}/${data['totalMarks']}');
        print('  Submitted: ${data['submittedAt']}');
        print('---');
      }
      print('=== END DEBUG ===');
    } catch (e) {
      print('Error debugging test results: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _subjectController.text = 'Mathematics'; // Default subject
    _tabController = TabController(length: 2, vsync: this);
    if (widget.isEditMode) {
      _loadContent();
    }
    // Debug all test results on init
    _debugAllTestResults();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _chapterNumberController.dispose();
    _chapterNameController.dispose();
    _subjectController.dispose();
    _totalMarksController.dispose();
    _timeLimitController.dispose();
    _instructionsController.dispose();
    _tagController.dispose();
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _explanationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: Text(
          widget.isEditMode ? 'Manage Content' : 'Add New Content',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.isEditMode)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showAddContentDialog(),
            ),
        ],
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
            child:
                widget.isEditMode
                    ? _buildContentList()
                    : _buildAddContentForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
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
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Text(
                        widget.standard.standardDisplayName,
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Standard ${widget.standard.standardDisplayName} - ${widget.board.boardDisplayName}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            widget.contentType.typeDisplayName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showAddContentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Content'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Content List with Tabs
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
                        const Icon(Icons.list, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          'Content Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_contentList.length} items',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(15),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.green[700],
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: Colors.green[700],
                      tabs: const [
                        Tab(icon: Icon(Icons.list), text: 'Content'),
                        Tab(icon: Icon(Icons.analytics), text: 'Results'),
                      ],
                    ),
                  ),
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildContentTab(), _buildResultsTab()],
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

  Widget _buildAddContentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
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
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Text(
                          widget.standard.standardDisplayName,
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Standard ${widget.standard.standardDisplayName} - ${widget.board.boardDisplayName}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              widget.contentType.typeDisplayName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Fields
            _buildFormCard([
              _buildTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'Enter content title',
                validator:
                    (value) =>
                        value?.isEmpty == true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Enter content description',
                maxLines: 3,
                validator:
                    (value) =>
                        value?.isEmpty == true
                            ? 'Description is required'
                            : null,
              ),
            ]),

            _buildFormCard([
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _chapterNumberController,
                      label: 'Chapter Number',
                      hint: 'e.g., 1, 2, 3',
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value?.isEmpty == true
                                  ? 'Chapter number is required'
                                  : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _chapterNameController,
                      label: 'Chapter Name',
                      hint: 'e.g., Real Numbers',
                      validator:
                          (value) =>
                              value?.isEmpty == true
                                  ? 'Chapter name is required'
                                  : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSubjectDropdown(),
            ]),

            if (widget.contentType == ContentType.assignment) ...[
              _buildFormCard([
                _buildDateField(),
                const SizedBox(height: 16),
                _buildFilePicker(),
              ]),
            ],

            if (widget.contentType == ContentType.mcq ||
                widget.contentType == ContentType.descriptive) ...[
              _buildFormCard([
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _totalMarksController,
                        label: 'Total Marks',
                        hint: 'e.g., 100',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _timeLimitController,
                        label: 'Time Limit (minutes)',
                        hint: 'e.g., 60',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _instructionsController,
                  label: 'Instructions',
                  hint: 'Enter exam instructions',
                  maxLines: 3,
                ),
              ]),
            ],

            if (widget.contentType == ContentType.notes) ...[
              _buildFormCard([_buildFilePicker()]),
            ],

            if (widget.contentType == ContentType.descriptive) ...[
              _buildFormCard([_buildFilePicker()]),
            ],

            if (widget.contentType == ContentType.mcq) ...[
              _buildFormCard([_buildMCQQuestionForm()]),
            ],

            _buildFormCard([_buildTagsField()]),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.green[700]!),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _saveContent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        _isUploading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('Save Content'),
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

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
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
        children: children,
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSubject,
          decoration: InputDecoration(
            hintText: 'Select subject',
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
          items: const [
            DropdownMenuItem(value: 'Mathematics', child: Text('Mathematics')),
            DropdownMenuItem(value: 'Algebra', child: Text('Algebra')),
            DropdownMenuItem(value: 'Geometry', child: Text('Geometry')),
            DropdownMenuItem(value: 'CET', child: Text('CET')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedSubject = value!;
              _subjectController.text = value;
            });
          },
          validator:
              (value) => value?.isEmpty == true ? 'Subject is required' : null,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
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
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Due Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  _dueDate != null
                      ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                      : 'Select due date',
                  style: TextStyle(
                    color: _dueDate != null ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (_dueDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _dueDate = null),
                    child: Icon(Icons.clear, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload File',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(Icons.attach_file, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedFileName ?? 'Select PDF file',
                    style: TextStyle(
                      color:
                          _selectedFileName != null
                              ? Colors.black87
                              : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(Icons.upload_file, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
        if (_selectedFileName != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFileName!,
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap:
                      () => setState(() {
                        _selectedFileName = null;
                        _selectedFilePath = null;
                        _selectedFileBytes = null;
                      }),
                  child: Icon(Icons.clear, color: Colors.green[600], size: 20),
                ),
              ],
            ),
          ),
        ],
        if (_isUploading) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value:
                _uploadProgress > 0 && _uploadProgress < 1
                    ? _uploadProgress
                    : null,
          ),
          const SizedBox(height: 4),
          Text('${(_uploadProgress * 100).toStringAsFixed(0)}%'),
        ],
      ],
    );
  }

  Widget _buildMCQQuestionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MCQ Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addMCQQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Question input form
        _buildTextField(
          controller: _questionController,
          label: 'Question',
          hint: 'Enter the question',
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _optionAController,
                label: 'Option A',
                hint: 'Enter option A',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _optionBController,
                label: 'Option B',
                hint: 'Enter option B',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _optionCController,
                label: 'Option C',
                hint: 'Enter option C',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _optionDController,
                label: 'Option D',
                hint: 'Enter option D',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Correct Answer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCorrectAnswer,
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
                    items: const [
                      DropdownMenuItem(value: 'A', child: Text('A')),
                      DropdownMenuItem(value: 'B', child: Text('B')),
                      DropdownMenuItem(value: 'C', child: Text('C')),
                      DropdownMenuItem(value: 'D', child: Text('D')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCorrectAnswer = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: TextEditingController(
                  text: _questionMarks.toString(),
                ),
                label: 'Marks',
                hint: 'Enter marks',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value?.isEmpty == true) return 'Marks required';
                  final marks = int.tryParse(value!);
                  if (marks == null || marks <= 0) return 'Invalid marks';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: _explanationController,
          label: 'Explanation (Optional)',
          hint: 'Explain why this is the correct answer',
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Display added questions
        if (_mcqQuestions.isNotEmpty) ...[
          const Text(
            'Added Questions:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ..._mcqQuestions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Text('${index + 1}'),
                ),
                title: Text(
                  question['question'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Correct: ${question['correctAnswer']} | Marks: ${question['marks']}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeMCQQuestion(index),
                ),
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Add a tag',
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
                onSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _addTag(_tagController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                        backgroundColor: Colors.green[100],
                        labelStyle: TextStyle(color: Colors.green[700]),
                      ),
                    )
                    .toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFileName = file.name;
          _selectedFileBytes = file.bytes;
          // Only set path if it's available (not on web)
          _selectedFilePath = file.path;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selected: ${file.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error picking file: $e';

      // Provide more helpful error message for web users
      if (e.toString().contains('path') && e.toString().contains('web')) {
        errorMessage = 'File selected successfully! (Web platform detected)';
        // Still try to get the file info if possible
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          setState(() {
            _selectedFileName = file.name;
            _selectedFileBytes = file.bytes;
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor:
              errorMessage.contains('successfully') ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty && !_tags.contains(tag.trim())) {
      setState(() {
        _tags.add(tag.trim());
        _tagController.clear();
      });
    }
  }

  void _addMCQQuestion() {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_optionAController.text.trim().isEmpty ||
        _optionBController.text.trim().isEmpty ||
        _optionCController.text.trim().isEmpty ||
        _optionDController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all options'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _mcqQuestions.add({
        'question': _questionController.text.trim(),
        'options': {
          'A': _optionAController.text.trim(),
          'B': _optionBController.text.trim(),
          'C': _optionCController.text.trim(),
          'D': _optionDController.text.trim(),
        },
        'correctAnswer': _selectedCorrectAnswer,
        'marks': _questionMarks,
        'explanation': _explanationController.text.trim(),
      });

      // Clear form
      _questionController.clear();
      _optionAController.clear();
      _optionBController.clear();
      _optionCController.clear();
      _optionDController.clear();
      _explanationController.clear();
      _selectedCorrectAnswer = 'A';
      _questionMarks = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Question added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeMCQQuestion(int index) {
    setState(() {
      _mcqQuestions.removeAt(index);
    });
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoadingContent = true;
    });

    try {
      // Load content for this specific type, standard and board
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('content')
              .where('standard', isEqualTo: widget.standard.standardDisplayName)
              .where('type', isEqualTo: widget.contentType.name)
              .get();

      setState(() {
        _contentList =
            snapshot.docs
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return data;
                })
                .where((content) {
                  // Filter by board in code to avoid index requirement
                  return content['board'] == widget.board.boardDisplayName;
                })
                .toList()
              ..sort((a, b) {
                // Sort by upload date in code
                final aDate =
                    (a['uploadDate'] as Timestamp?)?.toDate() ?? DateTime(1970);
                final bDate =
                    (b['uploadDate'] as Timestamp?)?.toDate() ?? DateTime(1970);
                return bDate.compareTo(aDate);
              });

        _isLoadingContent = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingContent = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading content: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildContentCard(Map<String, dynamic> content) {
    final contentType = content['type'] as String? ?? '';
    IconData iconData;
    Color iconColor;

    switch (contentType) {
      case 'descriptive':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'assignment':
        iconData = Icons.assignment;
        iconColor = Colors.orange;
        break;
      case 'mcq':
        iconData = Icons.quiz;
        iconColor = Colors.purple;
        break;
      case 'notes':
        iconData = Icons.note;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.description;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(iconData, color: iconColor),
        title: Text(
          content['title'] ?? 'Untitled',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content['description'] ?? ''),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  contentType.toUpperCase(),
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.subject, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  content['subject'] ?? 'No subject',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                if (content['totalMarks'] != null) ...[
                  Icon(Icons.star, size: 16, color: Colors.amber[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${content['totalMarks']} marks',
                    style: TextStyle(color: Colors.amber[700], fontSize: 12),
                  ),
                ],
              ],
            ),
            if (content['fileName'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      content['fileName'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.blue),
              onPressed: () => _viewContent(content),
              tooltip: 'View Details',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _deleteContent(content['id']),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  void _deleteContent(String contentId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Content'),
            content: const Text(
              'Are you sure you want to delete this content?',
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
                        .collection('content')
                        .doc(contentId)
                        .delete();
                    _loadContent(); // Refresh the list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Content deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting content: $e'),
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

  void _viewContent(Map<String, dynamic> content) {
    final contentType = content['type'] as String? ?? '';

    if (contentType == 'descriptive' &&
        content['fileUrl'] != null &&
        content['fileUrl'].isNotEmpty) {
      // For descriptive exams with PDF files, open the content viewer
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => ContentViewerScreen(
                title: content['title'] ?? 'Descriptive Exam',
                fileUrl: content['fileUrl'],
                fileType: 'pdf',
              ),
        ),
      );
    } else if (contentType == 'mcq') {
      // For MCQ tests, show test details and allow taking the test
      _showMCQTestDetails(content);
    } else {
      // For other content types, show details dialog
      _showContentDetails(content);
    }
  }

  void _showContentDetails(Map<String, dynamic> content) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(content['title'] ?? 'Content Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Description: ${content['description'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Subject: ${content['subject'] ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Type: ${content['type'] ?? 'N/A'}'),
                  if (content['totalMarks'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Total Marks: ${content['totalMarks']}'),
                  ],
                  if (content['timeLimit'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Time Limit: ${content['timeLimit']} minutes'),
                  ],
                  if (content['fileName'] != null) ...[
                    const SizedBox(height: 8),
                    Text('File: ${content['fileName']}'),
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

  void _showMCQTestDetails(Map<String, dynamic> content) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.purple[700],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.quiz, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            content['title'] ?? 'MCQ Test Details',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Test Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      border: Border(
                        bottom: BorderSide(color: Colors.purple[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Subject: ${content['subject'] ?? 'N/A'}'),
                              const SizedBox(height: 4),
                              Text(
                                'Total Marks: ${content['totalMarks'] ?? 'N/A'}',
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time Limit: ${content['timeLimit'] ?? 'N/A'} minutes',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Questions: ${(content['questions'] as List).length}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Questions List
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test Questions:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (content['questions'] != null)
                            ...((content['questions'] as List)
                                .asMap()
                                .entries
                                .map((entry) {
                                  final index = entry.key;
                                  final question =
                                      entry.value as Map<String, dynamic>;
                                  return _buildQuestionCard(
                                    index + 1,
                                    question,
                                  );
                                })
                                .toList())
                          else
                            const Text('No questions available'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildQuestionCard(int questionNumber, Map<String, dynamic> question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question $questionNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (question['marks'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${question['marks']} marks',
                      style: TextStyle(
                        color: Colors.amber[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Question Text
            Text(
              question['question'] ?? 'No question text',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            // Options
            Text(
              'Options:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ...(['A', 'B', 'C', 'D'].map((option) {
              final optionKey = 'option$option';
              final optionText = question[optionKey] as String? ?? '';
              final correctAnswer = question['correctAnswer'] as String? ?? '';
              final isCorrect = correctAnswer == option;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green[50] : Colors.grey[50],
                  border: Border.all(
                    color: isCorrect ? Colors.green[300]! : Colors.grey[300]!,
                    width: isCorrect ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCorrect ? Colors.green[500] : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          option,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        optionText,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isCorrect ? Colors.green[800] : Colors.grey[800],
                          fontWeight:
                              isCorrect ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 20,
                      ),
                  ],
                ),
              );
            }).toList()),
            // Explanation
            if (question['explanation'] != null &&
                question['explanation'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: Colors.blue[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Explanation:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question['explanation'],
                      style: TextStyle(fontSize: 14, color: Colors.blue[800]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasValidFile() {
    // Check if we have either file bytes (web) or file path (mobile/desktop)
    return _selectedFileBytes != null || _selectedFilePath != null;
  }

  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if file is required and selected
    if ((widget.contentType == ContentType.assignment ||
            widget.contentType == ContentType.notes ||
            widget.contentType == ContentType.descriptive) &&
        !_hasValidFile()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.contentType == ContentType.descriptive
                ? 'Please select a PDF file for descriptive exam'
                : 'Please select a PDF file',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if MCQ questions are added
    if (widget.contentType == ContentType.mcq && _mcqQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one MCQ question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      String? downloadUrl;
      String? filePath;

      // Upload file to Firebase Storage if file is selected
      if (_hasValidFile() && _selectedFileBytes != null) {
        final String timePrefix =
            DateTime.now().millisecondsSinceEpoch.toString();
        final String safeName = _selectedFileName!.replaceAll("/", "_");

        // Determine storage path based on content type
        if (widget.contentType == ContentType.descriptive) {
          filePath =
              'descriptive_exams/${widget.standard.standardDisplayName}/${timePrefix}_${safeName}';
        } else {
          filePath = 'content/${timePrefix}_${safeName}';
        }

        final Reference storageRef = FirebaseStorage.instance.ref().child(
          filePath,
        );

        final SettableMetadata metadata = SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'uploadedBy': user.uid,
            'title': _titleController.text,
            'type': widget.contentType.name,
          },
        );

        final UploadTask task = storageRef.putData(
          _selectedFileBytes!,
          metadata,
        );
        task.snapshotEvents.listen((TaskSnapshot snap) {
          if (snap.totalBytes > 0) {
            setState(() {
              _uploadProgress = snap.bytesTransferred / snap.totalBytes;
            });
          }
        });

        final TaskSnapshot snapshot = await task;
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      // Save content metadata to Firestore
      final contentData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'type': widget.contentType.name,
        'fileUrl': downloadUrl ?? '',
        'filePath': filePath ?? '',
        'fileName': _selectedFileName ?? '',
        'fileType': 'pdf',
        'fileSize': _selectedFileBytes?.length ?? 0,
        'uploadDate': Timestamp.now(),
        'uploadedBy': user.uid,
        'targetCourses': ['Basic Mathematics'], // Default course
        'targetStandards': [widget.standard.standardDisplayName],
        'subject': _selectedSubject,
        'isActive': true,
        'dueDate':
            widget.contentType == ContentType.assignment && _dueDate != null
                ? Timestamp.fromDate(_dueDate!)
                : null,
        'isWebFile': kIsWeb,
        'isDescriptiveExam': widget.contentType == ContentType.descriptive,
        'standard': widget.standard.standardDisplayName,
        'board': widget.board.boardDisplayName,
        'chapterNumber': _chapterNumberController.text,
        'chapterName': _chapterNameController.text,
        'tags': _tags,
        'totalMarks':
            _totalMarksController.text.isNotEmpty
                ? int.tryParse(_totalMarksController.text)
                : _mcqQuestions.isNotEmpty
                ? _mcqQuestions.fold(0, (sum, q) => sum + (q['marks'] as int))
                : null,
        'timeLimit':
            _timeLimitController.text.isNotEmpty
                ? int.tryParse(_timeLimitController.text)
                : null,
        'instructions':
            _instructionsController.text.isNotEmpty
                ? _instructionsController.text
                : null,
        'questions': _mcqQuestions,
      };

      await FirebaseFirestore.instance.collection('content').add(contentData);

      // Reset form
      _titleController.clear();
      _descriptionController.clear();
      _chapterNumberController.clear();
      _chapterNameController.clear();
      _totalMarksController.clear();
      _timeLimitController.clear();
      _instructionsController.clear();
      _tagController.clear();
      _questionController.clear();
      _optionAController.clear();
      _optionBController.clear();
      _optionCController.clear();
      _optionDController.clear();
      _explanationController.clear();
      setState(() {
        _dueDate = null;
        _selectedFileName = null;
        _selectedFilePath = null;
        _selectedFileBytes = null;
        _tags.clear();
        _mcqQuestions.clear();
        _selectedCorrectAnswer = 'A';
        _questionMarks = 1;
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to content list
      Navigator.of(context).pop();

      // Refresh content list if in edit mode
      if (widget.isEditMode) {
        _loadContent();
      }
    } catch (e) {
      String errorMessage = 'Error saving content: $e';

      // Provide more helpful error messages
      if (e.toString().contains('CORS')) {
        errorMessage =
            'CORS Error: Configure Firebase Storage CORS (see FIREBASE_STORAGE_CORS_SETUP.md).';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission Error: Check Firebase Storage rules.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network Error: Check your internet connection.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _showAddContentDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => AdminContentManagementScreen(
              standard: widget.standard,
              board: widget.board,
              contentType: widget.contentType,
              isEditMode: false,
            ),
      ),
    );
  }

  Widget _buildContentTab() {
    return _isLoadingContent
        ? const Center(child: CircularProgressIndicator())
        : _contentList.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No content found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first ${widget.contentType.typeDisplayName.toLowerCase()}',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        )
        : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _contentList.length,
          itemBuilder: (context, index) {
            final content = _contentList[index];
            return _buildContentCard(content);
          },
        );
  }

  Widget _buildResultsTab() {
    if (widget.contentType != ContentType.mcq) {
      return const Center(
        child: Text(
          'Results are only available for MCQ tests',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Filter controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Force refresh by rebuilding the widget
                  setState(() {});
                },
                tooltip: 'Refresh Results',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.bug_report),
                onPressed: () {
                  _debugAllTestResults();
                },
                tooltip: 'Debug All Results',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedResultSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items:
                      ['All Subjects', ..._availableResultSubjects].map((
                        subject,
                      ) {
                        return DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedResultSubject = value ?? 'All Subjects';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedResultStudent,
                  decoration: const InputDecoration(
                    labelText: 'Student',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items:
                      ['All Students', ..._availableResultStudents].map((
                        student,
                      ) {
                        return DropdownMenuItem(
                          value: student,
                          child: Text(student),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedResultStudent = value ?? 'All Students';
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Results list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('test_results')
                    .where(
                      'testStandard',
                      isEqualTo: widget.standard.standardDisplayName,
                    )
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No test results found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Results will appear here once students take the tests',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final allResults =
                  snapshot.data!.docs
                      .map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        data['id'] = doc.id;
                        return data;
                      })
                      .where((result) {
                        // Filter by board in code to avoid index requirement
                        return result['testBoard'] ==
                            widget.board.boardDisplayName;
                      })
                      .toList();

              // Debug: Check if there are any results at all
              print(
                'Total results in test_results collection: ${snapshot.data!.docs.length}',
              );

              // Debug: Print results count and details
              print(
                'Admin Results Tab - Found ${allResults.length} results for ${widget.standard.standardDisplayName} - ${widget.board.boardDisplayName}',
              );
              print(
                'Filtering by testStandard: ${widget.standard.standardDisplayName}',
              );
              print('Filtering by testBoard: ${widget.board.boardDisplayName}');

              // Debug: Print all raw results before filtering
              print('Raw results from Firestore:');
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                print(
                  '  - Student: ${data['studentEmail']}, TestStandard: ${data['testStandard']}, TestBoard: ${data['testBoard']}',
                );
              }

              // Show notification if new results are available
              if (allResults.isNotEmpty) {
                final latestResult = allResults.first;
                final submittedAt =
                    (latestResult['submittedAt'] as Timestamp?)?.toDate();
                if (submittedAt != null &&
                    submittedAt.isAfter(
                      DateTime.now().subtract(const Duration(minutes: 5)),
                    )) {
                  // Show a subtle notification for recent results
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'New test result from ${latestResult['studentEmail']}',
                        ),
                        backgroundColor: Colors.blue,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  });
                }
              }

              // Populate filter options
              _populateFilterOptions(allResults);

              // Apply filters
              final results =
                  allResults.where((result) {
                      bool subjectMatch =
                          _selectedResultSubject == 'All Subjects' ||
                          result['subject'] == _selectedResultSubject;
                      bool studentMatch =
                          _selectedResultStudent == 'All Students' ||
                          result['studentEmail'] == _selectedResultStudent;
                      return subjectMatch && studentMatch;
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

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  return _buildResultCard(results[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _populateFilterOptions(List<Map<String, dynamic>> results) {
    // Get unique subjects
    final subjects =
        results
            .map((result) => result['subject'] as String? ?? '')
            .toSet()
            .toList();
    subjects.removeWhere((subject) => subject.isEmpty);
    _availableResultSubjects = subjects;

    // Get unique students
    final students =
        results
            .map((result) => result['studentEmail'] as String? ?? '')
            .toSet()
            .toList();
    students.removeWhere((student) => student.isEmpty);
    _availableResultStudents = students;
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
          (context) => Dialog(
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Test Result Details',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Student Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border(
                        bottom: BorderSide(color: Colors.blue[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student: ${result['studentEmail'] ?? 'Unknown'}',
                              ),
                              const SizedBox(height: 4),
                              Text('Test: ${result['testTitle'] ?? 'Unknown'}'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Score: ${result['score']}/${result['totalMarks']} (${result['percentage']}%)',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Time Taken: ${result['timeTaken']} minutes',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Questions and Answers
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student Answers:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (result['answers'] != null)
                            ...((result['answers'] as Map<String, dynamic>)
                                .entries
                                .map((entry) {
                                  final questionIndex = int.parse(entry.key);
                                  final userAnswer = entry.value as String;
                                  final explanation =
                                      result['explanations']?[entry.key]
                                          as String? ??
                                      '';

                                  return _buildAdminAnswerCard(
                                    questionIndex + 1,
                                    userAnswer,
                                    explanation,
                                  );
                                })
                                .toList())
                          else
                            const Text('No answer details available'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildAdminAnswerCard(
    int questionNumber,
    String userAnswer,
    String explanation,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question $questionNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Answer: $userAnswer',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Explanation
            if (explanation.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: Colors.green[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Explanation:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      explanation,
                      style: TextStyle(fontSize: 14, color: Colors.green[800]),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No explanation available for this question.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
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
