import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/content_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  State<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  int _selectedIndex = 0;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();

  String _selectedType = 'note';
  List<String> _selectedCourses = [];
  List<String> _selectedStandards = [];
  String? _selectedSubject;
  DateTime? _selectedDueDate;
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final List<String> _availableCourses = [
    'Basic Mathematics',
    'Advanced Mathematics',
    'Competitive Mathematics',
    'JEE Preparation',
    'NEET Preparation',
  ];

  final List<String> _availableStandards = const [
    '8th',
    '9th',
    '10th',
    '11th',
    '12th',
  ];
  final List<String> _availableSubjects = const [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'Content Management',
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
            child: Column(
              children: [
                // Tab Bar
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildTabButton('Upload Content', 0)),
                      Expanded(child: _buildTabButton('Manage Content', 1)),
                    ],
                  ),
                ),

                // Content based on selected tab
                Expanded(
                  child:
                      _selectedIndex == 0
                          ? _buildUploadForm()
                          : _buildContentList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[700] : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildUploadForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upload New Content',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Web platform info
              if (kIsWeb)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'On web, Storage needs proper CORS. See FIREBASE_STORAGE_CORS_SETUP.md.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              if (kIsWeb) const SizedBox(height: 16),

              // Content Type Selection
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Content Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'note', child: Text('Note')),
                  DropdownMenuItem(
                    value: 'assignment',
                    child: Text('Assignment'),
                  ),
                  DropdownMenuItem(
                    value: 'descriptive',
                    child: Text('Descriptive Exam'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select content type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Subject
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.menu_book),
                ),
                items:
                    _availableSubjects
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (value) => setState(() => _selectedSubject = value),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please select subject';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Target Standards (Classes)
              const Text(
                'Target Standards (Classes):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    _availableStandards.map((std) {
                      final isSelected = _selectedStandards.contains(std);
                      return FilterChip(
                        label: Text(std),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedStandards.add(std);
                            } else {
                              _selectedStandards.remove(std);
                            }
                          });
                        },
                        selectedColor: Colors.green[100],
                        checkmarkColor: Colors.green[700],
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Target Courses
              const Text(
                'Target Courses:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    _availableCourses.map((course) {
                      final isSelected = _selectedCourses.contains(course);
                      return FilterChip(
                        label: Text(course),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCourses.add(course);
                            } else {
                              _selectedCourses.remove(course);
                            }
                          });
                        },
                        selectedColor: Colors.green[100],
                        checkmarkColor: Colors.green[700],
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Due Date (for assignments)
              if (_selectedType == 'assignment') ...[
                TextFormField(
                  controller: _dueDateController,
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDueDate = date;
                        _dueDateController.text =
                            '${date.day}/${date.month}/${date.year}';
                      });
                    }
                  },
                  validator: (value) {
                    if (_selectedType == 'assignment' &&
                        (value == null || value.isEmpty)) {
                      return 'Please select due date for assignment';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // File Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedType == 'descriptive'
                          ? Icons.picture_as_pdf
                          : Icons.upload_file,
                      size: 48,
                      color:
                          _selectedType == 'descriptive'
                              ? Colors.red
                              : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFile != null
                          ? 'Selected: ${_selectedFile!.name}'
                          : _selectedType == 'descriptive'
                          ? 'No PDF file selected'
                          : 'No file selected',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (_selectedType == 'descriptive') ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Only PDF files are allowed for descriptive exams',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickFile,
                      icon: Icon(
                        _selectedType == 'descriptive'
                            ? Icons.picture_as_pdf
                            : Icons.file_upload,
                      ),
                      label: Text(
                        _selectedType == 'descriptive'
                            ? 'Select PDF File'
                            : 'Select File',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _selectedType == 'descriptive'
                                ? Colors.red[700]
                                : Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Upload Button
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadContent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Upload Content',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('content').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No content uploaded yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        // Sort documents by upload date
        final sortedDocs =
            snapshot.data!.docs.toList()..sort((a, b) {
              final aDate =
                  (a.data() as Map<String, dynamic>)['uploadDate']
                      as Timestamp?;
              final bDate =
                  (b.data() as Map<String, dynamic>)['uploadDate']
                      as Timestamp?;
              final aDateTime = aDate?.toDate() ?? DateTime(1970);
              final bDateTime = bDate?.toDate() ?? DateTime(1970);
              return bDateTime.compareTo(aDateTime);
            });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];
            final content = ContentItem.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: Icon(
                  content.type == 'note'
                      ? Icons.note
                      : content.type == 'assignment'
                      ? Icons.assignment
                      : Icons.picture_as_pdf,
                  color:
                      content.type == 'note'
                          ? Colors.blue
                          : content.type == 'assignment'
                          ? Colors.orange
                          : Colors.red,
                ),
                title: Text(
                  content.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Type: ${content.type == 'descriptive' ? 'Descriptive Exam' : content.type}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Courses: ${content.targetCourses.join(", ")}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Standards: ${content.targetStandards.join(", ")}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (content.dueDate != null)
                      Text(
                        'Due: ${content.dueDate!.day}/${content.dueDate!.month}/${content.dueDate!.year}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: PopupMenuButton<String>(
                    onSelected: (value) => _handleContentAction(value, content),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 8),
                            Text('Toggle Visibility'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickFile() async {
    try {
      FileType fileType = FileType.any;
      List<String>? allowedExtensions;

      // For descriptive exams, only allow PDF files
      if (_selectedType == 'descriptive') {
        fileType = FileType.custom;
        allowedExtensions = ['pdf'];
      }

      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: false,
          withData: true,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });

        // Show success message for PDF files
        if (_selectedType == 'descriptive' &&
            _selectedFile!.extension?.toLowerCase() == 'pdf') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF file selected: ${_selectedFile!.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _uploadContent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null || _selectedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedType == 'descriptive'
                ? 'Please select a PDF file for descriptive exam'
                : 'Please select a file',
          ),
        ),
      );
      return;
    }

    // Validate PDF file for descriptive exams
    if (_selectedType == 'descriptive' &&
        _selectedFile!.extension?.toLowerCase() != 'pdf') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only PDF files are allowed for descriptive exams'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one target course'),
        ),
      );
      return;
    }
    if (_selectedStandards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one target standard'),
        ),
      );
      return;
    }
    if (_selectedSubject == null || _selectedSubject!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a subject')));
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final String timePrefix =
          DateTime.now().millisecondsSinceEpoch.toString();
      final String safeName = _selectedFile!.name.replaceAll("/", "_");
      final String path =
          _selectedType == 'descriptive'
              ? 'descriptive_exams/${_selectedStandards.first}/${timePrefix}_${safeName}'
              : 'content/${timePrefix}_${safeName}';
      final Reference storageRef = FirebaseStorage.instance.ref().child(path);

      final SettableMetadata metadata = SettableMetadata(
        contentType:
            _selectedFile!.extension != null
                ? _mimeFromExtension(_selectedFile!.extension!)
                : null,
        customMetadata: {
          'uploadedBy': user.uid,
          'title': _titleController.text,
          'type': _selectedType,
        },
      );

      final UploadTask task = storageRef.putData(
        _selectedFile!.bytes!,
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
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Save content metadata to Firestore
      final contentData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'type': _selectedType,
        'fileUrl': downloadUrl,
        'filePath': path,
        'fileName': _selectedFile!.name,
        'fileType': _selectedFile!.extension ?? '',
        'fileSize': _selectedFile!.size,
        'uploadDate': Timestamp.now(),
        'uploadedBy': user.uid,
        'targetCourses': _selectedCourses,
        'targetStandards': _selectedStandards,
        'subject': _selectedSubject,
        'isActive': true,
        'dueDate':
            _selectedType == 'assignment' && _selectedDueDate != null
                ? Timestamp.fromDate(_selectedDueDate!)
                : null,
        'isWebFile': kIsWeb,
        'isDescriptiveExam': _selectedType == 'descriptive',
        'standard':
            _selectedStandards.isNotEmpty ? _selectedStandards.first : null,
      };

      await FirebaseFirestore.instance.collection('content').add(contentData);

      // Reset form
      _formKey.currentState!.reset();
      _titleController.clear();
      _descriptionController.clear();
      _dueDateController.clear();
      setState(() {
        _selectedFile = null;
        _selectedCourses.clear();
        _selectedStandards.clear();
        _selectedDueDate = null;
        _selectedType = 'note';
        _selectedSubject = null;
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      String errorMessage = 'Error uploading content: $e';

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

  String? _mimeFromExtension(String ext) {
    final String lower = ext.toLowerCase();
    switch (lower) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'txt':
        return 'text/plain';
      default:
        return null;
    }
  }

  void _handleContentAction(String action, ContentItem content) {
    switch (action) {
      case 'toggle':
        FirebaseFirestore.instance.collection('content').doc(content.id).update(
          {'isActive': !content.isActive},
        );
        break;
      case 'delete':
        _showDeleteConfirmation(content);
        break;
    }
  }

  void _showDeleteConfirmation(ContentItem content) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Content'),
            content: Text(
              'Are you sure you want to delete "${content.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    // Attempt Storage deletion first if path exists
                    final DocumentReference ref = FirebaseFirestore.instance
                        .collection('content')
                        .doc(content.id);
                    final DocumentSnapshot snap = await ref.get();
                    final data = snap.data() as Map<String, dynamic>?;
                    final String? filePath =
                        data != null ? data['filePath'] as String? : null;
                    if (filePath != null && filePath.isNotEmpty) {
                      await FirebaseStorage.instance
                          .ref()
                          .child(filePath)
                          .delete();
                    }
                    await ref.delete();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Content deleted')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete: $e')),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
