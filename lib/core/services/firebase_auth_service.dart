import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/helpers/get_random_string.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rhttp/rhttp.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  /// Sign in with Google and authenticate with backend
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Use GoogleSignIn.instance for v7+
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        return {
          'success': false,
          'error': 'Google sign-in cancelled',
        };
      }

      // Get authentication details - in v7, this is a synchronous property
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential - Firebase Auth only needs ID token for Google
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      // Verify email exists
      final user = userCredential.user;
      final email = user?.email; // Extract email safely
      if (email == null || email.isEmpty) {
        await signOut();
        return {
          'success': false,
          'error': 'Email is required to sign in.',
        };
      }

      // Get the Firebase ID token
      // We know user is not null because if user was null, user?.email would be null and we would have returned
      final idToken = await user!.getIdToken();

      if (idToken == null) {
        return {
          'success': false,
          'error': 'Failed to get Firebase ID token',
        };
      }

      // Authenticate with our backend
      return await _authenticateWithBackend(idToken);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Sign in with Apple and authenticate with backend
  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credential from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create Firebase credential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential
            .authorizationCode, // Required for server-side validation
        rawNonce: rawNonce,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);

      // Verify email exists (some Apple logins might hide it if not configured correctly)
      final user = userCredential.user;
      final email = user?.email;
      if (email == null || email.isEmpty) {
        await signOut();
        return {
          'success': false,
          'error': 'Email is required for this app. Please try again.',
        };
      }

      // Get the Firebase ID token
      final idToken =
          await user!.getIdToken(); // User is confirmed not null above

      if (idToken == null) {
        return {
          'success': false,
          'error': 'Failed to get Firebase ID token',
        };
      }

      // Authenticate with our backend
      return await _authenticateWithBackend(idToken);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return {
          'success': false,
          'error': 'Apple sign-in cancelled',
        };
      }
      return {
        'success': false,
        'error': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Authenticate with our backend using Firebase ID token
  Future<Map<String, dynamic>> _authenticateWithBackend(String idToken) async {
    final identifier =
        DateTime.now().millisecondsSinceEpoch.toString() + getRandomString(32);
    final Map<String, dynamic> keys =
        await _authService.getLoginEncKey(identifier);

    final crypted = await encodePayload({
      'firebaseIdToken': idToken,
    }, keys['key'], true);

    return AppHttpClient.client
        .post('/auth/firebase-login',
            body: HttpBody.json({'crypted': crypted, 'identifier': identifier}))
        .then(
      (value) async {
        final payload = await decodePayload(
          value.bodyToJson['crypted'],
          value.bodyToJson['iv'],
          keys['key'],
          true,
        );

        if (payload['error'] != null) {
          return {
            'success': false,
            'error': payload['error'],
          };
        } else {
          Auth.setAuth(
              profile: Profile(
                  uid: payload['uid'],
                  email: payload['email'] ?? payload['preverified_email'],
                  emailVerified: payload['email_verified'] as bool),
              newToken: payload['access_token'] as String,
              newIsOtpActive: payload['otp_active'] as bool? ?? false);
          return {
            'success': true,
            'payload': payload,
          };
        }
      },
    );
  }

  /// Sign out from Firebase (called when user logs out)
  Future<void> signOut() async {
    await GoogleSignIn.instance.disconnect();
    await _firebaseAuth.signOut();
  }

  /// Generate a random nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// SHA256 hash of a string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if Apple Sign-In is available on this device
  Future<bool> isAppleSignInAvailable() async {
    return await SignInWithApple.isAvailable();
  }
}
