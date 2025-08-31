import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/screens/messages/components/file_message.dart';
import 'package:evercrypted/screens/messages/components/image_message.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.onDelete,
  });

  final ChatMessage message;
  final Participant? sender;
  final Chat chat;
  final FlutterSoundPlayer player;
  final Function(ChatMessage)? onDelete;

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  bool triedDecrypt = false;
  ChatMessage? message;
  EncryptionStatus? encryptionStatus;

  @override
  void initState() {
    checkAndDecrypt(true);
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
    checkAndDecrypt(false);
    // decrypt();
  }

  checkAndDecrypt(bool? isInit) async {
    if (encryptionStatus == EncryptionStatus.decrypted ||
        encryptionStatus == EncryptionStatus.notEncrypted) {
      return;
    }
    ChatMessage msg = widget.message;
    if (msg.iv == null) return;

    // Use the same SHA256-based key derivation as encryption
    String? inputForHashing;

    if (msg.withBaseKey) {
      if (msg.baseKey != null) {
        if (msg.pass != null) {
          // Combine baseKey and pass
          inputForHashing = msg.baseKey! + msg.pass!;
        } else {
          // Use baseKey only
          inputForHashing = msg.baseKey!;
        }
      }
    } else {
      if (msg.pass != null) {
        // Use pass only
        inputForHashing = msg.pass!;
      }
    }

    if (inputForHashing != null) {
      // ALWAYS hash the input to ensure exactly 32 bytes (same as encryption)
      final hash = sha256.convert(utf8.encode(inputForHashing));
      final hashedKey = base64Encode(hash.bytes);

      // Update the message with the hashed key
      msg.pass = hashedKey;
      msg = await decrypt(msg);
    }

    if (mounted) {
      setState(() {
        message = msg;
      });
    }
  }

  Future<ChatMessage> decrypt(ChatMessage msg) async {
    Completer<ChatMessage> completer = Completer<ChatMessage>();
    ChatMessage inProcess = msg;
    if (inProcess.encryptionStatus == EncryptionStatus.decrypted ||
        inProcess.encryptionStatus == EncryptionStatus.notEncrypted) {
      completer.complete(inProcess);
    } else {
      try {
        if (inProcess.pass != null) {
          String? decrypted;
          int? decryptedDuration;
          if (inProcess.messageType == MessageTypes.text &&
              inProcess.text != null) {
            decrypted = await decodePayload(
              inProcess.text,
              inProcess.iv,
              inProcess.pass,
              true,
            );
          }
          if (inProcess.messageType == MessageTypes.audio &&
              inProcess.duration != null &&
              inProcess.decodedDuration == null) {
            decryptedDuration = await decodePayload(
              inProcess.duration,
              inProcess.durationIV,
              inProcess.pass,
              true,
            );
          }

          inProcess.decodedDuration = decryptedDuration ?? 0;
          inProcess.decrypted = decrypted ?? widget.message.text;
          inProcess.encryptionStatus = EncryptionStatus.decrypted;
          encryptionStatus = EncryptionStatus.decrypted;
        }
      } catch (e) {
        inProcess.encryptionStatus = EncryptionStatus.failed;
        encryptionStatus = EncryptionStatus.failed;
      }
      completer.complete(inProcess);
    }

    return completer.future;
  }

  void _showMessageOptionsBottomSheet(
      BuildContext context, ChatMessage message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (message.messageType == MessageTypes.text &&
                    message.encryptionStatus == EncryptionStatus.decrypted &&
                    message.decrypted != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha((255 * 0.1).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.copy, color: primaryColor, size: 20),
                    ),
                    title: Text(
                      'Copy text',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: contentColorLightThemeSecondary),
                    ),
                    subtitle: const Text(
                      'Copy message text to clipboard',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Clipboard.setData(
                          ClipboardData(text: message.decrypted!));
                    },
                  ),
                if (message.messageType == MessageTypes.text &&
                    message.encryptionStatus != EncryptionStatus.decrypted &&
                    message.text != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha((255 * 0.1).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.copy, color: primaryColor, size: 20),
                    ),
                    title: Text(
                      'Copy text',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: contentColorLightThemeSecondary),
                    ),
                    subtitle: const Text(
                      'Copy message text to clipboard',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Clipboard.setData(ClipboardData(text: message.text!));
                    },
                  ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: errorColor.withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.delete, color: errorColor, size: 20),
                  ),
                  title: Text(
                    'Delete message',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: contentColorLightThemeSecondary),
                  ),
                  subtitle: const Text(
                    'Delete this message',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onDelete != null) {
                      widget.onDelete!(message);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
          return ImageMessage(
            message: message,
            encryptionStatusCallback: (status) {
              if (mounted) {
                if (status != null && status != encryptionStatus) {
                  setState(() {
                    encryptionStatus = status;
                  });
                }
              }
            },
          );
        default:
          return const SizedBox();
      }
    }

    return message != null
        ? Padding(
            padding: const EdgeInsets.only(top: defaultPadding / 2),
            child: message!.isSystemMessage
                ? Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withAlpha(
                              (255 * 0.1).round(),
                            ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: defaultPadding, vertical: defaultPadding),
                      child: Text(message!.text!),
                    ),
                  )
                : Row(
                    mainAxisAlignment: message!.isSender
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!message!.isSender && widget.sender != null) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            EncryptionStatusIcon(status: encryptionStatus),
                            const SizedBox(height: 2),
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
                      GestureDetector(
                        onLongPress: () {
                          _showMessageOptionsBottomSheet(context, message!);
                        },
                        child: messageContent(message!),
                      ),
                      if (message!.isSender) ...[
                        const SizedBox(width: defaultPadding / 4),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (encryptionStatus ==
                                  EncryptionStatus.encrypted) ...[
                                EncryptionStatusIcon(status: encryptionStatus),
                                const SizedBox(height: 2),
                              ],
                              MessageStatusDot(status: message!.messageStatus),
                            ]),
                      ],
                    ],
                  ),
          )
        : const SizedBox();
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
          return Theme.of(context)
              .textTheme
              .bodyLarge!
              .color!
              .withAlpha((255 * 0.3).round());
        case MessageStatus.successfullySent:
          return primaryColor;
      }
    }

    return status != null
        ? Icon(
            status == MessageStatus.couldNotSend
                ? Icons.error
                : Icons.check_circle,
            size: 22,
            color: dotColor(status!),
          )
        : SizedBox();
  }
}

class EncryptionStatusIcon extends StatelessWidget {
  final EncryptionStatus? status;

  const EncryptionStatusIcon({super.key, this.status});
  @override
  Widget build(BuildContext context) {
    Color dotColor(EncryptionStatus? status) {
      switch (status) {
        case EncryptionStatus.failed:
          return errorColor;
        case EncryptionStatus.encrypted:
          return Theme.of(context)
              .textTheme
              .bodyLarge!
              .color!
              .withAlpha((255 * 0.3).round());
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
      color: dotColor(status),
    );
  }
}
