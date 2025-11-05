import 'dart:typed_data';

import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter_ever_crypto/flutter_ever_crypto.dart';

class EncryptedRecording {
  final String iv;
  final String? mac;
  final String cryptedRecording;

  EncryptedRecording(
      {required this.cryptedRecording, required this.iv, this.mac});
}

// Old implementations using cryptography_plus
Future<EncryptedRecording?> encodeRecordingOld(key, Uint8List recording,
    [bool notHex = true]) async {
  try {
    final algorithm = Chacha20.poly1305Aead();
    final SecretBox secretBox = await algorithm.encrypt(recording,
        secretKey:
            SecretKey(notHex == true ? utf8.encode(key) : hex.decode(key)));
    return EncryptedRecording(
        cryptedRecording: base64.encode(secretBox.cipherText),
        iv: base64.encode(secretBox.nonce),
        mac: base64.encode(secretBox.mac.bytes));
  } catch (e) {
    return null;
  }
}

Future<Uint8List> decodeRecordingOld(
    {String? key,
    String? iv,
    String? mac,
    required String cryptedRecording,
    bool notHex = true,
    bool isEncrypted = true}) async {
  late final Uint8List recording;
  if (isEncrypted && key != null && iv != null && mac != null) {
    final algorithm = Chacha20.poly1305Aead();
    final secretBox = SecretBox(
      base64.decode(cryptedRecording),
      nonce: base64.decode(iv),
      mac: Mac(base64.decode(mac)),
    );
    final decrypted = await algorithm.decrypt(secretBox,
        secretKey:
            SecretKey(notHex == true ? utf8.encode(key) : hex.decode(key)));
    recording = Uint8List.fromList(decrypted);
  } else {
    recording = base64Decode(cryptedRecording);
  }
  return recording;
}

// New implementations using flutter_ever_crypto
Future<EncryptedRecording?> encodeRecording(key, Uint8List recording,
    [bool notHex = true]) async {
  try {
    // Handle different key formats:
    // - notHex = true: key is base64-encoded (from Kyber1024 or chat)
    // - notHex = false: key is hex-encoded (legacy)
    final Uint8List keyBytes = notHex == true
        ? base64.decode(key)
        : Uint8List.fromList(hex.decode(key));
    final Uint8List nonceBytes = EverCrypto.generateXChaChaNonce();

    final ciphertextBytes = EverCrypto.xchachaEncrypt(
      keyBytes,
      nonceBytes,
      recording,
    );

    return EncryptedRecording(
      cryptedRecording: base64.encode(ciphertextBytes),
      iv: base64.encode(nonceBytes),
    );
  } catch (e) {
    return null;
  }
}

Future<Uint8List> decodeRecording(
    {String? key,
    String? iv,
    required String cryptedRecording,
    bool notHex = true,
    bool isEncrypted = true}) async {
  try {
    late final Uint8List recording;
    if (isEncrypted && key != null && iv != null) {
      // Handle different key formats:
      // - notHex = true: key is base64-encoded (from Kyber1024 or chat)
      // - notHex = false: key is hex-encoded (legacy)
      final Uint8List keyBytes = notHex == true
          ? base64.decode(key)
          : Uint8List.fromList(hex.decode(key));
      final Uint8List nonceBytes = base64.decode(iv);
      final Uint8List ciphertextBytes = base64.decode(cryptedRecording);

      final decryptedBytes = EverCrypto.xchachaDecrypt(
        keyBytes,
        nonceBytes,
        ciphertextBytes,
      );

      recording = decryptedBytes;
    } else {
      recording = base64Decode(cryptedRecording);
    }
    return recording;
  } catch (e) {
    throw Exception('Failed to decode recording: $e');
  }
}

// Helper to create combined recording payload with metadata as JSON
// This combines recording data (base64), duration, and decibels into a single JSON object
Map<String, dynamic> createRecordingPayload(
    Uint8List recording,
    int durationMicroSeconds,
    List<double> decibels) {
  return {
    'recording': base64.encode(recording),
    'duration': durationMicroSeconds,
    'decibels': decibels,
  };
}

// Helper to extract recording data from payload
Map<String, dynamic> parseRecordingPayload(dynamic payload) {
  return {
    'recording': base64.decode(payload['recording']),
    'duration': payload['duration'],
    'decibels': List<double>.from(payload['decibels']),
  };
}
