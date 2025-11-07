import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_ever_crypto/flutter_ever_crypto.dart';

/// Encrypts text for database storage using XChaCha20-Poly1305.
/// The nonce is generated automatically and prepended to the ciphertext.
/// Returns base64-encoded result containing [nonce + ciphertext].
String? encryptForDb(String? text, String secureKey) {
  try {
    if (text == null) return null;

    // Derive a consistent 32-byte key from the secureKey
    final keyBytes = _deriveKey(secureKey);

    // Generate random nonce (24 bytes for XChaCha20)
    final nonceBytes = EverCrypto.generateXChaChaNonce();

    // Encrypt the text
    final plaintextBytes = Uint8List.fromList(utf8.encode(text));
    final ciphertextBytes = EverCrypto.xchachaEncrypt(
      keyBytes,
      nonceBytes,
      plaintextBytes,
    );

    // Combine nonce + ciphertext and encode as base64
    final combined = Uint8List(nonceBytes.length + ciphertextBytes.length);
    combined.setRange(0, nonceBytes.length, nonceBytes);
    combined.setRange(nonceBytes.length, combined.length, ciphertextBytes);

    return base64.encode(combined);
  } catch (e) {
    return text;
  }
}

/// Decrypts text that was encrypted with encryptForDb.
/// Expects base64-encoded input containing [nonce + ciphertext].
String? decryptForDb(String? base64cipher, String secureKey) {
  try {
    if (base64cipher == null) return null;

    // Derive the same key
    final keyBytes = _deriveKey(secureKey);

    // Decode from base64
    final combined = base64.decode(base64cipher);

    // Extract nonce (first 24 bytes) and ciphertext (rest)
    const nonceLength = 24;
    if (combined.length < nonceLength) {
      throw Exception('Invalid ciphertext: too short');
    }

    final nonceBytes = Uint8List.sublistView(combined, 0, nonceLength);
    final ciphertextBytes = Uint8List.sublistView(combined, nonceLength);

    // Decrypt
    final plaintextBytes = EverCrypto.xchachaDecrypt(
      keyBytes,
      nonceBytes,
      ciphertextBytes,
    );

    return utf8.decode(plaintextBytes);
  } catch (e) {
    return base64cipher;
  }
}

Uint8List _deriveKey(String secureKey) {
  // Convert secureKey to bytes
  final keyBytes = utf8.encode(secureKey);

  // If key is already 32 bytes, use it directly
  if (keyBytes.length == 32) {
    return Uint8List.fromList(keyBytes);
  }

  // Otherwise, derive 32 bytes using base64 encoding (matches original behavior)
  final b64key = base64Url.encode(keyBytes);
  final derivedBytes = utf8.encode(b64key);

  // Take first 32 bytes or pad if necessary
  final result = Uint8List(32);
  final copyLength = derivedBytes.length < 32 ? derivedBytes.length : 32;
  result.setRange(0, copyLength, derivedBytes);

  return result;
}
