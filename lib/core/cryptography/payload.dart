import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter_ever_crypto/flutter_ever_crypto.dart';

// New implementations using flutter_ever_crypto
dynamic decodePayload(crypted, iv, key, [bool notHex = false]) async {
  try {
    // Handle different key formats:
    // - notHex = true: key is base64-encoded (from Kyber1024 or chat)
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
    // - notHex = true: key is base64-encoded (from Kyber1024 or chat)
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
