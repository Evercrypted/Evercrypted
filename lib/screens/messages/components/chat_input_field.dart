import 'package:flutter/material.dart';

import '../../../ui_constants.dart';
import 'voice_recorder_button.dart';
import 'message_attachment.dart';

class ChatInputField extends StatefulWidget {
  const ChatInputField({
    Key? key,
  }) : super(key: key);

  @override
  _ChatInputFieldState createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  bool _showAttachment = false;

  void _updateAttachmentState() {
    setState(() {
      _showAttachment = !_showAttachment;
    });
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
                SizedBox(width: defaultPadding),
                VoiceRecorderButton(),
                SizedBox(width: defaultPadding),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(width: defaultPadding / 4),
                      Expanded(
                        child: TextField(
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
                                                .bodyText1!
                                                .color!
                                                .withOpacity(0.64),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: defaultPadding / 2),
                                      child: Icon(
                                        Icons.camera_alt_outlined,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText1!
                                            .color!
                                            .withOpacity(0.64),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ),
                      ),
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
