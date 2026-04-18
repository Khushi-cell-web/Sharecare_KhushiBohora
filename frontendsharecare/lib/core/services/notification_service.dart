// FCM notification service: request permission, get token, register with backend.
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'sharecare_api_service.dart';

/// Background message handler (must be top-level).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
}

class NotificationService {
  NotificationService({ShareCareApiService? api})
    : _api = api ?? ShareCareApiService();

  final ShareCareApiService _api;

  static Future<void> init() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Request permission and get token. Returns null if denied or unavailable (e.g. web).
  static Future<String?> getToken() async {
    if (kIsWeb) return null;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return null;
    }
    return FirebaseMessaging.instance.getToken();
  }

  /// Register token with backend. Call after login.
  Future<void> registerToken(
    Map<String, String> authHeaders,
    String token,
  ) async {
    try {
      await _api.registerDeviceToken(authHeaders, token);
    } catch (_) {
      // Silently fail - push is optional
    }
  }

  /// Configure onMessage handlers for foreground notifications.
  static void configureHandlers({
    void Function(RemoteMessage)? onMessage,
    void Function(RemoteMessage)? onMessageOpenedApp,
  }) {
    if (onMessage != null) {
      FirebaseMessaging.onMessage.listen(onMessage);
    }
    if (onMessageOpenedApp != null) {
      FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
    }
  }
}
