import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String studentUid;
  final String studentName;
  final String course;
  final int rating; // 1-5
  final String message;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.course,
    required this.rating,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'course': course,
      'rating': rating,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FeedbackModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FeedbackModel(
      id: doc.id,
      studentUid: (data['studentUid'] ?? '').toString(),
      studentName: (data['studentName'] ?? '').toString(),
      course: (data['course'] ?? '').toString(),
      rating: (data['rating'] ?? 0) is int ? data['rating'] as int : int.tryParse('${data['rating']}') ?? 0,
      message: (data['message'] ?? '').toString(),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
