import 'dart:convert';
import 'dart:typed_data';

import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_ever_crypto/flutter_ever_crypto.dart';
import 'package:rxdart/rxdart.dart';

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

  static BehaviorSubject<String> baseKeySubject = BehaviorSubject<String>();

  static const storage = FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      aOptions: AndroidOptions());

  static Future<Base64KeyData> generateKeys() async {
    final keyPair = EverCrypto.generateKyberKeyPair();
    final base64KeyPair = base64Encode(keyPair.secretKey);
    final base64PublicKey = base64Encode(keyPair.publicKey);
    return Base64KeyData(keyPair: base64KeyPair, publicKey: base64PublicKey);
  }

  static Future<String?> combine(
      String secretKeyBytesBase64, String ciphertextBytesBase64) async {
    try {
      final secretKey = base64Decode(secretKeyBytesBase64);
      final ciphertext = base64Decode(ciphertextBytesBase64);

      // Decapsulate the shared secret using Kyber1024
      final sharedSecret = EverCrypto.kyberDecapsulate(ciphertext, secretKey);

      return base64Encode(sharedSecret);
    } catch (e) {
      return null;
    }
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
    if (baseKey != null) {
      baseKeySubject.add(chatUid);
    }
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
