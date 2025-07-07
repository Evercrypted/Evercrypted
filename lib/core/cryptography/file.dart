import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:evercrypted/core/helpers/as_uinteight_list.dart';
import 'package:flutter_ever_crypto/flutter_ever_crypto.dart';

class EncryptedFile {
  final String iv;
  final String? mac;
  final Uint8List cryptedFile;

  EncryptedFile({required this.cryptedFile, required this.iv, this.mac});
}

// Old implementations using cryptography_plus
Future<EncryptedFile?> encodeFileOld(key, filePath,
    [bool notHex = true]) async {
  try {
    final algorithm = Chacha20.poly1305Aead();
    Uint8List bytes = File(filePath).readAsBytesSync();
    final SecretBox secretBox = await algorithm.encrypt(bytes,
        secretKey:
            SecretKey(notHex == true ? utf8.encode(key) : hex.decode(key)));
    return EncryptedFile(
        cryptedFile: secretBox.cipherText.asUint8List(),
        iv: base64.encode(secretBox.nonce),
        mac: base64.encode(secretBox.mac.bytes));
  } catch (e) {
    return null;
  }
}

Future<Uint8List> decodeFileOld(
    String key, String iv, String mac, List<int> cryptedFile,
    [bool notHex = true]) async {
  final algorithm = Chacha20.poly1305Aead();
  final secretBox = SecretBox(
    cryptedFile,
    nonce: base64.decode(iv),
    mac: Mac(base64.decode(mac)),
  );
  final decrypted = await algorithm.decrypt(secretBox,
      secretKey:
          SecretKey(notHex == true ? utf8.encode(key) : hex.decode(key)));
  return decrypted.asUint8List();
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
