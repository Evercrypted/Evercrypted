import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwk/jwk.dart';

class ChatKeys {
  final String chatUid;
  final String? baseKey;
  final String? private;
  final String? pubCombo;

  ChatKeys({required this.chatUid, this.baseKey, this.private, this.pubCombo});

  ChatKeys.fromJson(Map<String, dynamic> json)
      : chatUid = json['chatUid'],
        baseKey = json['baseKey'],
        private = json['private'],
        pubCombo = json['pubCombo'];

  Map<String, dynamic> toJson() {
    return {
      'chatUid': chatUid,
      'baseKey': baseKey,
      'private': private,
      'pubCombo': pubCombo,
    };
  }
}

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

  static String? pubkeyComb(List<Participant> participants) {
    if (participants.any((p) => p.pubKey == null)) {
      return null;
    }
    final List<String> pubKeys = participants.map((e) => e.pubKey!).toList();
    pubKeys.sort();
    return pubKeys.join();
  }

  static Future<ChatKeys> setKeys(
      {required String chatUid,
      String? baseKey,
      String? private,
      String? pubCombo}) async {
    ChatKeys? current = await getKeys(chatUid);
    late ChatKeys keys;
    if (current != null) {
      keys = ChatKeys(
          chatUid: chatUid,
          baseKey: baseKey ?? current.baseKey,
          private: private ?? current.private,
          pubCombo: pubCombo ?? current.pubCombo);
    } else {
      keys = ChatKeys(
          chatUid: chatUid,
          baseKey: baseKey,
          private: private,
          pubCombo: pubCombo);
    }
    await storage.write(key: 'keys-$chatUid', value: jsonEncode(keys.toJson()));
    return keys;
  }

  static Future<ChatKeys?> getKeys(String chatUid) async {
    final String? string = await storage.read(key: 'keys-$chatUid');
    return string != null ? ChatKeys.fromJson(jsonDecode(string)) : null;
  }
}

class Base64KeyData {
  String keyPair;
  String publicKey;

  Base64KeyData({required this.keyPair, required this.publicKey});
}
