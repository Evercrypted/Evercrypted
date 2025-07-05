import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter_ever_crypto/flutter_ever_crypto.dart';

// Old implementations using cryptography_plus
dynamic decodePayloadOld(crypted, iv, mac, key, [bool notHex = false]) async {
  final algorithm = Chacha20.poly1305Aead();
  final secretBox = SecretBox(
    base64.decode(crypted),
    nonce: base64.decode(iv),
    mac: Mac(base64.decode(mac)),
  );
  final clearText = await algorithm.decrypt(secretBox,
      secretKey:
          SecretKey(notHex == true ? utf8.encode(key) : hex.decode(key)));
  return json.decode(utf8.decode(clearText));
}

dynamic encodePayloadOld(message, key, [bool notHex = false]) async {
  final algorithm = Chacha20.poly1305Aead();
  final secretBox = await algorithm.encrypt(
      utf8.encode(json.encode(message).toString()),
      secretKey:
          SecretKey(notHex == true ? utf8.encode(key) : hex.decode(key)));
  return {
    'crypted': base64.encode(secretBox.cipherText),
    'iv': base64.encode(secretBox.nonce),
    'mac': base64.encode(secretBox.mac.bytes),
  };
}

// New implementations using flutter_ever_crypto
dynamic decodePayload(crypted, iv, key, [bool notHex = false]) async {
  try {
    // Handle different key formats:
    // - notHex = true: key is base64-encoded (from Kyber1024)
    // - notHex = false: key is hex-encoded (legacy)
    final Uint8List keyBytes = notHex == true
        ? base64.decode(key)
        : Uint8List.fromList(hex.decode(key));
    final Uint8List nonceBytes = base64.decode(iv);
    final Uint8List ciphertextBytes = base64.decode(crypted);

    final clearTextBytes = EverCrypto.xchachaDecrypt(
      keyBytes,
      nonceBytes,
      ciphertextBytes,
    );

    return json.decode(utf8.decode(clearTextBytes));
  } catch (e) {
    throw Exception('Failed to decode payload: $e');
  }
}

dynamic encodePayload(message, key, [bool notHex = false]) async {
  try {
    // Handle different key formats:
    // - notHex = true: key is base64-encoded (from Kyber1024)
    // - notHex = false: key is hex-encoded (legacy)
    final Uint8List keyBytes = notHex == true
        ? base64.decode(key)
        : Uint8List.fromList(hex.decode(key));
    final Uint8List nonceBytes = EverCrypto.generateXChaChaNonce();
    final Uint8List plaintextBytes =
        Uint8List.fromList(utf8.encode(json.encode(message).toString()));

    final ciphertextBytes = EverCrypto.xchachaEncrypt(
      keyBytes,
      nonceBytes,
      plaintextBytes,
    );

    return {
      'crypted': base64.encode(ciphertextBytes),
      'iv': base64.encode(nonceBytes),
    };
  } catch (e) {
    throw Exception('Failed to encode payload: $e');
  }
}
