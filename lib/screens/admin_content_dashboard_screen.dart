import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/content_model.dart';
import 'admin_content_management_screen.dart';

class AdminContentDashboardScreen extends StatefulWidget {
  const AdminContentDashboardScreen({super.key});

  @override
  State<AdminContentDashboardScreen> createState() => _AdminContentDashboardScreenState();
}

class _AdminContentDashboardScreenState extends State<AdminContentDashboardScreen> {
  Standard? selectedStandard;
  Board? selectedBoard;
  ContentType? selectedContentType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'Content Management Dashboard',
          style: TextStyle(
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
                          'Content Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Manage educational content for all standards',
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

                  // Selection Cards
                  _buildSelectionCard(
                    'Select Standard',
                    selectedStandard?.standardDisplayName ?? 'Choose Standard',
                    Icons.school,
                    Colors.blue,
                    () => _showStandardSelection(),
                  ),
                  const SizedBox(height: 12),

                  if (selectedStandard != null) ...[
                    _buildSelectionCard(
                      'Select Board',
                      selectedBoard?.boardDisplayName ?? 'Choose Board',
                      Icons.account_balance,
                      Colors.orange,
                      () => _showBoardSelection(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (selectedBoard != null) ...[
                    _buildSelectionCard(
                      'Select Content Type',
                      selectedContentType?.typeDisplayName ?? 'Choose Content Type',
                      Icons.category,
                      Colors.purple,
                      () => _showContentTypeSelection(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  if (selectedContentType != null) ...[
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildActionCard(
                            'Add New Content',
                            Icons.add_circle,
                            Colors.green,
                            () => _navigateToContentManagement(isEdit: false),
                          ),
                          _buildActionCard(
                            'View All Content',
                            Icons.list,
                            Colors.blue,
                            () => _navigateToContentManagement(isEdit: true),
                          ),
                          _buildActionCard(
                            'Manage Chapters',
                            Icons.menu_book,
                            Colors.teal,
                            () => _showChapterManagement(),
                          ),
                          _buildActionCard(
                            'Content Analytics',
                            Icons.analytics,
                            Colors.indigo,
                            () => _showContentAnalytics(),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Please select Standard, Board, and Content Type to continue',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
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

  void _showStandardSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Standard',
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: Standard.values.map((standard) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Text(
                        standard.standardDisplayName,
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      'Standard ${standard.standardDisplayName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      standard == Standard.eighth || standard == Standard.ninth || standard == Standard.tenth
                          ? 'CBSE Board'
                          : 'HSC Board',
                    ),
                    onTap: () {
                      setState(() {
                        selectedStandard = standard;
                        selectedBoard = null; // Reset board selection
                        selectedContentType = null; // Reset content type selection
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBoardSelection() {
    if (selectedStandard == null) return;

    final availableBoards = selectedStandard == Standard.eighth || 
                           selectedStandard == Standard.ninth || 
                           selectedStandard == Standard.tenth
        ? [Board.cbse]
        : [Board.hsc];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[700],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Board',
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: availableBoards.map((board) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange[100],
                      child: Text(
                        board.boardDisplayName,
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      board.boardDisplayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Standard ${selectedStandard!.standardDisplayName}',
                    ),
                    onTap: () {
                      setState(() {
                        selectedBoard = board;
                        selectedContentType = null; // Reset content type selection
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContentTypeSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple[700],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Content Type',
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: ContentType.values.map((type) {
                  IconData icon;
                  Color color;
                  
                  switch (type) {
                    case ContentType.mcq:
                      icon = Icons.quiz;
                      color = Colors.blue;
                      break;
                    case ContentType.descriptive:
                      icon = Icons.edit_note;
                      color = Colors.green;
                      break;
                    case ContentType.assignment:
                      icon = Icons.assignment;
                      color = Colors.orange;
                      break;
                    case ContentType.notes:
                      icon = Icons.note;
                      color = Colors.purple;
                      break;
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(
                      type.typeDisplayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Standard ${selectedStandard!.standardDisplayName} - ${selectedBoard!.boardDisplayName}',
                    ),
                    onTap: () {
                      setState(() {
                        selectedContentType = type;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToContentManagement({required bool isEdit}) {
    if (selectedStandard == null || selectedBoard == null || selectedContentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all options first')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminContentManagementScreen(
          standard: selectedStandard!,
          board: selectedBoard!,
          contentType: selectedContentType!,
          isEditMode: isEdit,
        ),
      ),
    );
  }

  void _showChapterManagement() {
    // TODO: Implement chapter management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chapter Management coming soon!')),
    );
  }

  void _showContentAnalytics() {
    // TODO: Implement content analytics
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Content Analytics coming soon!')),
    );
  }
}
