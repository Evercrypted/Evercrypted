import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/entities/message/message_isar.dart';
import '../../../core/entities/message/message_service.dart';
import '../../../ui_constants.dart';
import 'voice_recorder_button.dart';
import 'message_attachment.dart';

class ChatInputField extends StatefulWidget {
  final String chatId;
  const ChatInputField({Key? key, required this.chatId}) : super(key: key);

  @override
  ChatInputFieldState createState() => ChatInputFieldState();
}

class ChatInputFieldState extends State<ChatInputField> {
  bool _showAttachment = false;
  final TextEditingController messageField = TextEditingController();
  final MessageService _messageService = MessageService();

  void _updateAttachmentState() {
    setState(() {
      _showAttachment = !_showAttachment;
    });
  }

  void sendMessage(String message) {
    final newMessage = Message(
      chatId: widget.chatId,
      createdAtMSE: DateTime.now().millisecondsSinceEpoch,
      text: message,
      authorId: FirebaseAuth.instance.currentUser!.uid,
    );
    _messageService.sendMessage(newMessage);
    messageField.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: [
                const SizedBox(width: defaultPadding / 2),
                VoiceRecorderButton(),
                const SizedBox(width: defaultPadding / 4),
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(width: defaultPadding / 4),
                      Expanded(
                        child: TextField(
                          controller: messageField,
                          decoration: InputDecoration(
                            hintText: "Type message",
                            suffixIcon: SizedBox(
                              width: 65,
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: _updateAttachmentState,
                                    child: Icon(
                                      Icons.attach_file,
                                      color: _showAttachment
                                          ? primaryColor
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .color!
                                              .withOpacity(0.64),
                                    ),
                                  ),
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: defaultPadding / 2),
                                      child: InkWell(
                                        onTap: () {
                                          sendMessage(messageField.text);
                                        },
                                        child: const Icon(
                                          Icons.send,
                                          color: primaryColor,
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              sendMessage(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: defaultPadding / 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showAttachment) MessageAttachment(),
        ],
      ),
    );
  }
}
