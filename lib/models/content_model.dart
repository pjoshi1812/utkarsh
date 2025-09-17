import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType { mcq, descriptive, assignment, notes }

enum Standard { eighth, ninth, tenth, eleventh, twelfth }

enum Board { cbse, hsc }

extension StandardExtension on Standard {
  String get standardDisplayName {
    switch (this) {
      case Standard.eighth:
        return '8th';
      case Standard.ninth:
        return '9th';
      case Standard.tenth:
        return '10th';
      case Standard.eleventh:
        return '11th';
      case Standard.twelfth:
        return '12th';
    }
  }
}

extension BoardExtension on Board {
  String get boardDisplayName {
    switch (this) {
      case Board.cbse:
        return 'CBSE';
      case Board.hsc:
        return 'HSC';
    }
  }
}

extension ContentTypeExtension on ContentType {
  String get typeDisplayName {
    switch (this) {
      case ContentType.mcq:
        return 'MCQ Exam';
      case ContentType.descriptive:
        return 'Descriptive Exam';
      case ContentType.assignment:
        return 'Assignment';
      case ContentType.notes:
        return 'Notes';
    }
  }
}

class ContentItem {
  final String id;
  final String title;
  final String description;
  final ContentType type;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final int fileSize;
  final DateTime uploadDate;
  final String uploadedBy;
  final List<String> targetCourses;
  final List<String> targetStandards;
  final bool isActive;
  final DateTime? dueDate;
  final String? subject;
  final Standard standard;
  final Board board;
  final bool isDescriptiveExam;
  final String chapterNumber;
  final String chapterName;
  final List<String> tags;
  final int? totalMarks;
  final int? timeLimit; // in minutes
  final List<Map<String, dynamic>>? questions; // For MCQ and Descriptive
  final String? instructions;

  ContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.uploadDate,
    required this.uploadedBy,
    required this.targetCourses,
    required this.targetStandards,
    required this.isActive,
    this.dueDate,
    this.subject,
    required this.standard,
    required this.board,
    this.isDescriptiveExam = false,
    required this.chapterNumber,
    required this.chapterName,
    this.tags = const [],
    this.totalMarks,
    this.timeLimit,
    this.questions,
    this.instructions,
  });

  factory ContentItem.fromMap(Map<String, dynamic> map, String id) {
    return ContentItem(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: ContentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ContentType.notes,
      ),
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileType: map['fileType'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      uploadDate: (map['uploadDate'] as Timestamp).toDate(),
      uploadedBy: map['uploadedBy'] ?? '',
      targetCourses: List<String>.from(map['targetCourses'] ?? []),
      targetStandards: List<String>.from(map['targetStandards'] ?? []),
      isActive: map['isActive'] ?? true,
      dueDate:
          map['dueDate'] != null
              ? (map['dueDate'] as Timestamp).toDate()
              : null,
      subject: map['subject'] as String?,
      standard: Standard.values.firstWhere(
        (e) => e.name == map['standard'],
        orElse: () => Standard.eighth,
      ),
      board: Board.values.firstWhere(
        (e) => e.name == map['board'],
        orElse: () => Board.cbse,
      ),
      chapterNumber: map['chapterNumber'] ?? '',
      chapterName: map['chapterName'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      isDescriptiveExam: map['isDescriptiveExam'] ?? false,
      totalMarks: map['totalMarks'] as int?,
      timeLimit: map['timeLimit'] as int?,
      questions:
          map['questions'] != null
              ? List<Map<String, dynamic>>.from(map['questions'])
              : null,
      instructions: map['instructions'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'uploadedBy': uploadedBy,
      'targetCourses': targetCourses,
      'targetStandards': targetStandards,
      'isActive': isActive,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      if (subject != null) 'subject': subject,
      'standard': standard.name,
      'board': board.name,
      'isDescriptiveExam': isDescriptiveExam,
      'chapterNumber': chapterNumber,
      'chapterName': chapterName,
      'tags': tags,
      if (totalMarks != null) 'totalMarks': totalMarks,
      if (timeLimit != null) 'timeLimit': timeLimit,
      if (questions != null) 'questions': questions,
      if (instructions != null) 'instructions': instructions,
    };
  }

  ContentItem copyWith({
    String? id,
    String? title,
    String? description,
    ContentType? type,
    String? fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
    DateTime? uploadDate,
    String? uploadedBy,
    List<String>? targetCourses,
    List<String>? targetStandards,
    bool? isActive,
    DateTime? dueDate,
    String? subject,
    Standard? standard,
    Board? board,
    bool? isDescriptiveExam,
    String? chapterNumber,
    String? chapterName,
    List<String>? tags,
    int? totalMarks,
    int? timeLimit,
    List<Map<String, dynamic>>? questions,
    String? instructions,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      uploadDate: uploadDate ?? this.uploadDate,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      targetCourses: targetCourses ?? this.targetCourses,
      targetStandards: targetStandards ?? this.targetStandards,
      isActive: isActive ?? this.isActive,
      dueDate: dueDate ?? this.dueDate,
      subject: subject ?? this.subject,
      standard: standard ?? this.standard,
      board: board ?? this.board,
      isDescriptiveExam: isDescriptiveExam ?? this.isDescriptiveExam,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      chapterName: chapterName ?? this.chapterName,
      tags: tags ?? this.tags,
      totalMarks: totalMarks ?? this.totalMarks,
      timeLimit: timeLimit ?? this.timeLimit,
      questions: questions ?? this.questions,
      instructions: instructions ?? this.instructions,
    );
  }
}
