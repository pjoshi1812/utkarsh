import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
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
            child: Padding(
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
                        const Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Manage students and enrollments',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Admin Features Grid
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildFeatureCard(
                          context,
                          'View Enrollments',
                          Icons.people,
                          Colors.blue,
                          () => _showEnrollments(context),
                        ),
                        _buildFeatureCard(
                          context,
                          'Attendance',
                          Icons.event_available,
                          Colors.green,
                          () {
                            Navigator.of(context).pushNamed('/attendance');
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Student Management',
                          Icons.school,
                          Colors.orange,
                          () {
                            // TODO: Implement student management
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Student Management coming soon!')),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Course Management',
                          Icons.book,
                          Colors.purple,
                          () {
                            // TODO: Implement course management
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Course Management coming soon!')),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Reports & Analytics',
                          Icons.analytics,
                          Colors.teal,
                          () {
                            // TODO: Implement reports
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reports & Analytics coming soon!')),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Settings',
                          Icons.settings,
                          Colors.indigo,
                          () {
                            // TODO: Implement settings
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Settings coming soon!')),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Notifications',
                          Icons.notifications,
                          Colors.red,
                          () {
                            // TODO: Implement notifications
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notifications coming soon!')),
                            );
                          },
                        ),
                      ],
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

  void _showEnrollments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Student Enrollments',
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
                stream: FirebaseFirestore.instance
                    .collection('enrollments')
                    .orderBy('enrollmentDate', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No enrollments found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final enrollment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      final enrollmentId = snapshot.data!.docs[index].id;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            enrollment['studentName'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Course: ${enrollment['course'] ?? 'N/A'}'),
                              Text('Status: ${enrollment['status'] ?? 'pending'}'),
                              Text('Type: ${enrollment['studentType'] ?? 'N/A'}'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => _handleEnrollmentAction(value, enrollmentId, enrollment),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'approve',
                                child: Row(
                                  children: [
                                    Icon(Icons.check, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Approve'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'reject',
                                child: Row(
                                  children: [
                                    Icon(Icons.close, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Reject'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                            ],
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
      ),
    );
  }

  void _handleEnrollmentAction(String action, String enrollmentId, Map<String, dynamic> enrollment) {
    switch (action) {
      case 'approve':
        FirebaseFirestore.instance
            .collection('enrollments')
            .doc(enrollmentId)
            .update({'status': 'approved'});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment approved!'), backgroundColor: Colors.green),
        );
        break;
      case 'reject':
        FirebaseFirestore.instance
            .collection('enrollments')
            .doc(enrollmentId)
            .update({'status': 'rejected'});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment rejected!'), backgroundColor: Colors.red),
        );
        break;
      case 'view':
        _showEnrollmentDetails(enrollment);
        break;
    }
  }

  void _showEnrollmentDetails(Map<String, dynamic> enrollment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enrollment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Student Name', enrollment['studentName'] ?? 'N/A'),
              _buildDetailRow('Student Type', enrollment['studentType'] ?? 'N/A'),
              _buildDetailRow('Contact', enrollment['studentContact'] ?? 'N/A'),
              _buildDetailRow('WhatsApp', enrollment['studentWhatsApp'] ?? 'N/A'),
              _buildDetailRow('Email', enrollment['email'] ?? 'N/A'),
              _buildDetailRow('School/College', enrollment['schoolCollege'] ?? 'N/A'),
              _buildDetailRow('Address', enrollment['address'] ?? 'N/A'),
              _buildDetailRow('Parent Name', enrollment['parentName'] ?? 'N/A'),
              _buildDetailRow('Parent Contact', enrollment['parentContact'] ?? 'N/A'),
              _buildDetailRow('Parent WhatsApp', enrollment['parentWhatsApp'] ?? 'N/A'),
              _buildDetailRow('Occupation', enrollment['occupation'] ?? 'N/A'),
              _buildDetailRow('Parent Email', enrollment['parentEmail'] ?? 'N/A'),
              _buildDetailRow('Course', enrollment['course'] ?? 'N/A'),
              _buildDetailRow('Previous Maths Marks', enrollment['previousMathsMarks'] ?? 'N/A'),
              _buildDetailRow('Status', enrollment['status'] ?? 'pending'),
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
            width: 120,
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
} 