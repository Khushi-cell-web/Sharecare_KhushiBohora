# Backend Connection Startup Analysis - ShareCare Flutter App

## Summary
The app makes its **first backend connection attempt when loading user data during AuthProvider initialization**, followed by dashboard-specific API calls. Connection failures are caught but may be silently hidden with try-catch blocks that only update state.

---

## 1. STARTUP FLOW

### Phase 1: App Initialization (main.dart)
**File:** [lib/main.dart](lib/main.dart#L80-L110)  
**Lines:** 80-110

**First Connection Attempt (BEFORE UI):**
```dart
// main.dart, lines 80-110
await ApiConstants.initialize();  // Resolves API URL for platform
// ... Firebase/Notification init
runApp(const ShareCareApp());
```

**Initial URL Resolution (Key Issue):**
- [lib/core/constants/api_constants.dart](lib/core/constants/api_constants.dart#L10-L30) - Lines 10-30
- For Android emulator: defaults to `http://10.0.2.2:8000`
- For physical Android: uses `API_LAN_FALLBACK_BASE_URL` from env
- For desktop/web: uses `localhost:8000` or `API_BASE_URL` from env

---

### Phase 2: AuthProvider Initialization  
**File:** [lib/shared/providers/auth_provider.dart](lib/shared/providers/auth_provider.dart#L37-L65)  
**Lines:** 37-65

**FIRST BACKEND API CALL:**
```dart
// In ShareCareApp.build() at line 114:
ChangeNotifierProvider(create: (_) => AuthProvider()..loadTokens())

// In AuthProvider.loadTokens() at lines 37-65:
Future<void> loadTokens() async {
  _isLoading = true;
  notifyListeners();
  try {
    _accessToken = await _storage.read(key: _keyAccessToken);
    _refreshToken = await _storage.read(key: _keyRefreshToken);
    if (_accessToken != null) {
      await loadUser();  // 🔴 FIRST BACKEND CALL HERE
      _registerFcmToken();
    }
  } catch (_) {
    // ⚠️ SILENT FAILURE - Exception is caught and ignored
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**⚠️ Silent Failure Point #1:**
- Lines 61-63: General exception is silently caught
- User won't see error if backend unreachable at this point
- `_user` will be `null` but app continues

---

### Phase 2.1: Load User (Initial Auth Check)
**File:** [lib/shared/providers/auth_provider.dart](lib/shared/providers/auth_provider.dart#L71-L98)  
**Lines:** 71-98

**THE ACTUAL FIRST BACKEND CONNECTION:**
```dart
Future<void> loadUser() async {
  if (!isAuthenticated) return;
  try {
    _user = await _api.me(authHeaders);  // 🔴 HTTP GET: /api/auth/me/
    notifyListeners();
  } on ShareCareApiException catch (e) {
    if (e.statusCode == 401) {
      // Try refresh token...
      final refreshed = await tryRefreshToken();
      if (refreshed) {
        try {
          _user = await _api.me(authHeaders);  // 🔴 RETRY CALL
          notifyListeners();
        } catch (_) {
          await logout();  // ⚠️ Silent catch on retry
        }
      } else {
        await logout();
      }
    } else if (e.statusCode == 403) {
      await logout();
    } else {
      _user = null;
      notifyListeners();  // ⚠️ User becomes null, no error shown
    }
  } catch (_) {
    _user = null;
    notifyListeners();  // ⚠️ General exception silently caught
  }
}
```

**API Call Details:**
- **Endpoint:** `GET /api/auth/me/`
- **Headers:** Authorization bearer token
- **Line:** 76 (the `_api.me(authHeaders)` call)
- **File:** [lib/core/services/sharecare_api_service.dart](lib/core/services/sharecare_api_service.dart#L87-L90) - Lines 87-90
  ```dart
  Future<UserModel> me(Map<String, String> authHeaders) async {
    final r = await _api.get(
      '${ApiConstants.authPrefix}/me/',
      headers: _headers(authHeaders),
    );
    if (r.statusCode != 200) throw ShareCareApiException(r.statusCode, r.body);
    return UserModel.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }
  ```

---

## 2. FLOW AFTER AUTHENTICATION

### Phase 3: Auth Gate Rendering
**File:** [lib/screens/auth_gate_screen.dart](lib/screens/auth_gate_screen.dart)  
**Lines:** 1-75

Shows loading spinner while `auth.isLoading == true`:
```dart
if (auth.isLoading) {
  // Loading screen displayed
  return Scaffold(...CircularProgressIndicator...);
}

// Once loaded, routes based on auth state
if (auth.isAuthenticated) {
  if (auth.user?.role == 'volunteer') {
    return const VolunteerHubScreen();
  }
  return const MainShellScreen();
}
return const WelcomeScreen();
```

---

### Phase 4: Dashboard-Specific Initialization

After auth gate clears, the app routes to role-based dashboards. Each makes its own API calls:

#### 4A: Donor Dashboard (HomeScreen)
**File:** [lib/screens/home_screen.dart](lib/screens/home_screen.dart)  
**Lines:** 190-230 (initState and _loadRequests)

**API Calls Made:**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) => _loadRequests());
}

Future<void> _loadRequests() async {
  // Line 206-218
  final list = await _api.getRequests(
    authHeaders: auth.authHeaders,
    status: 'open',
  );
  if (mounted) setState(() => _requests = list);
  
  try {
    final recs = await _api.getRecommendations(auth.authHeaders);
    // ...
  } catch (_) {}  // ⚠️ Silent failure
  
  try {
    final stats = await _api.getDonationStats(auth.authHeaders);
    // ...
  } catch (_) {
    if (mounted) setState(() => _livesTouched = 0);
  }  // ⚠️ Silent failure
}
```

**Endpoints:**
1. `GET /api/donations/requests/?status=open` (Line 210)
2. `GET /api/recommendations/` (Line 217) - ⚠️ Silently fails
3. `GET /api/donations/stats/` (Line 223) - ⚠️ Silently fails

---

#### 4B: NGO Dashboard (NgoDashboardScreen)
**File:** [lib/screens/dashboards/ngo_dashboard_screen.dart](lib/screens/dashboards/ngo_dashboard_screen.dart)  
**Lines:** 30-50

**API Calls Made:**
```dart
Future<void> _load() async {
  // Line 42
  final list = await _api.getMyRequests(auth.authHeaders);
  if (mounted) setState(() => _requests = list);
}
```

**Endpoint:**
- `GET /api/donations/my-requests/` (Line 42)

---

#### 4C: Volunteer Dashboard (VolunteerDashboardTab)
**File:** [lib/features/volunteers/screens/volunteer_dashboard_tab.dart](lib/features/volunteers/screens/volunteer_dashboard_tab.dart#L48-L75)  
**Lines:** 48-75

**API Calls Made:**
```dart
Future<void> _load() async {
  await auth.loadUser();  // Reload user
  final results = await Future.wait([
    _api.getAvailableRequestsForVolunteer(auth.authHeaders),  // Line 61
    _api.getMyTasks(auth.authHeaders),  // Line 62
  ]);
}
```

**Endpoints:**
1. `GET /api/donations/available/` (Line 61)
2. `GET /api/volunteers/my-tasks/` (Line 62)

---

#### 4D: Admin Dashboard (AdminDashboardScreen)
**File:** [lib/screens/dashboards/admin_dashboard_screen.dart](lib/screens/dashboards/admin_dashboard_screen.dart#L33-L55)  
**Lines:** 33-55

**API Calls Made:**
```dart
Future<void> _load() async {
  // Line 50
  final data = await _api.getAdminDashboard(auth.authHeaders);
  if (mounted) {
    setState(() {
      _data = data;
      _error = null;
    });
  }
}
```

**Endpoint:**
- `GET /api/admin/dashboard/` (Line 50)

---

## 3. ERROR HANDLING & SILENT FAILURES

### Where "Backend Not Connected" Message is Generated

**File:** [lib/core/utils/network_error_helper.dart](lib/core/utils/network_error_helper.dart#L120-L160)  
**Lines:** 120-160

```dart
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
```

### Detection Logic
**Lines:** 106-116
```dart
if (s.contains('SocketException') ||
    s.contains('Connection timed out') ||
    s.contains('Connection refused') ||
    s.contains('connection abort') ||
    s.contains('ClientException') ||
    (s.contains('Connection timed out') && s.contains('address =')) ||
    (s.contains('uri=http') &&
        (s.contains('timed out') || s.contains('refused')))) {
  return 'Unable to connect. Please check that the backend is running...';
}
```

---

## 4. CRITICAL SILENT FAILURE POINTS

| Location | Code | Issue |
|----------|------|-------|
| [auth_provider.dart:63](lib/shared/providers/auth_provider.dart#L63) | `catch (_) { // ignore }` | Exceptions in loadTokens() are silently caught - user sees "Preparing ShareCare..." forever if backend down |
| [auth_provider.dart:88](lib/shared/providers/auth_provider.dart#L88) | `catch (_) { ... await logout(); }` | Silent catch on retry after 401 |
| [auth_provider.dart:93](lib/shared/providers/auth_provider.dart#L93) | `catch (_) { _user = null; }` | Non-401/403 errors silently set user to null without displaying error |
| [home_screen.dart:217](lib/screens/home_screen.dart#L217) | `catch (_) {}` | Recommendations API failure completely silenced |
| [home_screen.dart:223](lib/screens/home_screen.dart#L223) | `catch (_) { ... }` | Stats API failure silenced |
| [volunteer_dashboard_tab.dart:70](lib/features/volunteers/screens/volunteer_dashboard_tab.dart#L70) | `catch (e) { ... setState(() { _error = ... }); }` | Error IS displayed (good!) |

---

## 5. HTTP CLIENT & TIMEOUT CONFIGURATION

**File:** [lib/core/services/api_service.dart](lib/core/services/api_service.dart#L1-L80)  
**Lines:** 1-80

**Request Timeout:** 10 seconds (Line 7)
```dart
const Duration _requestTimeout = Duration(seconds: 10);
```

**GET Request Implementation:**
```dart
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
```

Timeout throws: `TimeoutException('Connection timed out')` - converted to user message on line 110 of network_error_helper.dart

---

## 6. SUMMARY: WHERE BACKEND NOT CONNECTED FIRST APPEARS

### Timeline of Connection Attempts:

1. **T+0ms**: App starts
2. **T+100ms**: `ApiConstants.initialize()` resolves API URL (no HTTP yet)
3. **T+200ms**: `AuthProvider()..loadTokens()` starts
4. **T+300ms**: `loadTokens()` checks for stored tokens
5. **T+400ms**: IF TOKEN EXISTS → `loadUser()` makes **FIRST HTTP REQUEST**: `GET /api/auth/me/`
6. **T+400-10,400ms**: Waits for response (10 second timeout)
7. **T+10,400ms**: If timeout/connection error → **"Backend not connected" appears** in error handler

### If Backend is Down:
- **User sees:** "Preparing ShareCare..." (loading screen) - because exception is silently caught in `loadTokens()`
- **OR:** If error is displayed, user sees connection error message
- **OR:** User gets logged out silently if not authenticated anymore

### Where Error Message Surfaces:
- Dashboard-specific errors: Caught and displayed via `NetworkErrorHelper.toUserMessage()`
- Auth errors: Silently caught on retry (line 88) but may show generic message
- Silent failures: Recommendations & stats APIs fail silently with no user notification

---

## 7. KEY FILES REFERENCE

| File | Purpose | Key Lines |
|------|---------|-----------|
| [main.dart](lib/main.dart) | App entry, ApiConstants init, AuthProvider creation | 80-114 |
| [auth_provider.dart](lib/shared/providers/auth_provider.dart) | Token storage, loadTokens(), loadUser() | 37-98 |
| [auth_gate_screen.dart](lib/screens/auth_gate_screen.dart) | Shows loading or routes to dashboard | All |
| [sharecare_api_service.dart](lib/core/services/sharecare_api_service.dart) | API methods (login, me, getRequests, etc) | 87-90 (me method) |
| [api_service.dart](lib/core/services/api_service.dart) | HTTP client with 10s timeout | 38-51 |
| [network_error_helper.dart](lib/core/utils/network_error_helper.dart) | Error → user message mapping | 106-160 |
| [api_constants.dart](lib/core/constants/api_constants.dart) | API base URL resolution | 10-30 |

