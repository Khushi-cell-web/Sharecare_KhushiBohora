import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// eSewa payment in a WebView.
///
/// **Preferred:** [backendFormUrl] — GET your Django
/// `/api/payments/esewa-form/?transaction_uuid=...` so the server returns real
/// HTML that POSTs to eSewa. This avoids `loadHtmlString` auto-POST, which
/// often stays blank on Android.
///
/// **Fallback:** [formUrl] + [formFields] from `esewa-init` (local HTML POST).
class EsewaWebViewScreen extends StatefulWidget {
  EsewaWebViewScreen({
    super.key,
    this.backendFormUrl,
    this.formUrl,
    this.formFields,
    required this.onSuccess,
    required this.onFailure,
  }) : assert(
         (backendFormUrl != null && backendFormUrl.trim().isNotEmpty) ||
             ((formUrl?.trim().isNotEmpty ?? false) &&
                 formFields != null &&
                 formFields.isNotEmpty),
       );

  /// Full URL: `{apiBase}/api/payments/esewa-form/?transaction_uuid=...`
  final String? backendFormUrl;

  /// e.g. https://rc-epay.esewa.com.np/api/epay/main/v2/form
  final String? formUrl;

  /// Map from `form_data` in esewa-init JSON (hidden POST fields).
  final Map<String, dynamic>? formFields;

  final VoidCallback onSuccess;
  final VoidCallback onFailure;

  @override
  State<EsewaWebViewScreen> createState() => _EsewaWebViewScreenState();
}

String _htmlEscapeAttr(Object? value) {
  final s = value?.toString() ?? '';
  return s
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

String _buildAutoPostHtml(String actionUrl, Map<String, dynamic> fields) {
  final inputs = StringBuffer();
  for (final e in fields.entries) {
    final name = _htmlEscapeAttr(e.key);
    final val = _htmlEscapeAttr(e.value);
    inputs.writeln('<input type="hidden" name="$name" value="$val">');
  }
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>eSewa</title>
</head>
<body onload="var f=document.getElementById('esewaForm');if(f)f.submit();">
  <p style="font-family:sans-serif;text-align:center;padding:24px;color:#555;">Opening eSewa…</p>
  <form id="esewaForm" action="${_htmlEscapeAttr(actionUrl)}" method="POST">
$inputs
  </form>
  <script>document.getElementById("esewaForm").submit();</script>
  <noscript><button type="submit" form="esewaForm">Continue to eSewa</button></noscript>
</body>
</html>''';
}

bool _supportsInAppWebView() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

class _EsewaWebViewScreenState extends State<EsewaWebViewScreen> {
  WebViewController? _controller;
  bool _loading = true;
  // ignore: unused_field
  bool _showFallbackMessage = false;
  String? _loadErrorMessage;
  bool _finishedHandled = false;
  Timer? _fallbackTimer;
  String? _openExternallyUrl;

  /// Switched to direct form fallback when backend form URL fails.
  bool _triedDirectFallback = false;

  /// Windows/Linux (and web): no WebView — open system browser only.
  bool _externalBrowserOnly = false;

  Future<void> _configureAndroid(WebViewController c) async {
    // Keep as async hook for platform-specific tweaks when needed.
    return;
  }

  @override
  void initState() {
    super.initState();

    final backend = widget.backendFormUrl?.trim();
    if (backend != null && backend.isNotEmpty) {
      if (!(backend.startsWith('http://') || backend.startsWith('https://'))) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onFailure();
        });
        return;
      }
      _openExternallyUrl = backend;

      if (!_supportsInAppWebView()) {
        _externalBrowserOnly = true;
        _loading = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _openPaymentInBrowser();
          if (mounted) {
            setState(() {
              _loading = false;
              _showFallbackMessage = true;
            });
          }
        });
        return;
      }

      final uri = Uri.parse(backend);
      final c = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(_navigationDelegate())
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        )
        ..loadRequest(
          uri,
          headers: const {
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        );
      unawaited(_configureAndroid(c));
      _controller = c;
      _loadErrorMessage = null;
      _fallbackTimer = Timer(const Duration(seconds: 15), () {
        if (mounted) setState(() => _showFallbackMessage = true);
      });
      debugPrint('eSewa WebView loading backend URL: $backend');
      return;
    }

    final action = widget.formUrl!.trim();
    if (action.isEmpty ||
        !(action.startsWith('http://') || action.startsWith('https://'))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFailure();
      });
      return;
    }

    _loadDirectForm();

    _fallbackTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _showFallbackMessage = true);
    });
  }

  NavigationDelegate _navigationDelegate() {
    return NavigationDelegate(
      onPageStarted: (url) {
        debugPrint('eSewa WebView page started: $url');
        if (mounted) setState(() => _loading = true);
      },
      onPageFinished: (_) async {
        if (mounted) setState(() => _loading = false);
        await _maybeFinishFromUrl();
      },
      onNavigationRequest: (request) {
        final url = request.url;
        debugPrint('eSewa WebView navigation request: $url');

        if (url.startsWith('sharecare://')) {
          if (url.contains('success')) {
            _safeSuccess();
          } else {
            _safeFailure();
          }
          return NavigationDecision.prevent;
        }

        final uri = Uri.tryParse(url);
        if (uri != null &&
            uri.scheme.isNotEmpty &&
            uri.scheme != 'http' &&
            uri.scheme != 'https') {
          unawaited(_launchExternally(uri));
          return NavigationDecision.prevent;
        }

        return NavigationDecision.navigate;
      },
      onWebResourceError: (error) {
        debugPrint('eSewa WebView resource error: ${error.description}');
        if (!_triedDirectFallback &&
            widget.formUrl != null &&
            widget.formFields != null &&
            widget.formFields!.isNotEmpty) {
          _triedDirectFallback = true;
          debugPrint('Switching to direct eSewa form fallback URL.');
          _loadDirectForm();
          return;
        }
        if (mounted) {
          setState(() {
            _loading = false;
            _showFallbackMessage = true;
            _loadErrorMessage = 'Unable to load payment page';
          });
        }
      },
    );
  }

  void _safeSuccess() {
    if (_finishedHandled) return;
    _finishedHandled = true;
    widget.onSuccess();
  }

  void _safeFailure() {
    if (_finishedHandled) return;
    _finishedHandled = true;
    widget.onFailure();
  }

  Future<void> _maybeFinishFromUrl() async {
    if (_finishedHandled || _controller == null) return;
    try {
      final u = await _controller!.currentUrl();
      if (u == null) return;
      debugPrint('eSewa WebView current URL: $u');
      if (u.contains('esewa-callback') && u.contains('data=')) {
        debugPrint('eSewa success detected from URL');
        _safeSuccess();
      } else if (u.contains('esewa-failure')) {
        debugPrint('eSewa failure detected from URL');
        _safeFailure();
      }
    } catch (_) {}
  }

  void _loadDirectForm() {
    final action = widget.formUrl?.trim();
    final fields = widget.formFields;
    if (action == null || action.isEmpty || fields == null || fields.isEmpty) {
      return;
    }

    final baseUri = Uri.parse(action);
    final origin =
        '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
    final html = _buildAutoPostHtml(action, fields);

    _openExternallyUrl = action;
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(_navigationDelegate())
      ..loadHtmlString(html, baseUrl: origin);
    unawaited(_configureAndroid(c));
    setState(() {
      _controller = c;
      _loading = true;
      _showFallbackMessage = false;
      _loadErrorMessage = null;
    });

    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _showFallbackMessage = true);
    });
    debugPrint('eSewa WebView loaded direct form URL fallback: $action');
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _launchExternally(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        setState(() => _showFallbackMessage = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _showFallbackMessage = true);
      }
    }
  }

  Future<void> _openPaymentInBrowser() async {
    final url = _openExternallyUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_externalBrowserOnly) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 56,
                color: AppTheme.primaryTeal,
              ),
              const SizedBox(height: 20),
              Text(
                'eSewa opens in your browser',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Complete payment there. When finished, use the back gesture or return to ShareCare.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              if (_loading) const CircularProgressIndicator(),
              if (!_loading && _openExternallyUrl != null)
                FilledButton.icon(
                  onPressed: _openPaymentInBrowser,
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text('Open eSewa again'),
                ),
            ],
          ),
        ),
      );
    }

    final c = _controller;
    if (c == null) {
      return const Center(child: Text('Unable to load payment page'));
    }
    return Stack(
      children: [
        WebViewWidget(controller: c),
        if (_loading)
          const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Connecting to eSewa…'),
                  ],
                ),
              ),
            ),
          ),
        if (_loadErrorMessage != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _loadErrorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
