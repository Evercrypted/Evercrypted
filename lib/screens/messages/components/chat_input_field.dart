import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/entities/message/message_isar.dart';
import '../../../core/entities/message/message_service.dart';
import '../../../ui_constants.dart';
import 'voice_recorder_button.dart';
import 'message_attachment.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ChatInputField extends StatefulWidget {
  final String chatId;
  final String? pass;
  final String? iv;
  const ChatInputField({Key? key, required this.chatId, this.pass, this.iv})
      : super(key: key);

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
    var encr = message;
    if (widget.pass != null) {
      if (widget.pass != null && widget.pass!.isNotEmpty == true) {
        var fullKeyString = widget.pass;
        if (fullKeyString!.length < 32) {
          fullKeyString = fullKeyString + '0' * (32 - widget.pass!.length);
        }
        final key = encrypt.Key.fromUtf8(fullKeyString);
        final encrypter = encrypt.Encrypter(encrypt.AES(key));
        if (widget.iv != null) {
          final iv = encrypt.IV.fromUtf8(widget.iv!);
          encr = encrypter.encrypt(message, iv: iv).base64;
        } else {
          encr = encrypter.encrypt(message).base64;
        }
      }
    }
    final newMessage = Message(
      chatId: widget.chatId,
      createdAtMSE: DateTime.now().millisecondsSinceEpoch,
      text: encr,
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
                const VoiceRecorderButton(),
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
          if (_showAttachment) const MessageAttachment(),
        ],
      ),
    );
  }
}
