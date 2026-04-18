import 'package:google_sign_in/google_sign_in.dart';

import '../core/config/app_config.dart';

class GoogleSignInResult {
  GoogleSignInResult({
    this.account,
    this.idToken,
    this.errorMessage,
    this.cancelled = false,
  });

  final GoogleSignInAccount? account;
  final String? idToken;
  final String? errorMessage;
  final bool cancelled;

  bool get isSuccess => account != null && (idToken?.isNotEmpty ?? false);
}

class GoogleAuthService {
  /// Prevent duplicate initialization of the singleton client.
  static bool _initialized = false;

  /// Starts Google sign-in and returns account + ID token.
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      final serverClientId = AppConfig.googleServerClientId;
      if (serverClientId == null || serverClientId.isEmpty) {
        return GoogleSignInResult(
          errorMessage:
              'Google Sign-In is not configured. Set GOOGLE_SERVER_CLIENT_ID in assets/.env.',
        );
      }

      if (!_initialized) {
        await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
        _initialized = true;
      }

      // Force account picker every time.
      await GoogleSignIn.instance.signOut();

      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate(scopeHint: ['email']);

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return GoogleSignInResult(
          account: account,
          errorMessage: 'Google Sign-In did not return an ID token.',
        );
      }

      return GoogleSignInResult(account: account, idToken: idToken);
    } on GoogleSignInException catch (e) {
      final cancelled = e.code == GoogleSignInExceptionCode.canceled;
      return GoogleSignInResult(
        cancelled: cancelled,
        errorMessage: cancelled
            ? 'Google sign-in was cancelled.'
            : 'Google sign-in failed: ${e.description ?? e.code.name}',
      );
    } catch (e) {
      return GoogleSignInResult(errorMessage: 'Google sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      if (_initialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
  }
}
