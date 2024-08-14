import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwk/jwk.dart';

class BaseKey {
  BaseKey._();

  static const storage = FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      aOptions: AndroidOptions());

  static Future<Base64KeyData> generateKeys() async {
    final algo = X25519();
    final SimpleKeyPair keyPair = await algo.newKeyPair();
    final SimplePublicKey publicKey = await keyPair.extractPublicKey();
    final jwkJSONStringFromKeyPair = (await Jwk.fromKeyPair(keyPair)).toJson();
    final jwkJSONFromPublic = Jwk.fromPublicKey(publicKey).toJson();
    final base64KeyPair =
        base64Encode(utf8.encode(jsonEncode(jwkJSONStringFromKeyPair)));
    final base64PublicKey =
        base64Encode(utf8.encode(jsonEncode(jwkJSONFromPublic)));
    return Base64KeyData(keyPair: base64KeyPair, publicKey: base64PublicKey);
  }

  static Future<String?> combine(
      String keyPairBytesBase64, String pubKeyBytesBase64) async {
    final algorithm = X25519();
    final keyPairJson =
        jsonDecode(utf8.decode(base64Decode(keyPairBytesBase64)));
    final pubKeyJson = jsonDecode(utf8.decode(base64Decode(pubKeyBytesBase64)));
    final KeyPair keyPair = Jwk.fromJson(keyPairJson).toKeyPair();
    final PublicKey? pubKey = Jwk.fromJson(pubKeyJson).toPublicKey();
    if (pubKey == null) return null;
    final sharedSecretKey = await algorithm.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: pubKey,
    );
    final secretKeyData = await sharedSecretKey.extract();
    return base64Encode(secretKeyData.bytes);
  }

  static setBase(String chatUid, String shared) async {
    await storage.write(key: 'base-$chatUid', value: shared.substring(0, 32));
  }

  static setPrivate(String chatUid, String keyPairBase64) async {
    await storage.write(key: 'private-$chatUid', value: keyPairBase64);
  }

  static Future<String?> getBase(String chatUid) async {
    return await storage.read(key: 'base-$chatUid');
  }

  static Future<String?> getPrivate(String chatUid) async {
    return await storage.read(key: 'private-$chatUid');
  }
}

class Base64KeyData {
  String keyPair;
  String publicKey;

  Base64KeyData({required this.keyPair, required this.publicKey});
}
