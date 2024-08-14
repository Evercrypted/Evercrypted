import 'package:encrypt/encrypt.dart';
import 'dart:convert';

fernetEncrypt(String? text, String secureKey) {
  if (text == null) return null;
  final key = Key.fromUtf8(secureKey);

  final b64key = Key.fromUtf8(base64Url.encode(key.bytes).substring(0, 32));
  // if you need to use the ttl feature, you'll need to use APIs in the algorithm itself
  final fernet = Fernet(b64key);
  final encrypter = Encrypter(fernet);
  final encrypted = encrypter.encrypt(text);
  return encrypted.base64;
}

fernetDecrypt(String? base64cypher, String secureKey) {
  if (base64cypher == null) return null;
  final key = Key.fromUtf8(secureKey);

  final b64key = Key.fromUtf8(base64Url.encode(key.bytes).substring(0, 32));
  final fernet = Fernet(b64key);
  final encrypter = Encrypter(fernet);
  final decrypted = encrypter.decrypt(Encrypted.fromBase64(base64cypher));
  return decrypted;
}
