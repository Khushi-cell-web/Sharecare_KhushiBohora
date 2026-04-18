import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime config from .env (assets/.env).
/// Edit assets/.env with your Stripe key and optional API base URL.
class AppConfig {
  AppConfig._();

  static const String _apiBaseUrlFromDefine = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get stripePublishableKey {
    try {
      final key = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
      return key.trim();
    } catch (_) {
      return 'pk_test_placeholder';
    }
  }

  /// API base URL (e.g. http://192.168.1.5:8000 for physical device).
  /// If unset, empty, or "auto", [ApiConstants] uses per-platform defaults
  /// (localhost on desktop/web, 10.0.2.2 on Android emulator).
  static String? get apiBaseUrl {
    try {
      final fromDefine = _apiBaseUrlFromDefine.trim();
      if (fromDefine.isNotEmpty) {
        if (!fromDefine.startsWith('http://') &&
            !fromDefine.startsWith('https://')) {
          return 'http://$fromDefine';
        }
        return fromDefine;
      }

      final url = dotenv.env['API_BASE_URL'] ?? '';
      final trimmed = url.trim();
      if (trimmed.isEmpty) return null;
      final lower = trimmed.toLowerCase();
      if (lower == 'auto' || lower == 'default') return null;
      if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
        return 'http://$trimmed';
      }
      return trimmed;
    } catch (_) {
      return null;
    }
  }

  /// LAN fallback for real Android devices when `API_BASE_URL=auto`.
  /// Keep this aligned with your PC IPv4 running Django.
  static String get apiLanFallbackBaseUrl {
    try {
      final url = dotenv.env['API_LAN_FALLBACK_BASE_URL'] ?? '';
      final trimmed = url.trim();
      if (trimmed.isNotEmpty) {
        if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
          return 'http://$trimmed';
        }
        return trimmed;
      }
    } catch (_) {}
    return 'http://192.168.43.57:8000';
  }

  /// Google OAuth web/server client ID for Android Google Sign-In.
  /// Required by google_sign_in 7.x on Android when google-services.json is absent.
  static String? get googleServerClientId {
    try {
      final v = (dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '').trim();
      if (v.isEmpty) return null;
      return v;
    } catch (_) {
      return null;
    }
  }
}
