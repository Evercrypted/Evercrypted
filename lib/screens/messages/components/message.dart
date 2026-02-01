import 'dart:async';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/core/services/block_service.dart';
import 'package:evercrypted/core/socket/event_types/settings_event_types.dart';
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

    // If message has no IV, it's unencrypted - set status and return
    if (msg.iv == null) {
      if (mounted) {
        setState(() {
          message = msg;
          encryptionStatus = EncryptionStatus.notEncrypted;
        });
      }
      return;
    }

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
          if (inProcess.messageType == MessageTypes.text &&
              inProcess.text != null) {
            decrypted = await decodePayload(
              inProcess.text,
              inProcess.iv,
              inProcess.pass,
              true,
            );
          }

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

  void _showDeleteConfirmationDialog(
      BuildContext context, ChatMessage message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to delete this message?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: errorColor.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: errorColor.withAlpha((255 * 0.3).toInt()),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: errorColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'If this message hasn\'t been delivered to all participants yet, it will also be deleted from the server.',
                        style: TextStyle(
                          fontSize: 13,
                          color: errorColor.withAlpha((255 * 0.9).toInt()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (widget.onDelete != null) {
                  widget.onDelete!(message);
                }
              },
              style: TextButton.styleFrom(foregroundColor: errorColor),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showReportDialog(BuildContext context, ChatMessage message) {
    String? selectedReason;
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Report Message'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Why are you reporting this message?'),
                    const SizedBox(height: 16),
                    ...ReportReasons.options
                        .map((option) => RadioListTile<String>(
                              title: Text(option['label']!),
                              value: option['value']!,
                              groupValue: selectedReason,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              onChanged: (value) {
                                setState(() {
                                  selectedReason = value;
                                });
                              },
                            )),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Additional details (optional)',
                        hintText: 'Provide more context...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: selectedReason == null
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(dialogContext);
                          final senderId = widget.sender?.uid;
                          if (senderId == null) return;

                          final success = await BlockService.reportContent(
                            reportedUserId: senderId,
                            messageId: message.uid,
                            messageContent: message.text,
                            reason: selectedReason!,
                            description: descriptionController.text.isEmpty
                                ? null
                                : descriptionController.text,
                          );

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Thank you for reporting. We will review this within 24 hours.'
                                    : 'Failed to submit report. Or you have already reported this message.',
                              ),
                              backgroundColor:
                                  success ? Colors.green : Colors.red,
                            ),
                          );
                        },
                  child: const Text('Report'),
                ),
              ],
            );
          },
        );
      },
    );
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
                    _showDeleteConfirmationDialog(context, message);
                  },
                ),
                // Report message option (only for received messages)
                if (!message.isSender)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha((255 * 0.1).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.flag,
                          color: Colors.orange, size: 20),
                    ),
                    title: Text(
                      'Report message',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: contentColorLightThemeSecondary),
                    ),
                    subtitle: const Text(
                      'Report this message as inappropriate',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showReportDialog(context, message);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(int createdAtMSE) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(createdAtMSE);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';

    if (messageDate == today) {
      return time;
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday $time';
    } else if (now.difference(dateTime).inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[dateTime.weekday - 1]} $time';
    } else {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      return '$day/$month/${dateTime.year} $time';
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

    Widget messageWithTimestamp(ChatMessage message) {
      return Column(
        crossAxisAlignment: message.isSender
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () {
              _showMessageOptionsBottomSheet(context, message);
            },
            child: messageContent(message),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _formatTimestamp(message.createdAtMSE),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withAlpha((255 * 0.6).round())
                    : Colors.black.withAlpha((255 * 0.6).round()),
              ),
            ),
          ),
        ],
      );
    }

    return message != null
        ? Padding(
            padding: const EdgeInsets.only(top: defaultPadding / 2),
            child: message!.isSystemMessage
                ? Center(
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withAlpha(
                                  (255 * 0.1).round(),
                                ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: defaultPadding,
                              vertical: defaultPadding),
                          child: Text(message!.text!),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatTimestamp(message!.createdAtMSE),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withAlpha((255 * 0.6).round())
                                  : Colors.black.withAlpha((255 * 0.6).round()),
                            ),
                          ),
                        ),
                      ],
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
                      messageWithTimestamp(message!),
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
