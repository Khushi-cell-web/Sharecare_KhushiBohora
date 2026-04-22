import 'dart:collection';
import 'dart:convert';

import 'package:frontendsharecare/core/services/api_service.dart';
import 'package:http/http.dart' as http;

/// Captures request details so tests can assert path, payload, and query params.
class ApiRequestCapture {
  ApiRequestCapture({
    required this.method,
    required this.path,
    this.headers,
    this.queryParams,
    this.body,
  });

  final String method;
  final String path;
  final Map<String, String>? headers;
  final Map<String, String>? queryParams;
  final Object? body;
}

/// In-memory fake for [ApiService] that queues deterministic responses.
class FakeApiService extends ApiService {
  FakeApiService() : super(baseUrl: 'http://localhost:8000');

  final List<ApiRequestCapture> requests = <ApiRequestCapture>[];
  final Map<String, Queue<http.Response>> _responseQueues =
      <String, Queue<http.Response>>{};

  String _key(String method, String path) => '${method.toUpperCase()} $path';

  /// Queue a raw response for a specific method/path pair.
  void queueResponse({
    required String method,
    required String path,
    required http.Response response,
  }) {
    final queue = _responseQueues.putIfAbsent(
      _key(method, path),
      () => Queue<http.Response>(),
    );
    queue.add(response);
  }

  /// Queue a JSON response body for a specific method/path pair.
  void queueJsonResponse({
    required String method,
    required String path,
    required int statusCode,
    Object? jsonBody,
  }) {
    queueResponse(
      method: method,
      path: path,
      response: http.Response(
        jsonBody == null ? '' : jsonEncode(jsonBody),
        statusCode,
        headers: const <String, String>{'content-type': 'application/json'},
      ),
    );
  }

  ApiRequestCapture lastRequest(String method, String path) {
    final normalizedMethod = method.toUpperCase();
    for (final request in requests.reversed) {
      if (request.method == normalizedMethod && request.path == path) {
        return request;
      }
    }
    throw StateError('No request captured for $normalizedMethod $path');
  }

  Future<http.Response> _handle({
    required String method,
    required String path,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    Object? body,
  }) async {
    final normalizedMethod = method.toUpperCase();
    requests.add(
      ApiRequestCapture(
        method: normalizedMethod,
        path: path,
        headers: headers,
        queryParams: queryParams,
        body: body,
      ),
    );

    final queue = _responseQueues[_key(normalizedMethod, path)];
    if (queue == null || queue.isEmpty) {
      throw StateError('No queued response for $normalizedMethod $path');
    }

    return queue.removeFirst();
  }

  @override
  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) {
    return _handle(
      method: 'GET',
      path: path,
      headers: headers,
      queryParams: queryParams,
    );
  }

  @override
  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _handle(method: 'POST', path: path, headers: headers, body: body);
  }

  @override
  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _handle(method: 'PUT', path: path, headers: headers, body: body);
  }

  @override
  Future<http.Response> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _handle(method: 'PATCH', path: path, headers: headers, body: body);
  }

  @override
  Future<http.Response> delete(String path, {Map<String, String>? headers}) {
    return _handle(method: 'DELETE', path: path, headers: headers);
  }

  @override
  Future<http.Response> multipartPost(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    Map<String, dynamic>? files,
  }) {
    return _handle(method: 'POST', path: path, headers: headers, body: fields);
  }
}

Map<String, dynamic> requestBodyAsMap(ApiRequestCapture request) {
  final body = request.body;
  if (body == null) return <String, dynamic>{};

  if (body is Map<String, dynamic>) return body;

  if (body is Map) {
    return body.map((key, value) => MapEntry(key.toString(), value));
  }

  if (body is String && body.isNotEmpty) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  }

  throw StateError('Request body is not a JSON map: ${body.runtimeType}');
}
