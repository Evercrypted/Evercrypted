import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';

dynamic decodePayload(crypted, iv, mac, key, [bool notHex = false]) async {
  final algorithm = Chacha20.poly1305Aead();
  final secretBox = SecretBox(
    base64.decode(crypted),
    nonce: base64.decode(iv),
    mac: Mac(base64.decode(mac)),
  );
  final clearText = await algorithm.decrypt(secretBox,
      secretKey:
          SecretKey(notHex == true ? utf8.encode(key) : hex.decode(key)));
  return json.decode(utf8.decode(clearText));
}

dynamic encodePayload(message, key, [bool notHex = false]) async {
  final algorithm = Chacha20.poly1305Aead();
  final secretBox = await algorithm.encrypt(
      utf8.encode(json.encode(message).toString()),
      secretKey:
          SecretKey(notHex == true ? utf8.encode(key) : hex.decode(key)));
  return {
    'crypted': base64.encode(secretBox.cipherText),
    'iv': base64.encode(secretBox.nonce),
    'mac': base64.encode(secretBox.mac.bytes),
  };
}
