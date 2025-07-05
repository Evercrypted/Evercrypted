import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/combine_keys.dart';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/helpers/get_random_string.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/socket/event_types/auth_event_types.dart';
import 'package:evercrypted/core/socket/event_types/settings_event_types.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:flutter_ever_crypto/flutter_ever_crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retry/retry.dart';
import 'package:rhttp/rhttp.dart';

class AuthForm {
  String? email;
  String? password;

  AuthForm({this.email, this.password});
}

class AuthService {
  Future<Map<String, dynamic>> loginHandshake(identifier) async {
    final keyPair = EverCrypto.generateKyberKeyPair();
    final resp = await AppHttpClient.client.post(
      '/auth/handshake',
      body: HttpBody.json({
        'publicKey': base64Encode(keyPair.publicKey),
        'identifier': identifier,
      }),
    );

    // Server responds with ciphertext for Kyber1024 decapsulation
    final serverCiphertext = resp.bodyToJson['ciphertext'];
    String? key;

    if (serverCiphertext != null) {
      // Decapsulate the shared secret using our secret key and server's ciphertext
      final sharedSecret = EverCrypto.kyberDecapsulate(
        base64Decode(serverCiphertext),
        keyPair.secretKey,
      );
      key = base64Encode(sharedSecret);
    }

    return {
      'key': key,
    };
  }

  Future<String> otpHandshake() async {
    final keyPair = EverCrypto.generateKyberKeyPair();
    final resp = await AppHttpClient.client.post(
      '/auth/httpHandshake',
      body: HttpBody.json({
        'publicKey': base64Encode(keyPair.publicKey),
      }),
    );

    // Server responds with ciphertext for Kyber1024 decapsulation
    final serverCiphertext = resp.bodyToJson['ciphertext'];

    if (serverCiphertext != null) {
      // Decapsulate the shared secret using our secret key and server's ciphertext
      final sharedSecret = EverCrypto.kyberDecapsulate(
        base64Decode(serverCiphertext),
        keyPair.secretKey,
      );
      return base64Encode(sharedSecret);
    }

    throw Exception('Server did not return ciphertext');
  }

  Future<Map<String, dynamic>> getLoginEncKey(identifier) async {
    final response = await retry(
        // Make a GET request
        () => loginHandshake(identifier).timeout(const Duration(seconds: 5)),
        // Retry on SocketException or TimeoutException
        delayFactor: const Duration(seconds: 2),
        maxAttempts: 10000,
        onRetry: (e) {});
    return response;
  }

  Future signUp(AuthForm formValues) async {
    final identifier =
        DateTime.now().millisecondsSinceEpoch.toString() + getRandomString(32);
    final Map<String, dynamic> keys = await getLoginEncKey(identifier);
    final crypted = await encodePayload({
      'email': formValues.email,
      'password': formValues.password,
    }, keys['key'], true);
    return AppHttpClient.client
        .post('/auth/register',
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
            'message': payload['message'],
          };
        } else {
          Auth.setAuth(
              profile: Profile(
                  uid: payload['uid'],
                  email: payload['email'] ?? payload['preverified_email'],
                  emailVerified: payload['email_verified'] as bool),
              newToken: payload['access_token'] as String,
              newIsOtpActive: payload['otp_active'] as bool);
          return {
            'success': true,
            'payload': payload,
          };
        }
      },
    );
  }

  Future singIn(AuthForm formValues) async {
    final identifier =
        DateTime.now().millisecondsSinceEpoch.toString() + getRandomString(32);
    final Map<String, dynamic> keys = await getLoginEncKey(identifier);
    final crypted = await encodePayload({
      'email': formValues.email,
      'password': formValues.password,
    }, keys['key'], true);
    return AppHttpClient.client
        .post('/auth/login',
            body: HttpBody.json({'crypted': crypted, 'identifier': identifier}))
        .then(
      (value) async {
        dynamic payload;
        if (value.bodyToJson['bypass'] == true) {
          payload = value.bodyToJson;
        } else {
          payload = await decodePayload(
            value.bodyToJson['crypted'],
            value.bodyToJson['iv'],
            keys['key'],
            true,
          );
        }
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
              newIsOtpActive: payload['otp_active'] as bool);
          return {
            'success': true,
            'payload': payload,
          };
        }
      },
    );
  }

  Future login2FA(WidgetRef ref, String code) async {
    final identifier =
        DateTime.now().millisecondsSinceEpoch.toString() + getRandomString(32);
    final Map<String, dynamic> keys = await getLoginEncKey(identifier);
    final crypted = await encodePayload(
        {'type': SettingsEventTypes.login2FA, 'code': code}, keys['key'], true);
    return AppHttpClient.client
        .post('/auth/login2fa',
            body: HttpBody.json({'crypted': crypted, 'identifier': identifier}))
        .then(
      (value) async {
        final payload = await decodePayload(
          value.bodyToJson['crypted'],
          value.bodyToJson['iv'],
          keys['key'],
          true,
        );
        if (payload['status'] == 'ok') {
          await Auth.setOtpToken(otpToken: payload['payload']['otpToken']);
          ChatSocket.resetConnectionSubject.add(true);
          return {
            'success': true,
          };
        } else {
          return {
            'error': payload['error'],
          };
        }
      },
    );
  }

  Future resendVerificationEmail() async {
    final completer = Completer<dynamic>();
    AppHttpClient.message(
      channel: SocketChannelTypes.auth,
      type: AuthEventTypes.resendVerificationEmail,
      payload: {'resend': true},
    ).then((resp) async {
      completer.complete(resp);
    }).onError((error, stackTrace) {
      completer.completeError(error ?? 'Unknown error');
    });
    return completer.future;
  }

  Future forgotPassword(String email) async {
    if (ChatSocket.socket?.connected == true &&
        ChatSocket.isConnected == true) {
      return AppHttpClient.message(
        channel: SocketChannelTypes.auth,
        type: AuthEventTypes.forgotPassword,
        payload: {'email': email},
      );
    }

    final identifier =
        DateTime.now().millisecondsSinceEpoch.toString() + getRandomString(32);
    final Map<String, dynamic> keys = await getLoginEncKey(identifier);
    final crypted = await encodePayload({
      'email': email,
    }, keys['key'], true);

    return AppHttpClient.client
        .post('/auth/forgot-password',
            body: HttpBody.json({'crypted': crypted, 'identifier': identifier}))
        .then((resp) => true);
  }
}
