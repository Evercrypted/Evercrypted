import 'package:flutter/material.dart';

import '../../../ui_constants.dart';
import '../../../models/chat_message.dart';

class TextMessage extends StatelessWidget {
  const TextMessage({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: primaryColor
            .withAlpha(((message.isSender ? 1 : 0.1) * 255).round()),
        borderRadius: BorderRadius.circular(30),
      ),
      child: SelectableText(
        showCursor: true,
        message.encryptionStatus == EncryptionStatus.decrypted
            ? message.decrypted!
            : message.text!,
        style: TextStyle(
          color: message.isSender
              ? Colors.white
              : Theme.of(context).textTheme.bodyLarge!.color,
        ),
      ),
    );
  }
}
