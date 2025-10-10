import 'package:flutter/material.dart';
import '../models/content_model.dart';
import '../services/notes_service.dart';
import 'content_viewer_screen.dart';

class StudentNotesScreen extends StatefulWidget {
  final Standard standard;
  final Board board;

  const StudentNotesScreen({super.key, required this.standard, required this.board});

  @override
  State<StudentNotesScreen> createState() => _StudentNotesScreenState();
}

class _StudentNotesScreenState extends State<StudentNotesScreen> {
  String? _selectedSubject;
  String? _selectedChapter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
          'Notes - ${widget.standard.standardDisplayName} ${widget.board.boardDisplayName}',
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
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search notes...',
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                      const SizedBox(height: 16),
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
                Expanded(child: _buildNotesList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectFilter() {
    return FutureBuilder<List<String>>(
      future: NotesService.getSubjects(standard: widget.standard, board: widget.board),
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
      future: NotesService.getChapters(
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

  Widget _buildNotesList() {
    Stream<List<ContentItem>> stream;
    if (_searchQuery.isNotEmpty) {
      stream = NotesService.searchNotes(
        query: _searchQuery,
        standard: widget.standard,
        board: widget.board,
        subject: _selectedSubject,
      );
    } else if (_selectedChapter != null) {
      stream = NotesService.getNotesByChapter(
        standard: widget.standard,
        board: widget.board,
        chapterNumber: _selectedChapter!,
        subject: _selectedSubject,
      );
    } else {
      stream = NotesService.getNotes(
        standard: widget.standard,
        board: widget.board,
        subject: _selectedSubject,
      );
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
                Icon(Icons.note_add, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty ? 'No notes found for "$_searchQuery"' : 'No notes available',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty ? 'Try a different search term' : 'Notes will appear here when uploaded',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) => _buildNoteCard(data[index]),
        );
      },
    );
  }

  Widget _buildNoteCard(ContentItem note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.note, color: Colors.blue[700]),
        ),
        title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(note.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.menu_book, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${note.subject} - Chapter ${note.chapterNumber}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Uploaded ${_formatDate(note.uploadDate)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: note.tags.take(3).map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 10)), backgroundColor: Colors.green[100], labelStyle: TextStyle(color: Colors.green[700], fontSize: 10))).toList(),
              ),
            ],
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: () => _viewNote(note),
      ),
    );
  }

  void _viewNote(ContentItem note) {
  final url = note.fileUrl.trim();
  final uri = Uri.tryParse(url);
  final isValid = url.isNotEmpty &&
      uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;

  if (!isValid) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File not available to view. Please try again later.')),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ContentViewerScreen(
        title: note.title,
        fileUrl: url,
        fileType: note.fileType,
      ),
    ),
  );
}

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return 'today';
    if (difference.inDays == 1) return 'yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}


