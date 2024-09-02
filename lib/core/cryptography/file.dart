import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:evercrypted/core/helpers/as_uinteight_list.dart';

class EncryptedFile {
  final String iv;
  final String mac;
  final Uint8List cryptedFile;

  EncryptedFile(this.cryptedFile, this.iv, this.mac);
}

Future<EncryptedFile?> encodeFile(key, filePath, [bool notHex = true]) async {
  try {
    final algorithm = Chacha20.poly1305Aead();
    Uint8List bytes = File(filePath).readAsBytesSync();
    final SecretBox secretBox = await algorithm.encrypt(bytes,
        secretKey:
            SecretKey(notHex == true ? utf8.encode(key) : hex.decode(key)));
    return EncryptedFile(secretBox.cipherText.asUint8List(),
        base64.encode(secretBox.nonce), base64.encode(secretBox.mac.bytes));
  } catch (e) {
    return null;
  }
}

Future<Uint8List> decodeFile(
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
