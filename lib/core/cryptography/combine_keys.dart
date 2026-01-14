import 'dart:convert';
import 'package:flutter_ever_crypto/flutter_ever_crypto.dart';

Future<String> combineKeys(String publicKeyBase64, String secretKeyBase64,
    String ciphertextBase64) async {
  final secretKey = base64Decode(secretKeyBase64);
  final ciphertext = base64Decode(ciphertextBase64);

  // Decapsulate the shared secret using Kyber1024
  final sharedSecret = EverCrypto.kyberDecapsulate(ciphertext, secretKey);

  return base64Encode(sharedSecret);
}

Future<Map<String, String>> encapsulateKey(String publicKeyBase64) async {
  final publicKey = base64Decode(publicKeyBase64);

  // Encapsulate a shared secret using Kyber1024
  final encapsulateResult = EverCrypto.kyberEncapsulate(publicKey);

  return {
    'sharedSecret': base64Encode(encapsulateResult.sharedSecret),
    'ciphertext': base64Encode(encapsulateResult.ciphertext),
  };
}
