import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'package:convert/convert.dart';

import 'package:evercrypted/core/extensions/list_map_with_index_extension.dart';

class EncryptedRecording {
  final String iv;
  final String mac;
  final String cryptedRecording;

  EncryptedRecording(this.cryptedRecording, this.iv, this.mac);
}

Future<EncryptedRecording?> encodeRecording(key, List<Uint8List> recording,
    [bool notHex = true]) async {
  try {
    final algorithm = Chacha20.poly1305Aead();
    Uint8List bytes = utf8.encode(recording.toString());
    final SecretBox secretBox = await algorithm.encrypt(bytes,
        secretKey:
            SecretKey(notHex == true ? utf8.encode(key) : hex.decode(key)));
    return EncryptedRecording(base64.encode(secretBox.cipherText),
        base64.encode(secretBox.nonce), base64.encode(secretBox.mac.bytes));
  } catch (e) {
    return null;
  }
}

Future<List<Uint8List>> decodeRecording(
    {String? key,
    String? iv,
    String? mac,
    required String cryptedRecording,
    bool notHex = true,
    bool isEncrypted = true}) async {
  late final String stringList;
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
    stringList = utf8.decode(decrypted);
  } else {
    stringList = utf8.decode(base64Decode(cryptedRecording));
  }
  final List<String> listString =
      stringList.substring(1, stringList.length - 1).split('],');
  final List<String> modified = listString
      .mapWithIndex((e, index) => index != listString.length - 1 ? '$e]' : e)
      .toList();
  List<Uint8List> decoded = modified.map((e) {
    return Uint8List.fromList(json.decode(e).cast<int>().toList());
  }).toList();
  return decoded;
}
