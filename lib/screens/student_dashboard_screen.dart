import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  Map<String, dynamic>? _enrollmentData;
  bool _isLoading = true;

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
        final querySnapshot = await FirebaseFirestore.instance
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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
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
            child: _isLoading
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
            Image.asset(
              'assets/utkarsh_logo.jpg',
              height: 120,
              width: 120,
            ),
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
                Image.asset(
                  'assets/utkarsh_logo.jpg',
                  height: 80,
                  width: 80,
                ),
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
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  () => _showCourseMaterials(context),
                ),
                _buildFeatureCard(
                  context,
                  'Assignments',
                  Icons.assignment,
                  Colors.orange,
                  () => _showAssignments(context),
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
              ],
            ),
          ),
        ],
      ),
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
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
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
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMaterialCard('Chapter 1: Introduction', 'PDF', '2.5 MB'),
                  _buildMaterialCard('Chapter 2: Basic Concepts', 'PDF', '3.1 MB'),
                  _buildMaterialCard('Practice Problems Set 1', 'PDF', '1.8 MB'),
                  _buildMaterialCard('Video Lecture 1', 'MP4', '45.2 MB'),
                  _buildMaterialCard('Quiz 1', 'Online', '15 min'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialCard(String title, String type, String size) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          type == 'PDF' ? Icons.picture_as_pdf : type == 'MP4' ? Icons.video_file : Icons.quiz,
          color: Colors.green,
        ),
        title: Text(title),
        subtitle: Text('$type • $size'),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Downloading $title...')),
            );
          },
        ),
      ),
    );
  }

  void _showAssignments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment, color: Colors.white, size: 24),
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAssignmentCard('Assignment 1', 'Due: 15 Dec 2024', 'Not Submitted'),
                  _buildAssignmentCard('Assignment 2', 'Due: 20 Dec 2024', 'Not Submitted'),
                  _buildAssignmentCard('Assignment 3', 'Due: 25 Dec 2024', 'Not Submitted'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(String title, String dueDate, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          status == 'Submitted' ? Icons.check_circle : Icons.pending,
          color: status == 'Submitted' ? Colors.green : Colors.orange,
        ),
        title: Text(title),
        subtitle: Text(dueDate),
        trailing: Text(
          status,
          style: TextStyle(
            color: status == 'Submitted' ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening $title...')),
          );
        },
      ),
    );
  }

  void _showProgress(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            children: [
              Text(title),
              Text('$percentage%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 80 ? Colors.green : percentage >= 60 ? Colors.orange : Colors.red,
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
} 