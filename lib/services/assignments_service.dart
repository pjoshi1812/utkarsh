import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_model.dart';

class AssignmentsService {
  static final CollectionReference _content =
      FirebaseFirestore.instance.collection('content');

  static Stream<List<ContentItem>> getAssignments({
    required Standard standard,
    required Board board,
    String? subject,
  }) {
    final Query baseQuery = _content
        .where('type', isEqualTo: 'assignment')
        .where('standard', isEqualTo: standard.standardDisplayName)
        .where('isActive', isEqualTo: true);

    return baseQuery.snapshots().map((snap) {
      final items = snap.docs
          .map((d) => ContentItem.fromMap(d.data() as Map<String, dynamic>, d.id))
          .where((c) => (c.board.boardDisplayName == board.boardDisplayName))
          .where((c) => subject == null || subject.isEmpty || c.subject == subject)
          .toList()
        ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      return items;
    });
  }

  static Stream<List<ContentItem>> getAssignmentsByChapter({
    required Standard standard,
    required Board board,
    required String chapterNumber,
    String? subject,
  }) {
    return getAssignments(standard: standard, board: board, subject: subject).map(
      (items) => items.where((c) => c.chapterNumber == chapterNumber).toList(),
    );
  }

  static Stream<List<ContentItem>> getUpcomingAssignments({
    required Standard standard,
    required Board board,
    String? subject,
    int daysAhead = 365,
  }) {
    final now = DateTime.now();
    final end = now.add(Duration(days: daysAhead));
    return getAssignments(standard: standard, board: board, subject: subject).map(
      (items) => items.where((c) => c.dueDate != null && c.dueDate!.isAfter(now) && c.dueDate!.isBefore(end)).toList(),
    );
  }

  static Stream<List<ContentItem>> getOverdueAssignments({
    required Standard standard,
    required Board board,
    String? subject,
  }) {
    final now = DateTime.now();
    return getAssignments(standard: standard, board: board, subject: subject).map(
      (items) => items.where((c) => c.dueDate != null && c.dueDate!.isBefore(now)).toList(),
    );
  }

  static Stream<List<ContentItem>> searchAssignments({
    required String query,
    required Standard standard,
    required Board board,
    String? subject,
  }) {
    final q = query.trim().toLowerCase();
    return getAssignments(standard: standard, board: board, subject: subject).map(
      (items) => items.where((c) {
        final hay = '${c.title} ${c.description} ${c.chapterName} ${c.subject}'.toLowerCase();
        return hay.contains(q);
      }).toList(),
    );
  }

  static Future<List<String>> getSubjects({
    required Standard standard,
    required Board board,
  }) async {
    final snap = await _content
        .where('type', isEqualTo: 'assignment')
        .where('standard', isEqualTo: standard.standardDisplayName)
        .get();
    final set = <String>{};
    for (final d in snap.docs) {
      final item = ContentItem.fromMap(d.data() as Map<String, dynamic>, d.id);
      final subj = item.subject;
      if (item.board.boardDisplayName == board.boardDisplayName && subj != null && subj.isNotEmpty) {
        set.add(subj);
      }
    }
    return set.toList()..sort();
  }

  static Future<List<String>> getChapters({
    required Standard standard,
    required Board board,
    String? subject,
  }) async {
    final snap = await _content
        .where('type', isEqualTo: 'assignment')
        .where('standard', isEqualTo: standard.standardDisplayName)
        .get();
    final set = <String>{};
    for (final d in snap.docs) {
      final item = ContentItem.fromMap(d.data() as Map<String, dynamic>, d.id);
      final okBoard = item.board.boardDisplayName == board.boardDisplayName;
      final okSubject = subject == null || subject.isEmpty || item.subject == subject;
      if (okBoard && okSubject && item.chapterNumber.isNotEmpty) {
        set.add(item.chapterNumber);
      }
    }
    final list = set.toList();
    list.sort((a, b) {
      final ai = int.tryParse(a) ?? 0;
      final bi = int.tryParse(b) ?? 0;
      return ai.compareTo(bi);
    });
    return list;
  }
}


