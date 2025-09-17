import 'package:flutter/material.dart';
import '../models/content_model.dart';
import '../services/assignments_service.dart';
import 'content_viewer_screen.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  final Standard standard;
  final Board board;

  const StudentAssignmentsScreen({super.key, required this.standard, required this.board});

  @override
  State<StudentAssignmentsScreen> createState() => _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  String? _selectedSubject;
  String? _selectedChapter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTab = 0; // 0: All, 1: Upcoming, 2: Overdue

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: Text(
          'Assignments - ${widget.standard.standardDisplayName} ${widget.board.boardDisplayName}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                Container(
                  margin: const EdgeInsets.all(16),
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
                    children: [
                      // Tabs
                      Row(
                        children: [
                          Expanded(child: _buildTabButton('All', 0)),
                          Expanded(child: _buildTabButton('Upcoming', 1)),
                          Expanded(child: _buildTabButton('Overdue', 2)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Search
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search assignments...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildSubjectFilter()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildChapterFilter()),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildAssignmentsList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[700] : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSubjectFilter() {
    return FutureBuilder<List<String>>(
      future: AssignmentsService.getSubjects(standard: widget.standard, board: widget.board),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final subjects = ['All Subjects', ...snapshot.data!];
        return DropdownButtonFormField<String>(
          value: _selectedSubject ?? 'All Subjects',
          decoration: InputDecoration(
            labelText: 'Subject',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _selectedSubject = v == 'All Subjects' ? null : v),
        );
      },
    );
  }

  Widget _buildChapterFilter() {
    return FutureBuilder<List<String>>(
      future: AssignmentsService.getChapters(
        standard: widget.standard,
        board: widget.board,
        subject: _selectedSubject,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final chapters = ['All Chapters', ...snapshot.data!];
        return DropdownButtonFormField<String>(
          value: _selectedChapter ?? 'All Chapters',
          decoration: InputDecoration(
            labelText: 'Chapter',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: chapters
              .map((c) => DropdownMenuItem(value: c, child: Text(c == 'All Chapters' ? c : 'Chapter $c')))
              .toList(),
          onChanged: (v) => setState(() => _selectedChapter = v == 'All Chapters' ? null : v),
        );
      },
    );
  }

  Widget _buildAssignmentsList() {
    Stream<List<ContentItem>> stream;
    if (_searchQuery.isNotEmpty) {
      stream = AssignmentsService.searchAssignments(
        query: _searchQuery,
        standard: widget.standard,
        board: widget.board,
        subject: _selectedSubject,
      );
    } else if (_selectedChapter != null) {
      stream = AssignmentsService.getAssignmentsByChapter(
        standard: widget.standard,
        board: widget.board,
        chapterNumber: _selectedChapter!,
        subject: _selectedSubject,
      );
    } else {
      switch (_selectedTab) {
        case 1:
          stream = AssignmentsService.getUpcomingAssignments(
            standard: widget.standard,
            board: widget.board,
            subject: _selectedSubject,
          );
          break;
        case 2:
          stream = AssignmentsService.getOverdueAssignments(
            standard: widget.standard,
            board: widget.board,
            subject: _selectedSubject,
          );
          break;
        default:
          stream = AssignmentsService.getAssignments(
            standard: widget.standard,
            board: widget.board,
            subject: _selectedSubject,
          );
      }
    }

    return StreamBuilder<List<ContentItem>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final data = snapshot.data ?? const <ContentItem>[];
        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_selectedTab == 2 ? Icons.check_circle : Icons.assignment_add, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _getEmptyStateMessage(),
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptyStateSubtitle(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) => _buildAssignmentCard(data[index]),
        );
      },
    );
  }

  String _getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty) return 'No assignments found for "$_searchQuery"';
    switch (_selectedTab) {
      case 1:
        return 'No upcoming assignments';
      case 2:
        return 'No overdue assignments';
      default:
        return 'No assignments available';
    }
  }

  String _getEmptyStateSubtitle() {
    if (_searchQuery.isNotEmpty) return 'Try a different search term';
    switch (_selectedTab) {
      case 1:
        return 'Great! You\'re all caught up';
      case 2:
        return 'Excellent! No overdue assignments';
      default:
        return 'Assignments will appear here when uploaded';
    }
  }

  Widget _buildAssignmentCard(ContentItem assignment) {
    final now = DateTime.now();
    final isOverdue = assignment.dueDate != null && assignment.dueDate!.isBefore(now);
    final isDueSoon = assignment.dueDate != null && assignment.dueDate!.isAfter(now) && assignment.dueDate!.difference(now).inDays <= 3;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOverdue ? Colors.red[100] : isDueSoon ? Colors.orange[100] : Colors.green[100],
          child: Icon(isOverdue ? Icons.warning : isDueSoon ? Icons.schedule : Icons.assignment,
              color: isOverdue ? Colors.red[700] : isDueSoon ? Colors.orange[700] : Colors.green[700]),
        ),
        title: Text(assignment.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(assignment.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.menu_book, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('${assignment.subject} - Chapter ${assignment.chapterNumber}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 4),
            if (assignment.dueDate != null)
              Row(children: [
                Icon(isOverdue ? Icons.warning : Icons.schedule, size: 16, color: isOverdue ? Colors.red : Colors.orange),
                const SizedBox(width: 4),
                Text(isOverdue ? 'Overdue - Due ${_formatDate(assignment.dueDate!)}' : 'Due ${_formatDate(assignment.dueDate!)}',
                    style: TextStyle(color: isOverdue ? Colors.red : Colors.orange, fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('Uploaded ${_formatDate(assignment.uploadDate)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ]),
            if (assignment.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: assignment.tags.take(3).map((t) =>
                    Chip(label: Text(t, style: const TextStyle(fontSize: 10)), backgroundColor: Colors.green[100], labelStyle: TextStyle(color: Colors.green[700], fontSize: 10))).toList(),
              ),
            ],
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: () => _viewAssignment(assignment),
      ),
    );
  }

  void _viewAssignment(ContentItem assignment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentViewerScreen(
          title: assignment.title,
          fileUrl: assignment.fileUrl,
          fileType: assignment.fileType,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    if (difference.inDays == 0) return 'today';
    if (difference.inDays == 1) return 'tomorrow';
    if (difference.inDays > 0) return 'in ${difference.inDays} days';
    final daysPast = -difference.inDays;
    if (daysPast == 1) return 'yesterday';
    return '$daysPast days ago';
  }
}


