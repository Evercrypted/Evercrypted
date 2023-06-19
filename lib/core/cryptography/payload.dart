import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';

decodePayload(
  resp,
  key,
) async {
  final algorithm = Chacha20.poly1305Aead();
  final secretBox = SecretBox(
    base64.decode(resp['crypted']),
    nonce: base64.decode(resp['iv']),
    mac: Mac(base64.decode(resp['mac'])),
  );
  print(key);
  final clearText =
      await algorithm.decrypt(secretBox, secretKey: SecretKey(hex.decode(key)));
  return json.decode(utf8.decode(clearText));
}

encodePayload(message, key) async {
  final algorithm = Chacha20.poly1305Aead();
  final secretBox = await algorithm.encrypt(
      utf8.encode(json.encode(message).toString()),
      secretKey: SecretKey(hex.decode(key)));
  return {
    'crypted': base64.encode(secretBox.cipherText),
    'iv': base64.encode(secretBox.nonce),
    'mac': base64.encode(secretBox.mac.bytes),
  };
}
