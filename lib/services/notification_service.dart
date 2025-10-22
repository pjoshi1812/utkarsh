import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> registerToken(String uid) async {
    try {
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final String? token = await _messaging.getToken();
      if (token == null) return;

      final String platform = _platform();
      final tokenRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tokens')
          .doc(token);

      await tokenRef.set({
        'token': token,
        'platform': platform,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _messaging.onTokenRefresh.listen((newToken) async {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('tokens')
            .doc(newToken);
        await ref.set({
          'token': newToken,
          'platform': platform,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (_) {}
  }

  static Future<void> removeCurrentToken(String uid) async {
    try {
      final String? token = await _messaging.getToken();
      if (token == null) return;
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tokens')
          .doc(token);
      await ref.delete();
    } catch (_) {}
  }

  static String _platform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
