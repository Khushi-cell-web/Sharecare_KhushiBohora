import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../services/sharecare_api_service.dart';

/// Maps API and network errors to safe user-facing messages.
class NetworkErrorHelper {
  NetworkErrorHelper._();

  /// Turns an exception into a short UI message.
  static String toUserMessage(Object error) {
    final s = error.toString();

    // Hide auth details from backend responses.
    if (s.contains('No active account found with the given credentials') ||
        s.contains('Incorrect username or password')) {
      return 'Incorrect username or password. Please try again.';
    }

    if (s.contains('token_not_valid') ||
        s.contains('Token is expired') ||
        (s.contains('ShareCareApiException(401)') &&
            !s.contains('No active account')) ||
        s.contains('Given token not valid') ||
        (s.contains('401') && (s.contains('token') || s.contains('expired')))) {
      return 'Session expired. Please log in again.';
    }

    // Typed API errors.
    if (error is ShareCareApiException) {
      if (error.statusCode == 401) {
        if (error.body.toLowerCase().contains('no active account') ||
            error.body.toLowerCase().contains('incorrect') ||
            error.body.toLowerCase().contains('invalid credentials') ||
            error.body.toLowerCase().contains('detail')) {
          return 'Incorrect username or password. Please try again.';
        }
        return 'Session expired. Please log in again.';
      }
      if (error.statusCode == 403) {
        final body = error.body.toLowerCase();
        if (body.contains('verified') || body.contains('verification')) {
          return 'Your organization must be verified before creating requests.';
        }
        if (body.contains('volunteer')) {
          return 'This action is only available for volunteer accounts.';
        }
        if (body.contains('ngo') || body.contains('hospital')) {
          return 'This action is only available for NGO/Hospital accounts.';
        }
        return 'You don\'t have permission to do this.';
      }
      if (error.statusCode == 404) {
        return 'The requested item was not found.';
      }
      if (error.statusCode == 500 ||
          error.statusCode == 502 ||
          error.statusCode == 503 ||
          error.body.contains('ProgrammingError') ||
          (error.body.contains('relation ') &&
              error.body.contains('does not exist')) ||
          (error.body.contains('api_user') && error.body.contains('exist'))) {
        final msg = error.message.trim();
        final lower = msg.toLowerCase();
        final looksTechnical =
            lower.contains('traceback') ||
            lower.contains('exception') ||
            lower.contains('programmingerror') ||
            lower.contains('<!doctype') ||
            lower.contains('<html') ||
            lower.contains('does not exist');
        if (msg.isNotEmpty && msg.length <= 180 && !looksTechnical) {
          return msg;
        }
        return 'Server is temporarily unavailable. Please try again later.';
      }
      if (error.statusCode == 400) {
        final msg = error.message;
        if (msg.toLowerCase().contains('stripe') &&
            msg.toLowerCase().contains('configured')) {
          return 'Card payment is not set up. Add Stripe keys to backend and frontend .env.';
        }
        if (msg.length <= 200 &&
            !msg.contains('{') &&
            !msg.contains('Exception')) {
          return msg;
        }
        return 'Invalid request. Please check your input and try again.';
      }
      final msg = error.message;
      if (msg.toLowerCase().contains('token') ||
          msg.contains('expired') ||
          msg.contains('not valid')) {
        return 'Session expired. Please log in again.';
      }
      return msg.length > 120 ? '${msg.substring(0, 120)}...' : msg;
    }

    // Database-style backend failures.
    if (s.contains('ProgrammingError') ||
        (s.contains('relation ') && s.contains('does not exist')) ||
        (s.contains('api_user') && s.contains('exist'))) {
      return 'Server is temporarily unavailable. Please try again later.';
    }

    // Connection failures.
    if (s.contains('SocketException') ||
        s.contains('Connection timed out') ||
        s.contains('Connection refused') ||
        s.contains('connection abort') ||
        s.contains('ClientException') ||
        (s.contains('Connection timed out') && s.contains('address =')) ||
        (s.contains('uri=http') &&
            (s.contains('timed out') || s.contains('refused')))) {
      return 'Unable to connect. Please check that the backend is running (see run steps) and try again.';
    }
    if (s.contains('TimeoutException') || s.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }
    if (s.contains('HandshakeException') ||
        s.contains('CertificateException')) {
      return 'Connection error. Please check your network.';
    }
    if (s.contains('FormatException') || s.contains('json')) {
      return 'Invalid response from server. Please try again later.';
    }

    // Raw URI/address failures.
    if (s.contains('uri=http') ||
        (s.contains('address =') && s.contains('port ='))) {
      return _connectionFailedMessage();
    }

    // Last resort for technical-looking text.
    if (s.contains('Exception') ||
        s.contains('Error:') ||
        s.contains(' at ') ||
        s.contains('{') ||
        s.length > 100) {
      return 'Something went wrong. Please try again.';
    }
    final result = s.length > 80 ? '${s.substring(0, 80)}...' : s;
    // Final auth safeguard.
    if (result.toLowerCase().contains('token') && result.contains('valid')) {
      return 'Session expired. Please log in again.';
    }
    return result;
  }

  static String _connectionFailedMessage() {
    final url = ApiConstants.resolvedBaseUrl;
    if (kDebugMode) {
      return 'Cannot reach backend at $url. '
          'Physical phone + auto uses API_LAN_FALLBACK_BASE_URL. '
          'For Wi‑Fi, set API_BASE_URL to your PC LAN IP (ipconfig). '
          'Start Django: python manage.py runserver 0.0.0.0:8000';
    }
    return 'Cannot reach the server at $url. Check Wi‑Fi, API_BASE_URL in assets/.env, '
        'API_LAN_FALLBACK_BASE_URL for physical Android auto mode, and Django on 0.0.0.0:8000.';
  }
}
