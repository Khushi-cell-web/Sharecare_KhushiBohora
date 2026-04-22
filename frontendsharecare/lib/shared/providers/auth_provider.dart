import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_model.dart';
import '../../core/services/sharecare_api_service.dart';
import '../../core/services/health_check_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/network_error_helper.dart';

/// Auth state and token storage for ShareCare.
class AuthProvider extends ChangeNotifier {
  AuthProvider({FlutterSecureStorage? storage, ShareCareApiService? api})
    : _storage = storage ?? const FlutterSecureStorage(),
      _api = api ?? ShareCareApiService();

  final FlutterSecureStorage _storage;
  ShareCareApiService _api;

  static const _keyAccessToken = 'sharecare_access_token';
  static const _keyRefreshToken = 'sharecare_refresh_token';

  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  String? _error;
  UserModel? _user;

  void _refreshApiClientFromRuntime() {
    _api = ShareCareApiService();
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserModel? get user => _user;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadTokens() async {
    _isLoading = true;
    notifyListeners();
    try {
      _accessToken = await _storage.read(key: _keyAccessToken);
      _refreshToken = await _storage.read(key: _keyRefreshToken);
      if (_accessToken != null) {
        await loadUser();
        _registerFcmToken();
      }
    } catch (_) {
      // ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _registerFcmToken() async {
    try {
      final token = await NotificationService.getToken();
      if (token != null && isAuthenticated) {
        await NotificationService().registerToken(authHeaders, token);
      }
    } catch (_) {
      // ignore
    }
  }

  /// Call after login to register FCM token.
  Future<void> registerFcmToken() => _registerFcmToken();

  Future<void> loadUser() async {
    if (!isAuthenticated) return;
    try {
      _user = await _api.me(authHeaders);
      notifyListeners();
    } on ShareCareApiException catch (e) {
      if (e.statusCode == 401) {
        final refreshed = await tryRefreshToken();
        if (refreshed) {
          try {
            _user = await _api.me(authHeaders);
            notifyListeners();
          } catch (_) {
            await logout();
          }
        } else {
          await logout();
        }
      } else if (e.statusCode == 403) {
        await logout();
      } else {
        _user = null;
        notifyListeners();
      }
    } catch (_) {
      _user = null;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.login(username, password);
      final access = data['access'] as String?;
      final refresh = data['refresh'] as String?;
      if (access != null && refresh != null) {
        await saveTokens(access: access, refresh: refresh);
        await loadUser();
        _registerFcmToken();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = 'Invalid response from server';
    } on ShareCareApiException catch (e) {
      _error = NetworkErrorHelper.toUserMessage(e);
    } catch (e) {
      // If the first login fails due a bad host selection, probe backend health
      // and retry once with the runtime-resolved base URL.
      final raw = e.toString().toLowerCase();
      final looksLikeConnectivityIssue =
          raw.contains('socketexception') ||
          raw.contains('clientexception') ||
          raw.contains('connection timed out') ||
          raw.contains('connection refused') ||
          raw.contains('failed host lookup') ||
          raw.contains('timed out');

      if (looksLikeConnectivityIssue) {
        try {
          final (connected, _) = await HealthCheckService().check();
          if (connected) {
            _refreshApiClientFromRuntime();
            final retriedData = await _api.login(username, password);
            final access = retriedData['access'] as String?;
            final refresh = retriedData['refresh'] as String?;
            if (access != null && refresh != null) {
              await saveTokens(access: access, refresh: refresh);
              await loadUser();
              _registerFcmToken();
              _isLoading = false;
              notifyListeners();
              return true;
            }
          }
        } catch (_) {
          // Fall through to normal mapped error below.
        }
      }

      _error = NetworkErrorHelper.toUserMessage(e);
    }
    if (_error != null &&
        (_error!.contains('uri=') ||
            _error!.contains('SocketException') ||
            _error!.contains('ClientException') ||
            _error!.contains('address ='))) {
      _error = NetworkErrorHelper.toUserMessage(_error!);
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> loginWithGoogleIdToken(String idToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.googleLogin(idToken);
      final access = data['access'] as String?;
      final refresh = data['refresh'] as String?;
      if (access != null && refresh != null) {
        await saveTokens(access: access, refresh: refresh);
        await loadUser();
        _registerFcmToken();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = 'Invalid response from server';
    } on ShareCareApiException catch (e) {
      _error = NetworkErrorHelper.toUserMessage(e);
    } catch (e) {
      _error = NetworkErrorHelper.toUserMessage(e);
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    required String role,
    String? firstName,
    String? lastName,
    String? phone,
    String? organization,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.register(
        username: username,
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        role: role,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        organization: organization,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ShareCareApiException catch (e) {
      _error = NetworkErrorHelper.toUserMessage(e);
    } catch (e) {
      _error = NetworkErrorHelper.toUserMessage(e);
    }
    if (_error != null &&
        (_error!.contains('uri=') ||
            _error!.contains('SocketException') ||
            _error!.contains('ClientException') ||
            _error!.contains('address ='))) {
      _error = NetworkErrorHelper.toUserMessage(_error!);
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> saveTokens({String? access, String? refresh}) async {
    if (access != null) {
      await _storage.write(key: _keyAccessToken, value: access);
      _accessToken = access;
    }
    if (refresh != null) {
      await _storage.write(key: _keyRefreshToken, value: refresh);
      _refreshToken = refresh;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await clearTokens();
    _user = null;
    _error = null;
    notifyListeners();
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
  }

  /// Refreshes access token. Returns false when re-login is required.
  Future<bool> tryRefreshToken() async {
    final refresh = _refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final access = await _api.refreshToken(refresh);
      await saveTokens(access: access);
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }

  Map<String, String> get authHeaders {
    if (_accessToken == null) return {};
    return {'Authorization': 'Bearer $_accessToken'};
  }
}
