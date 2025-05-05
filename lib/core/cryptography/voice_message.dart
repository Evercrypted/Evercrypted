import 'dart:typed_data';

import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:cryptography_plus/cryptography_plus.dart';

import 'package:evercrypted/core/extensions/list_map_with_index_extension.dart';

class EncryptedRecording {
  final String iv;
  final String mac;
  final String cryptedRecording;

  EncryptedRecording(this.cryptedRecording, this.iv, this.mac);
}

Future<EncryptedRecording?> encodeRecording(key, Uint8List recording,
    [bool notHex = true]) async {
  try {
    final algorithm = Chacha20.poly1305Aead();
    final SecretBox secretBox = await algorithm.encrypt(recording,
        secretKey:
            SecretKey(notHex == true ? utf8.encode(key) : hex.decode(key)));
    return EncryptedRecording(base64.encode(secretBox.cipherText),
        base64.encode(secretBox.nonce), base64.encode(secretBox.mac.bytes));
  } catch (e) {
    return null;
  }
}

Future<Uint8List> decodeRecording(
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
