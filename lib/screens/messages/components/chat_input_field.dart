import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/widgets/secret_keyboard/secret_input.dart';
import 'package:flutter/material.dart';

import '../../../core/entities/message/message_service.dart';
import '../../../ui_constants.dart';
import 'voice_recorder_button.dart';
import 'message_attachment.dart';

class ChatInputField extends StatefulWidget {
  final String chatId;
  final String? pass;
  final String? baseKey;
  const ChatInputField(
      {super.key, required this.chatId, this.pass, this.baseKey});

  @override
  ChatInputFieldState createState() => ChatInputFieldState();
}

class ChatInputFieldState extends State<ChatInputField> {
  bool _showAttachment = false;
  final TextEditingController _messageField = TextEditingController();
  final MessageService _messageService = MessageService();

  void _updateAttachmentState() {
    setState(() {
      _showAttachment = !_showAttachment;
    });
  }

  void sendMessage(String message) async {
    if (message.isEmpty) {
      return;
    }
    dynamic encr = message;
    String? fullKeyString;
    if (widget.baseKey != null) {
      if (widget.pass != null) {
        fullKeyString = widget.baseKey!.substring(0, 32 - widget.pass!.length) +
            widget.pass!;
      } else {
        fullKeyString = widget.baseKey!;
      }
    } else {
      if (widget.pass != null) {
        if (widget.pass!.length < 32) {
          fullKeyString = widget.pass! + '0' * (32 - widget.pass!.length);
        }
      }
    }
    if (fullKeyString != null) {
      encr = await encodePayload(message, fullKeyString, true);
    }
    _messageService.sendMessage(encr, widget.chatId);
    _messageField.clear();
  }

  @override
  void dispose() {
    _messageField.dispose();
    super.dispose();
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
                VoiceRecorderButton(pass: widget.pass, chatId: widget.chatId),
                const SizedBox(width: defaultPadding / 4),
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(width: defaultPadding / 4),
                      Expanded(
                        child: TextField(
                          controller: _messageField,
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
                                          sendMessage(_messageField.text);
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
                          onTap: () {
                            openSecretInput(
                                context: context,
                                controller: _messageField,
                                done: (val) => sendMessage(val.text));
                          },
                          keyboardType: TextInputType.none,
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
