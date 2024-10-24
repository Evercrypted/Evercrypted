import 'package:convert/convert.dart';
import 'package:jwk_plus/jwk_plus.dart';

Future<String> combineKeys(algo, keyPair, publicKey) async {
  final sharedSecretKey = await algo.sharedSecretKey(
    keyPair: keyPair!,
    remotePublicKey: Jwk.fromJson(publicKey).toPublicKey()!,
  );
  final keyBytes = await sharedSecretKey.extract();

  return hex.encode(keyBytes.bytes);
}
