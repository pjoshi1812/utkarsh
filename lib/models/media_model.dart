/// Model representing media content such as videos, images, banners, or pamphlets
class MediaModel {
  final String id;
  final String title;
  final String description;
  final String url;
  final String thumbnailUrl;
  final String type; // e.g. 'video', 'image'
  final int? duration; // in minutes for videos (optional)
  final DateTime createdAt;

  const MediaModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.thumbnailUrl,
    required this.type,
    this.duration,
    required this.createdAt,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json, String id) {
    return MediaModel(
      id: id,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      type: json['type'] as String? ?? 'image',
      duration: (json['duration'] as num?)?.toInt(),
      createdAt: _parseTimestamp(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'type': type,
      if (duration != null) 'duration': duration,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    // Firestore Timestamp compatibility without importing Firestore here
    try {
      final dynamic maybeSeconds = value is Map ? value['seconds'] : null;
      if (maybeSeconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(maybeSeconds * 1000);
      }
    } catch (_) {
      // ignore parsing errors and fall through
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'MediaModel(id: $id, title: $title, type: $type)';
  }
}
