import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

/// Request timeout duration (fail fast to avoid ANR when backend is down).
const Duration _requestTimeout = Duration(seconds: 10);

/// Base HTTP client for ShareCare backend.
class ApiService {
  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? ApiConstants.baseUrl;

  final String _baseUrl;

  String get baseUrl => _baseUrl;

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('$_baseUrl$path');
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
    return http
        .get(_uri(path, queryParams), headers: _defaultHeaders(headers))
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException('Connection timed out'),
        );
  }

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http
        .post(
          _uri(path),
          headers: _defaultHeaders(headers),
          body: body is String
              ? body
              : (body != null ? jsonEncode(body) : null),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException('Connection timed out'),
        );
  }

  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http
        .put(
          _uri(path),
          headers: _defaultHeaders(headers),
          body: body is String
              ? body
              : (body != null ? jsonEncode(body) : null),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException('Connection timed out'),
        );
  }

  Future<http.Response> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http
        .patch(
          _uri(path),
          headers: _defaultHeaders(headers),
          body: body is String
              ? body
              : (body != null ? jsonEncode(body) : null),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException('Connection timed out'),
        );
  }

  Future<http.Response> multipartPost(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    Map<String, dynamic>? files,
  }) async {
    final uri = _uri(path);
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
    return await http.Response.fromStream(stream).timeout(
      _requestTimeout,
      onTimeout: () => throw TimeoutException('Connection timed out'),
    );
  }

  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    return http
        .delete(_uri(path), headers: _defaultHeaders(headers))
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException('Connection timed out'),
        );
  }
}
