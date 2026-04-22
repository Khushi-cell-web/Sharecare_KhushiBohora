import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

/// Health check for backend connectivity at startup.
class HealthCheckService {
  HealthCheckService({ApiService? apiService})
    : _api = apiService ?? ApiService();

  final ApiService _api;

  List<String> _candidateBaseUrls() {
    final candidates = <String>{};

    void addCandidate(String? origin) {
      final trimmed = origin?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      candidates.add(trimmed.replaceFirst(RegExp(r'/$'), ''));
    }

    addCandidate(_api.baseUrl);
    addCandidate(ApiConstants.baseUrl);
    addCandidate('http://localhost:8000');
    addCandidate('http://127.0.0.1:8000');
    addCandidate('http://10.0.2.2:8000');
    addCandidate(AppConfig.apiLanFallbackBaseUrl);

    return candidates.toList(growable: false);
  }

  Future<(bool, String?)> _probeBaseUrl(String baseUrl) async {
    final uri = Uri.parse('$baseUrl/api/health/');
    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      ApiConstants.setRuntimeBaseUrl(baseUrl);
      return (true, null);
    }
    return (false, 'Backend returned status ${response.statusCode}');
  }

  /// Check if backend is reachable. Returns (success, error message).
  Future<(bool, String?)> check() async {
    String? lastError;
    for (final baseUrl in _candidateBaseUrls()) {
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          final result = await _probeBaseUrl(baseUrl);
          if (result.$1) {
            if (kDebugMode) {
              debugPrint('✓ Backend health check passed at $baseUrl');
            }
            return (true, null);
          }

          lastError = result.$2;
          if (kDebugMode) {
            debugPrint('✗ Backend returned status at $baseUrl: ${result.$2}');
          }
        } catch (e) {
          lastError = e.toString();
          if (kDebugMode) {
            debugPrint('✗ Backend health check failed at $baseUrl: $lastError');
          }
        }

        if (attempt < 3) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    if (kDebugMode) {
      debugPrint('✗ Backend health check failed after probing all candidates');
      for (final baseUrl in _candidateBaseUrls()) {
        debugPrint('  Tried URL: $baseUrl');
      }
    }

    return (
      false,
      'Cannot reach backend. Tried: ${_candidateBaseUrls().join(', ')}. '
          'Check: (1) Django running on 0.0.0.0:8000, '
          '(2) Device/browser can reach that host, (3) Firewall allows access',
    );
  }
}
