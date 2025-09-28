import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  final _col = FirebaseFirestore.instance.collection('feedback');

  Future<void> submitFeedback({
    required String message,
    required int rating,
    required String studentName,
    required String course,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');
    final docRef = _col.doc(uid);
    final snap = await docRef.get();

    // Preserve original createdAt if feedback already exists
    DateTime createdAt = DateTime.now();
    if (snap.exists) {
      final data = snap.data();
      final ts = (data != null ? data['createdAt'] : null);
      if (ts is Timestamp) {
        createdAt = ts.toDate();
      } else if (ts is DateTime) {
        createdAt = ts;
      }
    }

    final model = FeedbackModel(
      id: uid,
      studentUid: uid,
      studentName: studentName,
      course: course,
      rating: rating,
      message: message,
      createdAt: createdAt,
    );

    // Upsert by UID so each student has exactly one editable feedback
    await docRef.set(model.toMap());
  }

  Stream<List<FeedbackModel>> streamRecent({int limit = 10}) {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FeedbackModel.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<FeedbackModel?> getMyFeedback() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    return FeedbackModel.fromDoc(doc);
  }
}
