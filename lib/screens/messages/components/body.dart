import 'package:flutter/material.dart';

import '../../../ui_constants.dart';
import '../../../models/ChatMessage.dart';
import 'message.dart';

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: ListView.builder(
              itemCount: demeChatMessages.length,
              itemBuilder: (context, index) =>
                  MessageWidget(message: demeChatMessages[index]),
            ),
          ),
        ),
        // ChatInputField(),
      ],
    );
  }
}
