import 'package:cryptography_plus/cryptography_plus.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwk_plus/jwk_plus.dart';
import 'package:retry/retry.dart';
import 'package:rhttp/rhttp.dart';

class AuthForm {
  String? email;
  String? password;

  AuthForm({this.email, this.password});
}

class AuthService {
  Future<Map<String, dynamic>> loginHandshake(identifier) async {
    final algo = X25519();
    final SimpleKeyPair keyPair = await algo.newKeyPair();
    final SimplePublicKey localPublicKey = await keyPair.extractPublicKey();
    final resp = await HttpClient.client.post(
      '/auth/handshake',
      body: HttpBody.json({
        'publicKey': Jwk.fromPublicKey(localPublicKey).toJson(),
        'identifier': identifier,
      }),
    );
    return {
      'key': await combineKeys(algo, keyPair, resp.bodyToJson['publicKey']),
      'publicKey': resp.bodyToJson['publicKey'],
    };
  }

  Future<String> otpHandshake() async {
    final algo = X25519();
    final keyPair = await algo.newKeyPair();
    final SimplePublicKey localPublicKey = await keyPair.extractPublicKey();
    final resp = await HttpClient.client.post(
      '/auth/httpHandshake',
      body: HttpBody.json({
        'publicKey': Jwk.fromPublicKey(localPublicKey).toJson(),
      }),
    );
    return combineKeys(algo, keyPair, resp.bodyToJson['publicKey']);
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
    }, keys['key']);
    return HttpClient.client
        .post('/auth/register',
            body: HttpBody.json({'crypted': crypted, 'identifier': identifier}))
        .then(
      (value) async {
        final payload = await decodePayload(
          value.bodyToJson['crypted'],
          value.bodyToJson['iv'],
          value.bodyToJson['mac'],
          keys['key'],
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
    }, keys['key']);
    return HttpClient.client
        .post('/auth/login',
            body: HttpBody.json({'crypted': crypted, 'identifier': identifier}))
        .then(
      (value) async {
        final payload = await decodePayload(
          value.bodyToJson['crypted'],
          value.bodyToJson['iv'],
          value.bodyToJson['mac'],
          keys['key'],
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
        {'type': SettingsEventTypes.login2FA, 'code': code}, keys['key']);
    return HttpClient.client
        .post('/auth/login2fa',
            body: HttpBody.json({'crypted': crypted, 'identifier': identifier}))
        .then(
      (value) async {
        final payload = await decodePayload(
          value.bodyToJson['crypted'],
          value.bodyToJson['iv'],
          value.bodyToJson['mac'],
          keys['key'],
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
    return ChatSocket.emitWAck(
        SocketChannelTypes.auth,
        AuthEventTypes.resendVerificationEmail,
        {'resend': true}).then((resp) async {
      return resp;
    });
  }
}
