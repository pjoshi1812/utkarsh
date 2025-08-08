import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExploreMoreScreen extends StatelessWidget {
  const ExploreMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'Explore More',
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
                          'Welcome to Utkarsh',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Explore our educational services',
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

                  // Features Grid
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildFeatureCard(
                          context,
                          'Student Enrollment',
                          Icons.school,
                          Colors.blue,
                          () => Navigator.pushNamed(context, '/student-enrollment'),
                        ),
                        _buildFeatureCard(
                          context,
                          'Course Catalog',
                          Icons.book,
                          Colors.orange,
                          () {
                            // TODO: Implement course catalog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Course Catalog coming soon!')),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Progress Tracking',
                          Icons.trending_up,
                          Colors.purple,
                          () {
                            // TODO: Implement progress tracking
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Progress Tracking coming soon!')),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Study Materials',
                          Icons.library_books,
                          Colors.teal,
                          () {
                            // TODO: Implement study materials
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Study Materials coming soon!')),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Online Classes',
                          Icons.video_call,
                          Colors.red,
                          () {
                            // TODO: Implement online classes
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Online Classes coming soon!')),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context,
                          'Contact Support',
                          Icons.support_agent,
                          Colors.indigo,
                          () {
                            // TODO: Implement contact support
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Contact Support coming soon!')),
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
} 