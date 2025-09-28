import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_model.dart';
import '../services/feedback_service.dart';
import 'content_viewer_screen.dart';
import 'mcq_test_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  Map<String, dynamic>? _enrollmentData;
  bool _isLoading = true;
  String _selectedResultType =
      'All Results'; // For filtering MCQ vs Descriptive

  @override
  void initState() {
    super.initState();
    _loadEnrollmentData();
  }

  Future<void> _loadEnrollmentData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Find the approved enrollment for this user
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('enrollments')
                .where('parentUid', isEqualTo: user.uid)
                .where('status', isEqualTo: 'approved')
                .limit(1)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            _enrollmentData = querySnapshot.docs.first.data();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'Student Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/explore-more');
              }
            },
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
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _enrollmentData == null
                    ? _buildNoEnrollmentView()
                    : _buildDashboardContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEnrollmentView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/utkarsh_logo.jpg', height: 120, width: 120),
            const SizedBox(height: 24),
            const Text(
              'No Approved Enrollment Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your enrollment is still under review. Please wait for admin approval.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/explore-more');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Section
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
                Image.asset('assets/utkarsh_logo.jpg', height: 80, width: 80),
                const SizedBox(height: 16),
                Text(
                  'Welcome, ${_enrollmentData!['studentName']}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Course: ${_enrollmentData!['course']}',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Enrollment Approved ✓',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Actions Section
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
                Row(
                  children: [
                    const Icon(Icons.flash_on, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openNotesForEnrolledClass(context),
                        icon: const Icon(Icons.book),
                        label: const Text('Materials'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openAssignmentsForEnrolledClass(context),
                        icon: const Icon(Icons.assignment),
                        label: const Text('Assignments'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDescriptiveExams(context),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Descriptive Exams'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showMCQTests(context),
                        icon: const Icon(Icons.quiz),
                        label: const Text('MCQ Tests'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showMyResults(context),
                        icon: const Icon(Icons.analytics),
                        label: const Text('My Results'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showProgress(context),
                        icon: const Icon(Icons.trending_up),
                        label: const Text('Progress'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                 Row(
                 children: [
                    
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showOnlineClasses(context),
                        icon: const Icon(Icons.video_call),
                        label: const Text('Classes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showOnlineClasses(context),
                        icon: const Icon(Icons.video_call),
                        label: const Text('Contact Teacher'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showOnlineClasses(context),
                        icon: const Icon(Icons.video_call),
                        label: const Text('Branch Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),const SizedBox(width: 12),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Student Features Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildFeatureCard(
                  context,
                  'Course Materials',
                  Icons.book,
                  Colors.blue,
                  () => _openNotesForEnrolledClass(context),
                ),
                _buildFeatureCard(
                  context,
                  'Assignments',
                  Icons.assignment,
                  Colors.orange,
                  () => _openAssignmentsForEnrolledClass(context),
                ),
                _buildFeatureCard(
                  context,
                  'Descriptive Exams',
                  Icons.picture_as_pdf,
                  Colors.red,
                  () => _showDescriptiveExams(context),
                ),
                _buildFeatureCard(
                  context,
                  'MCQ Tests',
                  Icons.quiz,
                  Colors.purple,
                  () => _showMCQTests(context),
                ),
                _buildFeatureCard(
                  context,
                  'Progress Tracking',
                  Icons.trending_up,
                  Colors.purple,
                  () => _showProgress(context),
                ),
                _buildFeatureCard(
                  context,
                  'Online Classes',
                  Icons.video_call,
                  Colors.red,
                  () => _showOnlineClasses(context),
                ),
                _buildFeatureCard(
                  context,
                  'Study Schedule',
                  Icons.schedule,
                  Colors.teal,
                  () => _showStudySchedule(context),
                ),
                _buildFeatureCard(
                  context,
                  'Contact Teacher',
                  Icons.message,
                  Colors.indigo,
                  () => _showContactTeacher(context),
                ),
                _buildFeatureCard(
                  context,
                  'Submit Feedback',
                  Icons.feedback,
                  Colors.green,
                  () => _showSubmitFeedbackDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitFeedbackDialog(BuildContext context) {
    final msgCtl = TextEditingController();
    int rating = 5;
    bool seeded = false;
    final name = (_enrollmentData?['studentName'] ?? '').toString();
    final course = (_enrollmentData?['course'] ?? '').toString();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder(
              future: FeedbackService().getMyFeedback(),
              builder: (context, snap) {
                final existing = snap.data;
                if (!seeded && existing != null) {
                  rating = existing.rating;
                  msgCtl.text = existing.message;
                  seeded = true;
                }

                return AlertDialog(
                  title: Text(existing == null ? 'Submit Feedback' : 'Edit Feedback'),
                  content: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Student: $name'),
                        const SizedBox(height: 8),
                        Text('Course: $course'),
                        const SizedBox(height: 12),
                        const Text('Rating'),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(5, (index) {
                            final filled = index < rating;
                            return IconButton(
                              splashRadius: 20,
                              onPressed: () => setState(() => rating = index + 1),
                              icon: Icon(
                                filled ? Icons.star : Icons.star_border,
                                color: filled ? Colors.amber : Colors.grey,
                                size: 28,
                              ),
                            );
                          }),
                        ),
                        Text('$rating/5', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: msgCtl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Your feedback',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (snap.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (msgCtl.text.trim().isEmpty) return;
                        try {
                          await FeedbackService().submitFeedback(
                            message: msgCtl.text.trim(),
                            rating: rating,
                            studentName: name,
                            course: course,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(existing == null ? 'Feedback submitted.' : 'Feedback updated.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        }
                      },
                      child: Text(existing == null ? 'Submit' : 'Update'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCourseMaterials(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.book, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Course Materials',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('content')
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
                          child: Text(
                            'No course materials available yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      final items =
                          snapshot.data!.docs
                              .map(
                                (doc) => ContentItem.fromMap(
                                  doc.data() as Map<String, dynamic>,
                                  doc.id,
                                ),
                              )
                              .where(
                                (c) =>
                                    c.isActive && c.type == ContentType.notes,
                              )
                              .where((c) {
                                // For now, show all content since we don't have targetStandards in new model
                                // TODO: Implement proper filtering based on standard and board
                                return true;
                              })
                              .toList()
                            ..sort(
                              (a, b) => b.uploadDate.compareTo(a.uploadDate),
                            );

                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            'No course materials available yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder:
                            (context, index) =>
                                _buildMaterialCard(items[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMaterialCard(ContentItem content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(_getFileIcon(content.fileType), color: Colors.green),
        title: Text(content.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content.description),
            Text(
              '${content.fileType.toUpperCase()} • ${_formatFileSize(content.fileSize)}',
            ),
            Text('Uploaded: ${_formatDate(content.uploadDate)}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility),
          onPressed: () => _viewContent(content),
          tooltip: 'View Content',
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewContent(ContentItem content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ContentViewerScreen(
              title: content.title,
              fileUrl: content.fileUrl,
              fileType: content.fileType,
            ),
      ),
    );
  }

  void _showAssignments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.assignment,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Assignments',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('content')
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
                          child: Text(
                            'No assignments available yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      final items =
                          snapshot.data!.docs
                              .map(
                                (doc) => ContentItem.fromMap(
                                  doc.data() as Map<String, dynamic>,
                                  doc.id,
                                ),
                              )
                              .where(
                                (c) =>
                                    c.isActive &&
                                    c.type == ContentType.assignment,
                              )
                              .where((c) {
                                // For now, show all content since we don't have targetStandards in new model
                                // TODO: Implement proper filtering based on standard and board
                                return true;
                              })
                              .toList()
                            ..sort(
                              (a, b) => b.uploadDate.compareTo(a.uploadDate),
                            );

                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            'No assignments available yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder:
                            (context, index) =>
                                _buildAssignmentCard(items[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _openAssignmentsForEnrolledClass(BuildContext context) {
    if (_enrollmentData == null) return;
    final course = (_enrollmentData!['course'] as String? ?? '').trim();
    final Standard standard =
        course == '12th' ? Standard.twelfth :
        course == '11th' ? Standard.eleventh :
        course == '10th' ? Standard.tenth :
        course == '9th' ? Standard.ninth :
        Standard.eighth;
    final Board board = (standard == Standard.eleventh || standard == Standard.twelfth)
        ? Board.hsc
        : Board.cbse;
    Navigator.pushNamed(context, '/student-assignments', arguments: {
      'standard': standard,
      'board': board,
    });
  }

  void _openNotesForEnrolledClass(BuildContext context) {
    if (_enrollmentData == null) return;
    final course = (_enrollmentData!['course'] as String? ?? '').trim();
    final Standard standard =
        course == '12th' ? Standard.twelfth :
        course == '11th' ? Standard.eleventh :
        course == '10th' ? Standard.tenth :
        course == '9th' ? Standard.ninth :
        Standard.eighth;
    final Board board = (standard == Standard.eleventh || standard == Standard.twelfth)
        ? Board.hsc
        : Board.cbse;
    Navigator.pushNamed(context, '/student-notes', arguments: {
      'standard': standard,
      'board': board,
    });
  }

  Widget _buildAssignmentCard(ContentItem content) {
    final isOverdue =
        content.dueDate != null && content.dueDate!.isBefore(DateTime.now());
    final status = isOverdue ? 'Overdue' : 'Not Submitted';
    final statusColor = isOverdue ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          isOverdue ? Icons.warning : Icons.pending,
          color: statusColor,
        ),
        title: Text(content.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content.description),
            if (content.dueDate != null)
              Text(
                'Due: ${_formatDate(content.dueDate!)}',
                style: TextStyle(
                  color: isOverdue ? Colors.red : Colors.grey[600],
                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            Text(
              '${content.fileType.toUpperCase()} • ${_formatFileSize(content.fileSize)}',
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _viewContent(content),
              tooltip: 'View Assignment',
            ),
          ],
        ),
        onTap: () => _viewContent(content),
      ),
    );
  }

  void _showProgress(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Progress Tracking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProgressItem('Chapter 1', 85),
                _buildProgressItem('Chapter 2', 60),
                _buildProgressItem('Chapter 3', 30),
                _buildProgressItem('Overall Progress', 58),
              ],
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

  Widget _buildProgressItem(String title, int percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(title), Text('$percentage%')],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 80
                  ? Colors.green
                  : percentage >= 60
                  ? Colors.orange
                  : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showOnlineClasses(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Online Classes feature coming soon!')),
    );
  }

  void _showStudySchedule(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Study Schedule feature coming soon!')),
    );
  }

  void _showContactTeacher(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact Teacher feature coming soon!')),
    );
  }

  void _showMCQTests(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.purple[700],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.quiz, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'MCQ Tests',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('content')
                            .where('type', isEqualTo: 'mcq')
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
                          child: Text(
                            'No MCQ tests available yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      // Get student's standard from enrollment data
                      final studentStandard =
                          _enrollmentData?['course'] as String? ?? '';

                      final items =
                          snapshot.data!.docs
                              .map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                data['id'] = doc.id;
                                return data;
                              })
                              .where((test) {
                                // Filter by student's standard and active status
                                final testStandard =
                                    test['standard'] as String? ?? '';
                                final targetStandards = List<String>.from(
                                  test['targetStandards'] ?? [],
                                );
                                final isActive =
                                    test['isActive'] as bool? ?? true;
                                return isActive &&
                                    (testStandard == studentStandard ||
                                        targetStandards.contains(
                                          studentStandard,
                                        ));
                              })
                              .toList()
                            ..sort((a, b) {
                              final aDate =
                                  (a['uploadDate'] as Timestamp?)?.toDate() ??
                                  DateTime(1970);
                              final bDate =
                                  (b['uploadDate'] as Timestamp?)?.toDate() ??
                                  DateTime(1970);
                              return bDate.compareTo(aDate);
                            });

                      if (items.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.quiz,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No MCQ tests available for your standard',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Standard: $studentStandard',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder:
                            (context, index) => _buildMCQTestCard(items[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMCQTestCard(Map<String, dynamic> test) {
    final questions = List<Map<String, dynamic>>.from(test['questions'] ?? []);
    final totalMarks = questions.fold(
      0,
      (sum, q) => sum + (q['marks'] as int? ?? 0),
    );
    final timeLimit = test['timeLimit'] as int?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.quiz, color: Colors.purple[700], size: 32),
        title: Text(
          test['title'] ?? 'Untitled Test',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(test['description'] ?? ''),
            const SizedBox(height: 4),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${questions.length} questions',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$totalMarks marks',
                      style: TextStyle(color: Colors.amber[700], fontSize: 12),
                    ),
                  ],
                ),
                if (timeLimit != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${timeLimit} min',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Subject: ${test['subject'] ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            Text(
              'Uploaded: ${_formatDate((test['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now())}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _startMCQTest(test),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Start Test'),
        ),
      ),
    );
  }

  void _startMCQTest(Map<String, dynamic> test) {
    Navigator.of(context).pop(); // Close the bottom sheet
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => MCQTestScreen(testData: test)),
    );
  }

  void _showDescriptiveExams(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Descriptive Exams',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('content')
                            .where('isDescriptiveExam', isEqualTo: true)
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
                          child: Text(
                            'No descriptive exams available yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      // Get student's standard from enrollment data
                      final studentStandard =
                          _enrollmentData?['course'] as String? ?? '';

                      final items =
                          snapshot.data!.docs
                              .map(
                                (doc) => ContentItem.fromMap(
                                  doc.data() as Map<String, dynamic>,
                                  doc.id,
                                ),
                              )
                              .where((c) {
                                // Filter by student's standard and active status - only show exams for their standard
                                final examStandard =
                                    c.standard.standardDisplayName;
                                return c.isActive &&
                                    (examStandard == studentStandard ||
                                        c.targetStandards.contains(
                                          studentStandard,
                                        ));
                              })
                              .toList()
                            ..sort(
                              (a, b) => b.uploadDate.compareTo(a.uploadDate),
                            );

                      if (items.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No descriptive exams available for your standard',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Standard: $studentStandard',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder:
                            (context, index) =>
                                _buildDescriptiveExamCard(items[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDescriptiveExamCard(ContentItem content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.picture_as_pdf, color: Colors.red[700], size: 32),
        title: Text(
          content.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content.description),
            const SizedBox(height: 4),
            Text(
              'PDF • ${_formatFileSize(content.fileSize)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              'Uploaded: ${_formatDate(content.uploadDate)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            if (content.targetStandards.isNotEmpty)
              Text(
                'For: ${content.targetStandards.join(", ")}',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility),
          onPressed: () => _viewContent(content),
          tooltip: 'View PDF Exam',
        ),
        onTap: () => _viewContent(content),
      ),
    );
  }

  void _showMyResults(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'My Test Results',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () {
                          // Force refresh by rebuilding the widget
                          setState(() {});
                        },
                        tooltip: 'Refresh Results',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Filter Dropdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text(
                        'Filter by:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedResultType,
                          decoration: const InputDecoration(
                            labelText: 'Result Type',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'All Results',
                              child: Text('All Results'),
                            ),
                            DropdownMenuItem(
                              value: 'MCQ',
                              child: Text('MCQ Tests'),
                            ),
                            DropdownMenuItem(
                              value: 'Descriptive',
                              child: Text('Descriptive Exams'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedResultType = value ?? 'All Results';
                              // Force immediate rebuild of the StreamBuilder
                              // by triggering a rebuild of the parent widget
                            });
                            // Close and reopen the bottom sheet to apply filter immediately
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                              // Small delay to ensure smooth transition
                              Future.delayed(const Duration(milliseconds: 100), () {
                                _showMyResults(context);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('test_results')
                            .where(
                              'studentEmail',
                              isEqualTo: _enrollmentData?['email'],
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
                              Icon(
                                Icons.analytics,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No test results found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Take some MCQ tests to see your results here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final allResults =
                          snapshot.data!.docs.map((doc) {
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

                      // Apply filtering based on selected type
                      final filteredResults =
                          allResults.where((result) {
                            if (_selectedResultType == 'All Results') {
                              return true;
                            } else if (_selectedResultType == 'MCQ') {
                              // Filter for MCQ results
                              // Check for the test type field first, then fall back to checking questionDetails
                              final testType = result['testType'];
                              if (testType != null) {
                                return testType.toString().toLowerCase() == 'mcq';
                              } else {
                                // Legacy check - if testType is not available
                                return result['questionDetails'] != null;
                              }
                            } else if (_selectedResultType == 'Descriptive') {
                              // Filter for Descriptive results
                              final testType = result['testType'];
                              if (testType != null) {
                                return testType.toString().toLowerCase() == 'descriptive';
                              } else {
                                // Legacy check - if testType is not available
                                return result['questionDetails'] == null;
                              }
                            }
                            return true;
                          }).toList();

                      // Results loaded; removed debug prints to keep console clean

                      if (filteredResults.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedResultType == 'MCQ'
                                    ? Icons.quiz
                                    : _selectedResultType == 'Descriptive'
                                    ? Icons.edit_note
                                    : Icons.analytics,
                                size: 80,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedResultType == 'MCQ'
                                    ? 'No MCQ test results found'
                                    : _selectedResultType == 'Descriptive'
                                    ? 'No Descriptive exam results found'
                                    : 'No test results found',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedResultType == 'MCQ'
                                    ? 'Take some MCQ tests to see your results here'
                                    : _selectedResultType == 'Descriptive'
                                    ? 'Descriptive exams are currently PDF-only. Results will appear here once submission system is implemented.'
                                    : 'Take some tests to see your results here',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredResults.length,
                        itemBuilder: (context, index) {
                          return _buildMyResultCard(filteredResults[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMyResultCard(Map<String, dynamic> result) {
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                result['testTitle'] ?? 'Unknown Test',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Test Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTestTypeColor(result),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getTestTypeColor(result)?.withOpacity(0.7) ?? Colors.grey,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getTestTypeText(result).toLowerCase() == 'mcq'
                        ? Icons.quiz
                        : Icons.edit_note,
                    size: 12,
                    color: _getTestTypeTextColor(result),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getTestTypeText(result),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getTestTypeTextColor(result),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber[600]),
                    const SizedBox(width: 4),
                    Text('$score/$totalMarks marks'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${timeTaken} min'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(result['standard'] ?? 'N/A'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Submitted: ${_formatDate(submittedAt)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility, color: Colors.blue),
          onPressed: () => _viewMyResultDetails(result),
          tooltip: 'View Details',
        ),
      ),
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
  
  // Helper methods for test type display
  String _getTestTypeText(Map<String, dynamic> result) {
    final testType = result['testType'];
    if (testType != null) {
      return testType.toString();
    }
    // Legacy fallback
    return result['questionDetails'] != null ? 'MCQ' : 'Descriptive';
  }
  
  Color? _getTestTypeColor(Map<String, dynamic> result) {
    final testType = result['testType'];
    if (testType != null) {
      if (testType.toString().toLowerCase() == 'mcq') {
        return Colors.blue[100];
      } else if (testType.toString().toLowerCase() == 'descriptive') {
        return Colors.green[100];
      }
    }
    // Legacy fallback
    return result['questionDetails'] != null ? Colors.blue[100] : Colors.green[100];
  }
  
  Color? _getTestTypeTextColor(Map<String, dynamic> result) {
    final testType = result['testType'];
    if (testType != null) {
      if (testType.toString().toLowerCase() == 'mcq') {
        return Colors.blue[700];
      } else if (testType.toString().toLowerCase() == 'descriptive') {
        return Colors.green[700];
      }
    }
    // Legacy fallback
    return result['questionDetails'] != null ? Colors.blue[700] : Colors.green[700];
  }

  void _viewMyResultDetails(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.9,
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
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            result['testTitle'] ?? 'Test Result Details',
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Score: ${result['score']}/${result['totalMarks']} (${result['percentage']}%)',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Subject: ${result['subject'] ?? 'N/A'}'),
                              const SizedBox(height: 4),
                              Text(
                                'Time Taken: ${result['timeTaken']} minutes',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Submitted: ${_formatDate((result['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now())}',
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
                            'Detailed Question Analysis:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (result['questionDetails'] != null &&
                              result['answers'] != null)
                            ...((result['questionDetails']
                                    as Map<String, dynamic>)
                                .entries
                                .map((entry) {
                                  final questionIndex = int.parse(entry.key);
                                  final questionData =
                                      entry.value as Map<String, dynamic>;
                                  final userAnswer =
                                      result['answers'][entry.key] as String? ??
                                      '';

                                  return _buildDetailedQuestionCard(
                                    questionIndex + 1,
                                    questionData,
                                    userAnswer,
                                  );
                                })
                                .toList())
                          else
                            const Text('No detailed question data available'),
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

  Widget _buildDetailedQuestionCard(
    int questionNumber,
    Map<String, dynamic> questionData,
    String userAnswer,
  ) {
    final question = questionData['question'] as String? ?? '';
    final options = questionData['options'] as Map<String, dynamic>? ?? {};
    final correctAnswer = questionData['correctAnswer'] as String? ?? '';
    final marks = questionData['marks'] as int? ?? 0;
    final explanation = questionData['explanation'] as String? ?? '';

    final isCorrect = userAnswer == correctAnswer;
    final earnedMarks = isCorrect ? marks : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCorrect ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
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
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[300]!),
                  ),
                  child: Text(
                    '${earnedMarks}/${marks} marks',
                    style: TextStyle(
                      color: Colors.amber[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question Text
            Text(
              question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
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
            ...options.entries.map((entry) {
              final optionKey = entry.key;
              final optionText = entry.value as String;
              final isUserAnswer = optionKey == userAnswer;
              final isCorrectOption = optionKey == correctAnswer;

              Color backgroundColor;
              Color textColor;
              IconData? icon;

              if (isCorrectOption) {
                backgroundColor = Colors.green[100]!;
                textColor = Colors.green[800]!;
                icon = Icons.check_circle;
              } else if (isUserAnswer && !isCorrectOption) {
                backgroundColor = Colors.red[100]!;
                textColor = Colors.red[800]!;
                icon = Icons.cancel;
              } else {
                backgroundColor = Colors.grey[100]!;
                textColor = Colors.grey[800]!;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isCorrectOption
                            ? Colors.green[300]!
                            : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            isCorrectOption ? Colors.green : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          optionKey,
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
                          color: textColor,
                          fontWeight:
                              isCorrectOption
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (icon != null) Icon(icon, color: textColor, size: 20),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 16),

            // Answer Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue[600], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Your Answer: $userAnswer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Correct Answer: $correctAnswer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Explanation
            if (explanation.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: Colors.amber[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Explanation:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber[800],
                        height: 1.4,
                      ),
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
}
