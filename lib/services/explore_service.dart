import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/media_model.dart';

class ExploreService {
  ExploreService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _mediaCol =>
      _firestore.collection('media');

  // Query media by category
  Future<List<MediaModel>> fetchByCategory(String category,
      {int limit = 20}) async {
    final qs = await _mediaCol
        .where('category', isEqualTo: category)
        .limit(limit)
        .get();
    final list = qs.docs.map((d) => MediaModel.fromJson(d.data(), d.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // Fetch latest media regardless of category
  Future<List<MediaModel>> fetchLatest({int limit = 20}) async {
    final qs = await _mediaCol
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return qs.docs
        .map((d) => MediaModel.fromJson(d.data(), d.id))
        .toList();
  }

  // Toppers
  Future<List<Map<String, dynamic>>> fetchToppers({int limit = 100}) async {
    final qs = await _firestore
        .collection('toppers')
        .orderBy('year', descending: true)
        .limit(limit)
        .get();
    return qs.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<String> addTopper({
    required String studentName,
    required String standard, // '10th' | '12th'
    required String board, // 'SSC' | 'CBSE'
    required int year,
    required int rank,
    required num percentage,
    String? enrollmentId,
  }) async {
    final doc = await _firestore.collection('toppers').add({
      'studentName': studentName,
      'standard': standard,
      'board': board,
      'year': year,
      'rank': rank,
      'percentage': percentage,
      if (enrollmentId != null) 'enrollmentId': enrollmentId,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return doc.id;
  }

  Future<void> deleteTopper(String id) async {
    await _firestore.collection('toppers').doc(id).delete();
  }

  // Upload a file to Firebase Storage and return its download URL
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String storagePath,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref().child(storagePath);
    final uploadTask = ref.putData(bytes, SettableMetadata(contentType: contentType));

    uploadTask.snapshotEvents.listen((event) {
      if (onProgress != null && event.totalBytes > 0) {
        onProgress(event.bytesTransferred / event.totalBytes);
      }
    });

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Create or update a media document
  Future<String> upsertMedia(MediaModel media) async {
    if (media.id.isEmpty) {
      final doc = await _mediaCol.add(media.toJson());
      return doc.id;
    } else {
      await _mediaCol.doc(media.id).set(media.toJson(), SetOptions(merge: true));
      return media.id;
    }
  }

  Future<void> deleteMedia(String id) async {
    await _mediaCol.doc(id).delete();
  }
}
