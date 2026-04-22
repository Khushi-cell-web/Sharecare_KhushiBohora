import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../constants/api_constants.dart';

/// Read timeout duration (fail fast to avoid hanging UI).
const Duration _readRequestTimeout = Duration(seconds: 10);

/// Write timeout duration (creates/updates may trigger server-side processing).
const Duration _writeRequestTimeout = Duration(seconds: 25);

/// Base HTTP client for ShareCare backend.
class ApiService {
  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? ApiConstants.baseUrl;

  final String _baseUrl;

  String get baseUrl => _baseUrl;

  String? get _fallbackBaseUrl {
    try {
      final fallback = AppConfig.apiLanFallbackBaseUrl.trim();
      if (fallback.isEmpty) return null;
      final normalized = fallback.replaceFirst(RegExp(r'/$'), '');
      if (normalized == _baseUrl) return null;
      return normalized;
    } catch (_) {
      return null;
    }
  }

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Uri _uriForBase(
    String base,
    String path, [
    Map<String, String>? queryParams,
  ]) {
    final uri = Uri.parse('$base$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Map<String, String> _defaultHeaders(Map<String, String>? extra) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (extra != null) map.addAll(extra);
    return map;
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    try {
      return await http
          .get(_uri(path, queryParams), headers: _defaultHeaders(headers))
          .timeout(
            _readRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    } on TimeoutException {
      final fallback = _fallbackBaseUrl;
      if (fallback == null) rethrow;
      return http
          .get(
            _uriForBase(fallback, path, queryParams),
            headers: _defaultHeaders(headers),
          )
          .timeout(
            _readRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    } on SocketException {
      final fallback = _fallbackBaseUrl;
      if (fallback == null) rethrow;
      return http
          .get(
            _uriForBase(fallback, path, queryParams),
            headers: _defaultHeaders(headers),
          )
          .timeout(
            _readRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    }
  }

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final encodedBody = body is String
        ? body
        : (body != null ? jsonEncode(body) : null);
    try {
      return await http
          .post(
            _uri(path),
            headers: _defaultHeaders(headers),
            body: encodedBody,
          )
          .timeout(
            _writeRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    } on TimeoutException {
      final fallback = _fallbackBaseUrl;
      if (fallback == null || _baseUrl == fallback) rethrow;
      return http
          .post(
            _uriForBase(fallback, path),
            headers: _defaultHeaders(headers),
            body: encodedBody,
          )
          .timeout(
            _writeRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    } on SocketException {
      final fallback = _fallbackBaseUrl;
      if (fallback == null) rethrow;
      return http
          .post(
            _uriForBase(fallback, path),
            headers: _defaultHeaders(headers),
            body: encodedBody,
          )
          .timeout(
            _writeRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    }
  }

  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final encodedBody = body is String
        ? body
        : (body != null ? jsonEncode(body) : null);
    try {
      return await http
          .put(_uri(path), headers: _defaultHeaders(headers), body: encodedBody)
          .timeout(
            _writeRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    } on TimeoutException {
      final fallback = _fallbackBaseUrl;
      if (fallback == null) rethrow;
      return http
          .put(
            _uriForBase(fallback, path),
            headers: _defaultHeaders(headers),
            body: encodedBody,
          )
          .timeout(
            _writeRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    } on SocketException {
      final fallback = _fallbackBaseUrl;
      if (fallback == null) rethrow;
      return http
          .put(
            _uriForBase(fallback, path),
            headers: _defaultHeaders(headers),
            body: encodedBody,
          )
          .timeout(
            _writeRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    }
  }

  Future<http.Response> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final encodedBody = body is String
        ? body
        : (body != null ? jsonEncode(body) : null);
    try {
      return await http
          .patch(
            _uri(path),
            headers: _defaultHeaders(headers),
            body: encodedBody,
          )
          .timeout(
            _writeRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    } on TimeoutException {
      final fallback = _fallbackBaseUrl;
      if (fallback == null) rethrow;
      return http
          .patch(
            _uriForBase(fallback, path),
            headers: _defaultHeaders(headers),
            body: encodedBody,
          )
          .timeout(
            _writeRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    } on SocketException {
      final fallback = _fallbackBaseUrl;
      if (fallback == null) rethrow;
      return http
          .patch(
            _uriForBase(fallback, path),
            headers: _defaultHeaders(headers),
            body: encodedBody,
          )
          .timeout(
            _writeRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    }
  }

  Future<http.Response> multipartPost(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    Map<String, dynamic>? files,
  }) async {
    Future<http.Response> sendTo(Uri uri) async {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_defaultHeaders(headers)..remove('Content-Type'));
      if (fields != null) {
        for (final e in fields.entries) {
          request.fields[e.key] = e.value;
        }
      }
      if (files != null) {
        for (final e in files.entries) {
          if (e.value is http.MultipartFile) {
            request.files.add(e.value as http.MultipartFile);
          } else if (e.value is List<int>) {
            request.files.add(
              http.MultipartFile.fromBytes(
                e.key,
                e.value as List<int>,
                filename: e.key,
              ),
            );
          }
        }
      }
      final stream = await request.send();
      return http.Response.fromStream(stream).timeout(
        _writeRequestTimeout,
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );
    }

    try {
      return await sendTo(_uri(path));
    } on TimeoutException {
      final fallback = _fallbackBaseUrl;
      if (fallback == null) rethrow;
      return sendTo(_uriForBase(fallback, path));
    } on SocketException {
      final fallback = _fallbackBaseUrl;
      if (fallback == null) rethrow;
      return sendTo(_uriForBase(fallback, path));
    }
  }

  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    try {
      return await http
          .delete(_uri(path), headers: _defaultHeaders(headers))
          .timeout(
            _writeRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    } on TimeoutException {
      final fallback = _fallbackBaseUrl;
      if (fallback == null) rethrow;
      return http
          .delete(
            _uriForBase(fallback, path),
            headers: _defaultHeaders(headers),
          )
          .timeout(
            _writeRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    } on SocketException {
      final fallback = _fallbackBaseUrl;
      if (fallback == null) rethrow;
      return http
          .delete(
            _uriForBase(fallback, path),
            headers: _defaultHeaders(headers),
          )
          .timeout(
            _writeRequestTimeout,
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
    }
  }
}
