import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:flutter_ever_crypto/flutter_ever_crypto.dart';

class EncryptedFile {
  final String iv;
  final String? mac;
  final Uint8List cryptedFile;

  EncryptedFile({required this.cryptedFile, required this.iv, this.mac});
}

// New implementations using flutter_ever_crypto
Future<EncryptedFile?> encodeFile(key, filePath, [bool notHex = true]) async {
  try {
    // Handle different key formats:
    // - notHex = true: key is base64-encoded (from Kyber1024 or chat)
    // - notHex = false: key is hex-encoded (legacy)
    final Uint8List keyBytes = notHex == true
        ? base64.decode(key)
        : Uint8List.fromList(hex.decode(key));
    final Uint8List nonceBytes = EverCrypto.generateXChaChaNonce();

    Uint8List fileBytes = File(filePath).readAsBytesSync();

    final ciphertextBytes = EverCrypto.xchachaEncrypt(
      keyBytes,
      nonceBytes,
      fileBytes,
    );

    return EncryptedFile(
      cryptedFile: ciphertextBytes,
      iv: base64.encode(nonceBytes),
    );
  } catch (e) {
    return null;
  }
}

Future<Uint8List> decodeFile(String key, String iv, List<int> cryptedFile,
    [bool notHex = true]) async {
  try {
    // Handle different key formats:
    // - notHex = true: key is base64-encoded (from Kyber1024 or chat)
    // - notHex = false: key is hex-encoded (legacy)
    final Uint8List keyBytes = notHex == true
        ? base64.decode(key)
        : Uint8List.fromList(hex.decode(key));
    final Uint8List nonceBytes = base64.decode(iv);
    final Uint8List ciphertextBytes = Uint8List.fromList(cryptedFile);

    final decryptedBytes = EverCrypto.xchachaDecrypt(
      keyBytes,
      nonceBytes,
      ciphertextBytes,
    );

    return decryptedBytes;
  } catch (e) {
    throw Exception('Failed to decode file: $e');
  }
}
