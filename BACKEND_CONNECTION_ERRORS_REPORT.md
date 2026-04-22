# Backend Connection Error Messages - ShareCare Flutter App

## Summary
This report documents all backend connectivity error messages, their locations, triggers, and related variables in the ShareCare Flutter project at `frontendsharecare/lib`.

---

## 1. Primary Connection Error Handler

### File: [core/utils/network_error_helper.dart](core/utils/network_error_helper.dart)
**Purpose**: Maps API and network errors to safe user-facing messages

#### Error Message #1: Backend Not Running
- **Line**: 115
- **Exact Message**: `"Unable to connect. Please check that the backend is running (see run steps) and try again."`
- **Trigger Conditions**: When any of these patterns are detected:
  - `SocketException`
  - `Connection timed out`
  - `Connection refused`
  - `connection abort`
  - `ClientException`
  - `uri=http` combined with `timed out` or `refused`
- **Code Context** (lines 106-117):
```dart
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
```
- **Related Variables**: None (static message)
- **Caused By**: HTTP request failures when backend server is unreachable

---

#### Error Message #2: Backend URL Unreachable (Detailed)
- **Line**: 153
- **Exact Message**: 
  - **Debug Mode**: `"Cannot reach backend at $url. Physical phone + auto uses API_LAN_FALLBACK_BASE_URL. For Wi‑Fi, set API_BASE_URL to your PC LAN IP (ipconfig). Start Django: python manage.py runserver 0.0.0.0:8000"`
  - **Release Mode**: `"Cannot reach the server at $url. Check Wi‑Fi, API_BASE_URL in assets/.env, API_LAN_FALLBACK_BASE_URL for physical Android auto mode, and Django on 0.0.0.0:8000."`
- **Trigger Conditions**: When URI/address failure patterns detected (lines 144-146):
  - `s.contains('uri=http')`
  - `s.contains('address =') && s.contains('port =')`
- **Code Context** (lines 148-160):
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
- **Related Variables**: `ApiConstants.resolvedBaseUrl`

---

#### Error Message #3: Request Timeout
- **Line**: 120
- **Exact Message**: `"Request timed out. Please try again."`
- **Trigger Conditions**: 
  - `TimeoutException` exception
  - String contains `timed out`
- **Code Context** (lines 119-121):
```dart
if (s.contains('TimeoutException') || s.contains('timed out')) {
  return 'Request timed out. Please try again.';
}
```
- **Related Variables**: `_requestTimeout` (10 seconds) - defined in [core/services/api_service.dart](core/services/api_service.dart) line 8

---

#### Error Message #4: Handshake/Certificate Error
- **Line**: 122
- **Exact Message**: `"Connection error. Please check your network."`
- **Trigger Conditions**:
  - `HandshakeException`
  - `CertificateException`
- **Code Context** (lines 123-125):
```dart
if (s.contains('HandshakeException') ||
    s.contains('CertificateException')) {
  return 'Connection error. Please check your network.';
}
```

---

#### Error Message #5: Invalid Server Response
- **Line**: 127
- **Exact Message**: `"Invalid response from server. Please try again later."`
- **Trigger Conditions**:
  - `FormatException`
  - String contains `json`
- **Code Context** (lines 126-128):
```dart
if (s.contains('FormatException') || s.contains('json')) {
  return 'Invalid response from server. Please try again later.';
}
```

---

#### Error Message #6: Server Temporarily Unavailable
- **Lines**: 75, 103
- **Exact Message**: `"Server is temporarily unavailable. Please try again later."`
- **Trigger Conditions**:
  - HTTP Status Code: 500, 502, 503
  - Response contains `ProgrammingError`
  - Response contains database error patterns: `relation ... does not exist`
  - Response contains `api_user` and `exist`
- **Code Context** (lines 56-75 and 99-103):
```dart
if (error.statusCode == 500 ||
    error.statusCode == 502 ||
    error.statusCode == 503 ||
    error.body.contains('ProgrammingError') ||
    (error.body.contains('relation ') &&
        error.body.contains('does not exist')) ||
    (error.body.contains('api_user') && error.body.contains('exist'))) {
  final msg = error.message.trim();
  // ... validation ...
  return 'Server is temporarily unavailable. Please try again later.';
}
```
- **Related Variables**: 
  - `error.statusCode` (HTTP status)
  - `error.body` (response body)
  - `error.message` (parsed error message)

---

## 2. WebSocket Connection Errors

### File: [features/volunteers/screens/delivery_task_tracking_screen.dart](features/volunteers/screens/delivery_task_tracking_screen.dart)

#### Error Message #7: WebSocket Connection Error
- **Line**: 80
- **Exact Message**: `"Connection error. Pull to reconnect or check your network."`
- **Trigger Conditions**: WebSocket stream `onError` callback triggered
- **Code Context** (lines 76-81):
```dart
onError: (_) {
  if (mounted) {
    setState(() {
      _error =
          'Connection error. Pull to reconnect or check your network.';
      _connected = false;
    });
  }
},
```
- **Related Variables**:
  - `_connected` (boolean flag)
  - `_channel` (WebSocketChannel instance)
  - `_statusDisplay` (user-facing status)
  - `_error` (error message state)

---

#### Error Message #8: WebSocket Connection Failed to Open
- **Line**: 90
- **Exact Message**: `"Could not open live connection."`
- **Trigger Conditions**: Exception thrown in WebSocket connection try-catch block
- **Code Context** (lines 45-90):
```dart
void _connect() {
  final auth = context.read<AuthProvider>();
  if (!auth.isAuthenticated || auth.accessToken == null) {
    setState(() => _error = 'Please log in to track this delivery.');
    return;
  }
  final wsUrl =
      '${ApiConstants.wsBaseUrl}/ws/delivery-tasks/${widget.taskId}/?token=${auth.accessToken}';
  try {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _sub = _channel!.stream.listen(
      (data) {
        // ... handle message ...
      },
      onError: (_) {
        // ... error handler ...
      },
      onDone: () {
        // ... done handler ...
      },
    );
  } catch (e) {
    setState(() => _error = 'Could not open live connection.');
  }
}
```
- **Related Variables**:
  - `wsUrl` (WebSocket URL pattern: `${ApiConstants.wsBaseUrl}/ws/delivery-tasks/{taskId}/?token={accessToken}`)
  - `_channel` (WebSocketChannel)
  - `_sub` (StreamSubscription)

---

### File: [features/messages/chat_room_screen.dart](features/messages/chat_room_screen.dart)

#### Error Message #9: Chat Room Opening Failed
- **Line**: 130
- **Exact Message**: `"Could not open chat room"`
- **Trigger Conditions**: When `getOrCreateChatRoom` API call returns null for room ID
- **Code Context** (lines 125-141):
```dart
try {
  var roomId = widget.initialRoomId;
  if (roomId == null) {
    final room = await _api.getOrCreateChatRoom(
      auth.authHeaders,
      otherUserId: widget.receiverId,
    );
    roomId = room['id'] as int? ?? (room['chat_room'] as num?)?.toInt();
  }
  if (roomId == null) {
    throw Exception('Could not open chat room');
  }
  _roomId = roomId;
  // ... continue initialization ...
} catch (e) {
  if (mounted) {
    setState(() => _error = NetworkErrorHelper.toUserMessage(e));
  }
}
```
- **Related Variables**:
  - `roomId` (chat room ID)
  - `_roomId` (instance variable storing current room ID)
  - `_error` (error message state)

---

#### WebSocket Connection for Chat (lines 173-191)
- **Pattern**: Similar to delivery tracking
- **Connection URL**: `${ApiConstants.wsBaseUrl}/ws/messages/$_roomId/?token=${auth.accessToken}`
- **Code Context**:
```dart
void _connectWs() {
  final auth = context.read<AuthProvider>();
  if (!auth.isAuthenticated || auth.accessToken == null || _roomId == null) {
    return;
  }
  final wsUrl =
      '${ApiConstants.wsBaseUrl}/ws/messages/$_roomId/?token=${auth.accessToken}';
  try {
    _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _wsSub = _wsChannel!.stream.listen(
      (data) { /* ... */ },
      onError: (_) {},  // Silent error handling
      onDone: () {},    // Silent done handling
    );
  } catch (_) {}  // Silent catch
}
```
- **Note**: Chat WebSocket errors are handled silently (no user-facing message)

---

## 3. Timeout Configuration

### File: [core/services/api_service.dart](core/services/api_service.dart)
- **Line**: 8
- **Timeout Duration**: `10 seconds`
- **Configuration**:
```dart
/// Request timeout duration (fail fast to avoid ANR when backend is down).
const Duration _requestTimeout = Duration(seconds: 10);
```
- **Applied To**: All HTTP methods (GET, POST, PUT, PATCH, DELETE)
- **Timeout Exception**: Throws `TimeoutException('Connection timed out')`

---

## 4. ShareCareApiException Class

### File: [core/services/sharecare_api_service.dart](core/services/sharecare_api_service.dart)
- **Lines**: 1477-1502
- **Purpose**: Custom exception for API errors with HTTP status codes
- **Properties**:
  - `statusCode` (int): HTTP status code
  - `body` (String): Response body
  - `message` (getter): Parsed error message from JSON response
- **Definition**:
```dart
class ShareCareApiException implements Exception {
  ShareCareApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  String get message {
    try {
      final json = jsonDecode(body);
      final parts = <String>[];
      if (json is Map) {
        if (json.containsKey('detail')) parts.add(json['detail'].toString());
        if (json.containsKey('error')) parts.add(json['error'].toString());
        for (final k in json.keys) {
          if (k != 'detail' && k != 'error') {
            parts.add('$k: ${json[k]}');
          }
        }
      }
      if (parts.isNotEmpty) return parts.join('; ');
      return body.isNotEmpty ? body : 'Request failed ($statusCode)';
    } catch (_) {
      return body.isNotEmpty ? body : 'Request failed ($statusCode)';
    }
  }

  @override
  String toString() => 'ShareCareApiException($statusCode): $body';
}
```

---

## 5. Error Handling Locations (Usage Count)

### Primary Error Handler Usage (NetworkErrorHelper.toUserMessage)
- **Total Usage**: 50+ locations
- **Key Files Using This Helper**:
  - `shared/providers/auth_provider.dart` (8 usages)
  - `features/messages/chat_room_screen.dart` (4 usages)
  - `features/messages/chat_list_screen.dart` (2 usages)
  - `features/volunteers/screens/volunteer_available_tab.dart` (8 usages)
  - `features/volunteers/screens/update_task_status_screen.dart` (2 usages)
  - And 40+ other screens

---

## 6. Connectivity Checking Flow

### Authentication Provider
**File**: [shared/providers/auth_provider.dart](shared/providers/auth_provider.dart)

Connection error detection patterns (lines 125-126, 198-199):
```dart
if (_error!.contains('SocketException') ||
    _error!.contains('TimeoutException')) {
  // Backend connectivity issue detected
}
```

---

## 7. Related Configuration

### API Constants
**File**: [core/constants/api_constants.dart](core/constants/api_constants.dart)
- Defines `baseUrl`, `wsBaseUrl`, `resolvedBaseUrl`
- Used in error messages for displaying the server URL

### WebSocket Base URLs
- Pattern: `${ApiConstants.wsBaseUrl}/ws/{endpoint}/?token={accessToken}`
- Endpoints:
  - `/ws/delivery-tasks/{taskId}/`
  - `/ws/messages/{roomId}/`

---

## 8. Connectivity Conditions by Error Type

| Error Message | Root Cause | HTTP Status | Exception Type | User Action |
|---|---|---|---|---|
| Backend not running | Server unreachable | N/A | SocketException, ClientException | Check backend running on 0.0.0.0:8000 |
| Cannot reach backend at $url | DNS/Network issue | N/A | URI parsing error | Check network, API_BASE_URL setting |
| Request timed out | Backend slow/unresponsive | N/A | TimeoutException | Retry, check backend performance |
| Connection error (network) | SSL/TLS issue | N/A | HandshakeException | Check network security |
| Invalid response | Backend returned malformed data | N/A | FormatException | Try again later |
| Server temporarily unavailable | Backend error | 500, 502, 503 | ShareCareApiException | Try again later |
| Connection error (WebSocket) | WebSocket stream failed | N/A | Stream error | Pull to reconnect |
| Could not open live connection | WebSocket connection exception | N/A | Exception (generic) | Connection lost |
| Could not open chat room | Room ID not returned | N/A | Exception | Contact support |

---

## 9. Debugging Notes

### For Development (Debug Mode)
- Detailed error messages showing URL and instructions
- Messages include: API_BASE_URL, API_LAN_FALLBACK_BASE_URL, Django startup command
- File: [core/utils/network_error_helper.dart](core/utils/network_error_helper.dart) line 151-160

### For Production (Release Mode)
- Generic error messages without technical details
- File: [core/utils/network_error_helper.dart](core/utils/network_error_helper.dart) line 158-160

---

## 10. Summary Table of All Error Messages

| # | Message | File | Line | Trigger | Type |
|---|---|---|---|---|---|
| 1 | "Unable to connect. Please check that the backend is running..." | network_error_helper.dart | 115 | SocketException, Connection refused | HTTP/Network |
| 2 | "Cannot reach backend at $url. Physical phone + auto..." | network_error_helper.dart | 153 | URI parsing error | HTTP/Network |
| 3 | "Request timed out. Please try again." | network_error_helper.dart | 120 | TimeoutException | HTTP Timeout |
| 4 | "Connection error. Please check your network." | network_error_helper.dart | 122 | HandshakeException, CertificateException | SSL/TLS Error |
| 5 | "Invalid response from server. Please try again later." | network_error_helper.dart | 127 | FormatException, JSON error | Response Error |
| 6 | "Server is temporarily unavailable. Please try again later." | network_error_helper.dart | 75, 103 | HTTP 500/502/503, ProgrammingError | Server Error |
| 7 | "Connection error. Pull to reconnect or check your network." | delivery_task_tracking_screen.dart | 80 | WebSocket stream onError | WebSocket Error |
| 8 | "Could not open live connection." | delivery_task_tracking_screen.dart | 90 | WebSocket connect exception | WebSocket Error |
| 9 | "Could not open chat room" | chat_room_screen.dart | 130 | Room ID null | API Error |

