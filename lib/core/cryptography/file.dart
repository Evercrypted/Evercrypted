import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';

import 'package:convert/convert.dart';

Future<Map<String, dynamic>> encodeFile(key, filePath,
    [bool notHex = false]) async {
  final algorithm = Chacha20.poly1305Aead();
  Uint8List bytes = File(filePath).readAsBytesSync();
  final SecretBox secretBox = await algorithm.encrypt(bytes,
      secretKey:
          SecretKey(notHex == true ? utf8.encode(key) : hex.decode(key)));
  return {
    'cryptedFile': secretBox.cipherText,
    'iv': base64.encode(secretBox.nonce),
    'mac': base64.encode(secretBox.mac.bytes),
  };
}

Future<List<int>> decodeFile(
    String key, String iv, String mac, List<int> cryptedFile,
    [bool notHex = false]) async {
  final algorithm = Chacha20.poly1305Aead();
  final secretBox = SecretBox(
    cryptedFile,
    nonce: base64.decode(iv),
    mac: Mac(base64.decode(mac)),
  );
  return algorithm.decrypt(secretBox,
      secretKey:
          SecretKey(notHex == true ? utf8.encode(key) : hex.decode(key)));
}
