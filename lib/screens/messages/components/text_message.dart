import 'package:flutter/material.dart';

import '../../../ui_constants.dart';
import '../../../models/ChatMessage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class TextMessage extends StatelessWidget {
  const TextMessage({Key? key, this.message, this.pass, this.iv})
      : super(key: key);

  final ChatMessage? message;
  final String? pass;
  final String? iv;

  @override
  Widget build(BuildContext context) {
    var decr = message!.text;
    try {
      if (pass != null && pass!.isNotEmpty == true) {
        if (pass != null) {
          var fullKeyString = pass;
          if (fullKeyString!.length < 32) {
            fullKeyString = fullKeyString + '0' * (32 - pass!.length);
          }
          final key = encrypt.Key.fromUtf8(fullKeyString);
          final encrypter = encrypt.Encrypter(encrypt.AES(key));
          if (iv != null) {
            final decrIV = encrypt.IV.fromUtf8(iv!);
            decr = encrypter.decrypt64(decr, iv: decrIV);
          } else {
            decr = encrypter.decrypt64(decr);
          }
        }
      }
    } catch (e) {
      decr = 'Can\'t decrypt message';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: defaultPadding * 0.75,
        vertical: defaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(message!.isSender ? 1 : 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        decr,
        style: TextStyle(
          color: message!.isSender
              ? Colors.white
              : Theme.of(context).textTheme.bodyText1!.color,
        ),
      ),
    );
  }
}
