import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/screens/messages/components/file_message.dart';
import 'package:evercrypted/screens/messages/components/image_message.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';

import '../../../ui_constants.dart';
import '../../../models/chat_message.dart';
import 'audio_message.dart';
import 'text_message.dart';

class MessageWidget extends StatefulWidget {
  const MessageWidget({
    super.key,
    required this.message,
    this.sender,
    required this.chat,
    required this.player,
  });

  final ChatMessage message;
  final Participant? sender;
  final Chat chat;

  final FlutterSoundPlayer player;

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  bool triedDecrypt = false;
  late ChatMessage message;

  @override
  void initState() {
    checkAndDecrypt();
    super.initState();
  }

  // @override
  // didChangeDependencies() {
  //   checkAndDecrypt();
  //   super.didChangeDependencies();
  // }

  @override
  didUpdateWidget(MessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    checkAndDecrypt();
    decrypt();
  }

  checkAndDecrypt() {
    message = widget.message;
    if (message.iv == null || message.mac == null) return;
    if (message.withBaseKey) {
      if (message.baseKey != null) {
        if (message.pass != null) {
          message.pass =
              message.baseKey!.substring(0, 32 - message.pass!.length) +
                  message.pass!;
        } else {
          message.pass = message.baseKey!;
        }
        decrypt();
      }
    } else {
      if (message.pass != null) {
        if (message.pass!.length < 32) {
          message.pass = message.pass! + '0' * (32 - message.pass!.length);
        }
        message.pass = widget.message.pass;
        decrypt();
      }
    }
  }

  decrypt() async {
    try {
      if (message.pass != null) {
        String? decrypted;
        int? decryptedDuration;
        if (message.messageType == MessageTypes.text && message.text != null) {
          decrypted = await decodePayload(
            message.text,
            message.iv,
            message.mac,
            message.pass,
            true,
          );
        }
        if (message.messageType == MessageTypes.audio &&
            message.duration != null &&
            message.decodedDuration == null) {
          decryptedDuration = await decodePayload(
            message.duration,
            message.durationIV,
            message.durationMAC,
            message.pass,
            true,
          );
        }
        setState(() {
          message.decodedDuration = decryptedDuration ?? 0;
          message.decrypted = decrypted ?? message.text;
          message.encryptionStatus = EncryptionStatus.decrypted;
        });
      }
    } catch (e) {
      setState(() {
        message.encryptionStatus = EncryptionStatus.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget messageContent(ChatMessage message) {
      switch (message.messageType) {
        case MessageTypes.text:
          return TextMessage(message: message);
        case MessageTypes.audio:
          return AudioMessage(
            message: message,
            player: widget.player,
          );
        case MessageTypes.file:
          return FileMessage(message: message);
        case MessageTypes.image:
          return ImageMessage(message: message);
        default:
          return const SizedBox();
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: defaultPadding / 2),
      child: message.isSystemMessage
          ? Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: defaultPadding, vertical: defaultPadding),
                child: Text(message.text!),
              ),
            )
          : Row(
              mainAxisAlignment: message.isSender
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!message.isSender && widget.sender != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (message.encryptionStatus !=
                          EncryptionStatus.notEncrypted) ...[
                        EncryptionStatusIcon(status: message.encryptionStatus),
                        const SizedBox(height: 2),
                      ],
                      CircleAvatarWithActiveIndicator(
                        image: widget.sender!.avatar?.pic,
                        radius: 12,
                        name: widget.sender!.name ?? widget.sender!.email,
                        initialsSize: 1,
                      ),
                    ],
                  ),
                  const SizedBox(width: defaultPadding / 3),
                ],
                messageContent(message),
                if (message.isSender) ...[
                  const SizedBox(width: defaultPadding / 4),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (message.encryptionStatus !=
                            EncryptionStatus.notEncrypted) ...[
                          EncryptionStatusIcon(
                              status: message.encryptionStatus),
                          const SizedBox(height: 2),
                        ],
                        MessageStatusDot(status: message.messageStatus),
                      ]),
                ],
              ],
            ),
    );
  }
}

class MessageStatusDot extends StatelessWidget {
  final MessageStatus? status;

  const MessageStatusDot({super.key, this.status});
  @override
  Widget build(BuildContext context) {
    Color dotColor(MessageStatus status) {
      switch (status) {
        case MessageStatus.couldNotSend:
          return errorColor;
        case MessageStatus.queued:
          return Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.3);
        case MessageStatus.successfullySent:
          return primaryColor;
        default:
          return Colors.transparent;
      }
    }

    return Icon(
      status == MessageStatus.couldNotSend
          ? Icons.pause_circle
          : Icons.check_circle,
      size: 22,
      color: dotColor(status!),
    );
  }
}

class EncryptionStatusIcon extends StatelessWidget {
  final EncryptionStatus? status;

  const EncryptionStatusIcon({super.key, this.status});
  @override
  Widget build(BuildContext context) {
    Color dotColor(EncryptionStatus status) {
      switch (status) {
        case EncryptionStatus.failed:
          return errorColor;
        case EncryptionStatus.encrypted:
          return Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.3);
        case EncryptionStatus.decrypted:
          return primaryColor;
        default:
          return Colors.transparent;
      }
    }

    return Icon(
      status == EncryptionStatus.encrypted
          ? Icons.gpp_maybe
          : status == EncryptionStatus.failed
              ? Icons.gpp_bad
              : Icons.gpp_good,
      size: 24,
      color: dotColor(status!),
    );
  }
}
