import 'package:cryptography/cryptography.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:jwk/jwk.dart';
import 'package:rhttp/rhttp.dart';

import '../cryptography/combine_keys.dart';
import '../http.dart';

class SettingsService {
  static const String otpTokenPrefix = 'otpToken-';

  final currentUserUid = Auth.user?.uid;

  Future<String> otpHandshake() async {
    final algo = X25519();

    // We need the private key pair of Alice.
    final keyPair = await algo.newKeyPair();
    final SimplePublicKey localPublicKey = await keyPair.extractPublicKey();
    final resp = await HttpClient.client.post('/settings/httpHandshake',
        body: HttpBody.json({
          'publicKey': Jwk.fromPublicKey(localPublicKey).toJson(),
        }));
    return combineKeys(algo, keyPair, resp.bodyToJson['publicKey']);
  }
}
