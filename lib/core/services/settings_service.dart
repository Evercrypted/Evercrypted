import 'package:cryptography/cryptography.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/socket/event_types/settings_event_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwk/jwk.dart';

import '../cryptography/combine_keys.dart';
import '../cryptography/payload.dart';
import '../http.dart';

class SettingsService {
  static const String otpTokenPrefix = 'otpToken-';

  final currentUserUid = Auth.user?.uid;

  Future<String> otpHandshake() async {
    final algo = X25519();

    // We need the private key pair of Alice.
    final keyPair = await algo.newKeyPair();
    final SimplePublicKey localPublicKey = await keyPair.extractPublicKey();
    final resp = await dio.post('/settings/httpHandshake', data: {
      'publicKey': Jwk.fromPublicKey(localPublicKey).toJson(),
    });
    return combineKeys(algo, keyPair, resp.data['publicKey']);
  }

  Future<Map<String, dynamic>> otpLogin(WidgetRef ref, String otpCode) async {
    final String key = await getOtpEncKey(ref);
    final crypted = await encodePayload({
      'type': SettingsEventTypes.login2FA,
      'payload': {'code': otpCode}
    }, key);
    return dio.post('/settings', data: crypted).then(
      (value) async {
        final payload = await decodePayload(
          value.data,
          key,
        );
        return payload['needOtp'];
      },
    );
  }
}
