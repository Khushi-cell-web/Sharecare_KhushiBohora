import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// API base URL and path prefixes for ShareCare backend.
class ApiConstants {
  ApiConstants._();

  /// Android fallback base URL resolved in [initialize].
  static String? _androidAutoBaseUrl;
  static String? _runtimeBaseUrlOverride;

  static String? _normalizeOrigin(String? origin) {
    final trimmed = origin?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.replaceFirst(RegExp(r'/$'), '');
  }

  /// Overrides the resolved API origin for the current app session.
  static void setRuntimeBaseUrl(String? baseUrl) {
    final normalized = _normalizeOrigin(baseUrl);
    if (normalized == null) return;
    _runtimeBaseUrlOverride = normalized;
  }

  /// Call once after dotenv is loaded.
  static Future<void> initialize() async {
    _androidAutoBaseUrl = null;
    _runtimeBaseUrlOverride = null;
    try {
      if (AppConfig.apiBaseUrl != null) return;
      if (kIsWeb) return;
      if (defaultTargetPlatform != TargetPlatform.android) return;
      final info = await DeviceInfoPlugin().androidInfo;
      _androidAutoBaseUrl = info.isPhysicalDevice
          ? AppConfig.apiLanFallbackBaseUrl
          : 'http://10.0.2.2:8000';
    } catch (_) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        _androidAutoBaseUrl = AppConfig.apiLanFallbackBaseUrl;
      }
    }
  }

  /// API origin without trailing slash.
  static String get resolvedBaseUrl => baseUrl;

  /// Uses env value when available; otherwise falls back to platform defaults.
  static String get baseUrl {
    final runtime = _runtimeBaseUrlOverride;
    if (runtime != null && runtime.isNotEmpty) {
      return runtime;
    }
    try {
      final env = AppConfig.apiBaseUrl;
      if (env != null && env.isNotEmpty) {
        return _normalizeOrigin(env)!;
      }
    } catch (_) {
      // dotenv not loaded yet (e.g. tests) - use defaults
    }
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        _androidAutoBaseUrl != null) {
      return _androidAutoBaseUrl!;
    }
    if (kIsWeb) return 'http://localhost:8000';

    // Desktop platforms can use localhost directly.
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:8000';
    }

    // If initialize has not run on Android yet, prefer localhost so adb reverse
    // works on physical devices; ApiService will still fall back to LAN if needed.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://127.0.0.1:8000';
    }

    // iOS simulator can use localhost.
    return 'http://localhost:8000';
  }

  static String _httpToWs(String httpOrigin) {
    final u = httpOrigin.replaceFirst(RegExp(r'/$'), '');
    return u.replaceFirst(RegExp(r'^https?://'), 'ws://');
  }

  /// WebSocket origin aligned with [baseUrl].
  static String get wsBaseUrl {
    final runtime = _runtimeBaseUrlOverride;
    if (runtime != null && runtime.isNotEmpty) {
      return _httpToWs(runtime);
    }
    try {
      final env = AppConfig.apiBaseUrl;
      if (env != null && env.isNotEmpty) {
        return _httpToWs(env);
      }
    } catch (_) {
      // dotenv not loaded yet - use defaults
    }
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        _androidAutoBaseUrl != null) {
      return _httpToWs(_androidAutoBaseUrl!);
    }
    if (kIsWeb) return 'ws://localhost:8000';

    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'ws://localhost:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ws://127.0.0.1:8000';
    }

    return 'ws://localhost:8000';
  }

  static const String apiPrefix = '/api';
  static const String authPrefix = '$apiPrefix/auth';
  static const String profilePrefix = '$apiPrefix/profile';
  static const String donationsPrefix = '$apiPrefix/donations';
  static const String volunteersPrefix = '$apiPrefix/volunteers';
  static const String notificationsPrefix = '$apiPrefix/notifications';
  static const String paymentsPrefix = '$apiPrefix/payments';
  static const String adminPrefix = '$apiPrefix/admin';
  static const String requestsPrefix = '$apiPrefix/requests';
  static const String supportPrefix = '$apiPrefix/support';
  static const String messagesPrefix = '$apiPrefix/messages';
  static const String chatPrefix = '$apiPrefix/chat';

  /// Life donation endpoints.
  static const String lifeBloodStatus = '$apiPrefix/blood/status/';
  static const String lifeBloodRegister = '$apiPrefix/blood/register/';
  static const String lifeOrganStatus = '$apiPrefix/organ/status/';
  static const String lifeOrganPledge = '$apiPrefix/organ/pledge/';

  /// Stripe publishable key loaded from .env.
  static String get stripePublishableKey {
    try {
      return _stripeKey ?? 'pk_test_placeholder';
    } catch (_) {
      return 'pk_test_placeholder';
    }
  }

  static String? _stripeKey;

  /// Set after .env loads in main.dart.
  static void setStripeKey(String? key) {
    _stripeKey = key;
  }
}
