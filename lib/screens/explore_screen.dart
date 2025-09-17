import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../models/media_model.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  // Demo videos data
  List<MediaModel> demoVideos = [];
  List<MediaModel> classPamphlets = [];
  List<MediaModel> banners = [];
  List<MediaModel> _mediaList = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDemoVideos();
    _loadPamphletsAndBanners();
    _loadMedia();
  }

  void _showVideoPlayer(String videoUrl, String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VideoPlayerDialog(videoUrl: videoUrl, title: title),
    );
  }

  Future<void> _loadUserData() async {
    try {
      currentUser = _auth.currentUser;
      if (currentUser != null) {
        final doc =
            await _firestore.collection('users').doc(currentUser!.uid).get();
        if (doc.exists) {
          setState(() {
            userData = doc.data();
            isLoading = false;
          });
        }
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadMedia() async {
    try {
      final QuerySnapshot querySnapshot =
          await _firestore.collection('media').get();

      final List<MediaModel> mediaList =
          querySnapshot.docs.map((doc) {
              return MediaModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            }).toList()
            ..sort((a, b) {
              // Sort by creation date in code
              return b.createdAt.compareTo(a.createdAt);
            });

      setState(() {
        _mediaList = mediaList;
      });
    } catch (e) {
      debugPrint('Error loading media: $e');
    }
  }

  Future<void> _loadDemoVideos() async {
    try {
      demoVideos = [
        MediaModel(
          id: '1',
          title: 'Demo Video 1',
          description: 'Mathematics - Chapter 1',
          url:
              'https://res.cloudinary.com/dpyig1neh/video/upload/Screen_Recording_2025-08-05_221051_tg21sb.mp4',
          thumbnailUrl:
              'https://res.cloudinary.com/dpyig1neh/video/upload/w_300,h_200,c_fill,so_0/Screen_Recording_2025-08-05_221051_tg21sb.jpg',
          type: 'video',
          duration: 15,
          createdAt: DateTime.now(),
        ),
        MediaModel(
          id: '2',
          title: 'Demo Video 2',
          description: 'Mathematics - Chapter 2',
          url:
              'https://res.cloudinary.com/dpyig1neh/video/upload/Screen_Recording_2025-08-05_221051_tg21sb.mp4',
          thumbnailUrl:
              'https://res.cloudinary.com/dpyig1neh/video/upload/w_300,h_200,c_fill,so_0/Screen_Recording_2025-08-05_221051_tg21sb.jpg',
          type: 'video',
          duration: 20,
          createdAt: DateTime.now(),
        ),
        MediaModel(
          id: '3',
          title: 'Demo Video 3',
          description: 'Mathematics - Chapter 3',
          url:
              'https://res.cloudinary.com/dpyig1neh/video/upload/Screen_Recording_2025-08-05_221051_tg21sb.mp4',
          thumbnailUrl:
              'https://res.cloudinary.com/dpyig1neh/video/upload/w_300,h_200,c_fill,so_0/Screen_Recording_2025-08-05_221051_tg21sb.jpg',
          type: 'video',
          duration: 25,
          createdAt: DateTime.now(),
        ),
      ];
      setState(() {});
    } catch (e) {
      debugPrint('Error loading demo videos: $e');
    }
  }

  Future<void> _loadPamphletsAndBanners() async {
    try {
      classPamphlets = [
        MediaModel(
          id: 'p1',
          title: 'Pamphlet 1',
          description: 'Cloudinary Pamphlet Example',
          url:
              'https://res.cloudinary.com/dpyig1neh/image/upload/maths_banner_kz9kq0.jpg',
          thumbnailUrl:
              'https://res.cloudinary.com/dpyig1neh/image/upload/maths_banner_kz9kq0.jpg',
          type: 'image',
          createdAt: DateTime.now(),
        ),
        MediaModel(
          id: 'p2',
          title: 'Pamphlet 2',
          description: 'Course Details',
          url:
              'https://res.cloudinary.com/dpyig1neh/image/upload/maths_banner_kz9kq0.jpg',
          thumbnailUrl:
              'https://res.cloudinary.com/dpyig1neh/image/upload/maths_banner_kz9kq0.jpg',
          type: 'image',
          createdAt: DateTime.now(),
        ),
      ];

      banners = [
        MediaModel(
          id: 'b1',
          title: 'Banner 1',
          description: 'Special Offer',
          url:
              'https://res.cloudinary.com/dpyig1neh/image/upload/maths_banner_kz9kq0.jpg',
          thumbnailUrl:
              'https://res.cloudinary.com/dpyig1neh/image/upload/maths_banner_kz9kq0.jpg',
          type: 'image',
          createdAt: DateTime.now(),
        ),
        MediaModel(
          id: 'b2',
          title: 'Banner 2',
          description: 'New Course',
          url:
              'https://res.cloudinary.com/dpyig1neh/image/upload/maths_banner_kz9kq0.jpg',
          thumbnailUrl:
              'https://res.cloudinary.com/dpyig1neh/image/upload/maths_banner_kz9kq0.jpg',
          type: 'image',
          createdAt: DateTime.now(),
        ),
      ];
      setState(() {});
    } catch (e) {
      debugPrint('Error loading pamphlets and banners: $e');
    }
  }

  void _showDemoLectureResults(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Demo/Lecture Results',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildResultSection('Demo Results', [
                    _buildResultCard(
                      'Mathematics Demo',
                      '85%',
                      'Excellent',
                      Colors.green,
                    ),
                    _buildResultCard(
                      'Science Demo',
                      '78%',
                      'Good',
                      Colors.orange,
                    ),
                    _buildResultCard(
                      'English Demo',
                      '92%',
                      'Outstanding',
                      Colors.green,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildResultSection('Lecture Results', [
                    _buildResultCard(
                      'Chapter 1: Introduction',
                      '88%',
                      'Very Good',
                      Colors.green,
                    ),
                    _buildResultCard(
                      'Chapter 2: Basic Concepts',
                      '75%',
                      'Good',
                      Colors.orange,
                    ),
                    _buildResultCard(
                      'Chapter 3: Advanced Topics',
                      '82%',
                      'Good',
                      Colors.green,
                    ),
                  ]),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildResultSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildResultCard(
    String title,
    String score,
    String grade,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.school, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Score: $score',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          grade,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'Utkarsh - Explore',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        actions: [
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _signOut,
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
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Welcome Section with Login/Register
                          _buildWelcomeSection(),
                          const SizedBox(height: 20),

                          // Demo Videos Section
                          _buildDemoVideosSection(),
                          const SizedBox(height: 20),

                          // Media Content Section
                          if (_mediaList.isNotEmpty) ...[
                            _buildMediaContentSection(),
                            const SizedBox(height: 20),
                          ],

                          // Previous Year Toppers
                          _buildPreviousYearToppers(),
                          const SizedBox(height: 20),

                          // Class Pamphlets and Banners
                          _buildClassPamphlets(),
                          const SizedBox(height: 20),

                          // Student/Parent Feedback
                          _buildFeedbackSection(),
                          const SizedBox(height: 20),

                          // Branch Details
                          _buildBranchDetails(),
                          const SizedBox(height: 20),

                          // Features Grid
                          _buildFeaturesGrid(),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
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
            'Explore our educational services and media content',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Show different content based on login status
          if (currentUser == null) ...[
            const Text(
              'Get started by creating an account or logging in',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Register'),
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
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.green[700]!),
                      foregroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Show user info and quick actions when logged in
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'Welcome back, ${userData?['name'] ?? currentUser?.email ?? 'User'}!',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (userData?['role'] == 'admin') {
                              Navigator.pushReplacementNamed(
                                context,
                                '/admin-dashboard',
                              );
                            } else {
                              Navigator.pushReplacementNamed(
                                context,
                                '/student-dashboard',
                              );
                            }
                          },
                          icon: const Icon(Icons.dashboard),
                          label: const Text('Go to Dashboard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDemoVideosSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              const Icon(Icons.video_library, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Demo Videos by Sir',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: demoVideos.length,
              itemBuilder: (context, index) {
                final video = demoVideos[index];
                return GestureDetector(
                  onTap: () => _showVideoPlayer(video.url, video.title),
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Stack(
                            children: [
                              if (video.thumbnailUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: video.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder:
                                        (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                    errorWidget:
                                        (context, url, error) => const Center(
                                          child: Icon(
                                            Icons.video_library,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  ),
                                ),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                video.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${video.duration} min',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest Media Content',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mediaList.length,
              itemBuilder: (context, index) {
                final media = _mediaList[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: media.thumbnailUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                height: 120,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                height: 120,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              media.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              media.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  media.type == 'video'
                                      ? Icons.video_library
                                      : Icons.image,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  media.type.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (media.duration != null) ...[
                                  const Spacer(),
                                  Text(
                                    '${media.duration} min',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousYearToppers() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              const Icon(Icons.emoji_events, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Previous Year Toppers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTopperCard('2023', [
            {'name': 'Rahul Sharma', 'marks': '98%', 'rank': '1st'},
            {'name': 'Priya Patel', 'marks': '96%', 'rank': '2nd'},
            {'name': 'Amit Kumar', 'marks': '94%', 'rank': '3rd'},
          ]),
          const SizedBox(height: 12),
          _buildTopperCard('2022', [
            {'name': 'Neha Singh', 'marks': '97%', 'rank': '1st'},
            {'name': 'Vikram Malhotra', 'marks': '95%', 'rank': '2nd'},
            {'name': 'Anjali Gupta', 'marks': '93%', 'rank': '3rd'},
          ]),
        ],
      ),
    );
  }

  Widget _buildTopperCard(String year, List<Map<String, String>> toppers) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Year $year',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          ...toppers.map(
            (topper) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          topper['rank']!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        topper['name']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    topper['marks']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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

  Widget _buildClassPamphlets() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              const Icon(Icons.campaign, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Class Pamphlets & Banners',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: classPamphlets.length + banners.length,
              itemBuilder: (context, index) {
                MediaModel item;
                if (index < classPamphlets.length) {
                  item = classPamphlets[index];
                } else {
                  item = banners[index - classPamphlets.length];
                }

                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => Dialog(
                            backgroundColor: Colors.black,
                            insetPadding: const EdgeInsets.all(8),
                            child: Stack(
                              children: [
                                InteractiveViewer(
                                  child: CachedNetworkImage(
                                    imageUrl: item.url,
                                    fit: BoxFit.contain,
                                    placeholder:
                                        (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                    errorWidget:
                                        (context, url, error) => const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.7,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    );
                  },
                  child: Container(
                    width: 250,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha: 0.1),
                          Colors.green.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (item.thumbnailUrl.isNotEmpty)
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: item.thumbnailUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder:
                                    (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                errorWidget:
                                    (context, url, error) => Icon(
                                      item.type == 'image'
                                          ? Icons.picture_as_pdf
                                          : Icons.campaign,
                                      size: 32,
                                      color: Colors.green,
                                    ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'View Details',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              const Icon(Icons.feedback, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Student/Parent Feedback',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeedbackCard(
            'Rahul Sharma',
            'Parent',
            'Excellent teaching methodology. My child has improved significantly in mathematics.',
            5,
          ),
          const SizedBox(height: 12),
          _buildFeedbackCard(
            'Priya Patel',
            'Student',
            'The teachers are very supportive and the study material is comprehensive.',
            5,
          ),
          const SizedBox(height: 12),
          _buildFeedbackCard(
            'Amit Kumar',
            'Parent',
            'Great environment for learning. Highly recommended for competitive exam preparation.',
            4,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(
    String name,
    String role,
    String feedback,
    int rating,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    role,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: index < rating ? Colors.amber : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            feedback,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              const Icon(Icons.location_on, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Branch Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBranchCard(
            'Utkarsh Academy',
            'Mayur Colony, Pune',
            '+91 9876543210',
            'main@utkarshacademy.com',
          ),
          const SizedBox(height: 12),
          _buildBranchCard(
            'Utkarsh Academy',
            '456 Bibwewadi, Pune',
            '+91 9876543211',
            'aaa@utkarshacademy.com',
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(
    String name,
    String address,
    String phone,
    String email,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                phone,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.email, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                email,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                'Demo/Lecture Results',
                Icons.assessment,
                Colors.green,
                () => _showDemoLectureResults(context),
              ),
              _buildFeatureCard(
                context,
                'Course Catalog',
                Icons.book,
                Colors.orange,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course Catalog coming soon!'),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                'Progress Tracking',
                Icons.trending_up,
                Colors.purple,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Progress Tracking coming soon!'),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                'Study Materials',
                Icons.library_books,
                Colors.teal,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Study Materials coming soon!'),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                'Online Classes',
                Icons.video_call,
                Colors.red,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Online Classes coming soon!'),
                    ),
                  );
                },
              ),
              _buildFeatureCard(
                context,
                'Contact Support',
                Icons.support_agent,
                Colors.indigo,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact Support coming soon!'),
                    ),
                  );
                },
              ),
            ],
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
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                color: color.withValues(alpha: 0.1),
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
}

class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerDialog({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    try {
      await _controller!.initialize();
      _controller!.addListener(() {
        if (mounted) {
          setState(() {
            _position = _controller!.value.position;
            _duration = _controller!.value.duration;
          });
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child:
                _isInitialized
                    ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                    : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (_isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Slider(
                      value: _position.inMilliseconds.toDouble(),
                      min: 0,
                      max: _duration.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        final newPosition = Duration(
                          milliseconds: value.toInt(),
                        );
                        _controller!.seekTo(newPosition);
                      },
                      activeColor: Colors.red,
                      inactiveColor: Colors.grey.withValues(alpha: 0.5),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_isPlaying) {
                                _controller!.pause();
                              } else {
                                _controller!.play();
                              }
                              _isPlaying = !_isPlaying;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
