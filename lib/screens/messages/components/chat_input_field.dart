import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue_model.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/core/cryptography/voice_message.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_text_controller.dart';
import 'package:evercrypted/screens/messages/components/camera.dart';
import 'package:evercrypted/widgets/fade_icon.dart';
import 'package:evercrypted/widgets/evercrypted_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';

import '../../../core/entities/message/message_service.dart';
import '../../../ui_constants.dart';
import 'audio_waveform_bars.dart';
import 'voice_recorder_button.dart';

class ChatInputField extends ConsumerStatefulWidget {
  final Chat chat;
  final String? pass;
  final String? baseKey;
  final FlutterSoundPlayer player;
  final Function onDelete;
  final Function(bool, List<double>)? onRecordingStateChange;
  const ChatInputField(
      {super.key,
      required this.chat,
      required this.player,
      this.pass,
      this.baseKey,
      required this.onDelete,
      this.onRecordingStateChange});

  @override
  ChatInputFieldState createState() => ChatInputFieldState();
}

class ChatInputFieldState extends ConsumerState<ChatInputField> {
  final EvercryptedTextController _messageField = EvercryptedTextController();
  final MessageService _messageService = MessageService();
  String? fullKey;
  int? recordingMicroSeconds;
  Uint8List? recordingData;
  bool sendingFile = false;
  PlatformFile? file;
  bool withBaseKey = false;
  List<double> recordingDecibels = [];
  bool isRecording = false;
  static const int _overlaySampleLimit = 200;

  @override
  void initState() {
    super.initState();
    setFullKey();
  }

  @override
  void didUpdateWidget(ChatInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    setFullKey();
  }

  void setFullKey() {
    try {
      String? inputForHashing;

      if (widget.baseKey != null) {
        withBaseKey = true;
        if (widget.pass != null) {
          // Combine baseKey and pass
          inputForHashing = widget.baseKey! + widget.pass!;
        } else {
          // Use baseKey only
          inputForHashing = widget.baseKey!;
        }
      } else {
        if (widget.pass != null) {
          // Use pass only
          inputForHashing = widget.pass!;
        } else {
          fullKey = null;
          return;
        }
      }

      // ALWAYS hash the input to ensure exactly 32 bytes
      final hash = sha256.convert(utf8.encode(inputForHashing));
      fullKey = base64Encode(hash.bytes);
    } catch (e) {
      fullKey = null;
    }
  }

  void sendMessage(String message) async {
    if (message.isEmpty) {
      return;
    }

    // Check if user has premium access - if not, send unencrypted
    final bool hasPremium = Auth.getUser?.activated == true;
    if (!hasPremium) {
      _messageService.sendMessage(message, widget.chat.uid, false);
      _messageField.clear();
      return;
    }

    // Check if we have a key for encryption
    if (fullKey != null) {
      // We have the key - encrypt and send normally
      dynamic encr = message;
      try {
        encr = await encodePayload(message, fullKey, true);
      } catch (e) {
        rethrow;
      }
      _messageService.sendMessage(encr, widget.chat.uid, withBaseKey);
      _messageField.clear();
    } else {
      // No encryption key available - queue message regardless of chat type
      if (widget.baseKey == null) {
        // Queue message until key is available (works for both one-to-one and group chats)
        await _queueMessageUntilKeyExchange(
          widget.chat.uid,
          text: message,
          messageType: MessageTypes.text,
        );
        _messageField.clear();

        // Show user feedback that message is queued
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.chat.isOneToOne
                  ? 'Message queued - waiting for secure connection'
                  : 'Message queued - waiting for group encryption key'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Send normally (fallback case)
        _messageService.sendMessage(message, widget.chat.uid, withBaseKey);
        _messageField.clear();
      }
    }
  }

  Future<void> _queueMessageUntilKeyExchange(
    String chatUid, {
    String? text,
    String? messageType,
    Uint8List? fileData,
    String? fileName,
    int? duration,
    List<double>? waveData,
  }) async {
    // Store in action queue with special type for key-pending messages
    final action = ActionQueue(
      channel: SocketChannelTypes.message,
      type: 'sendMessagePendingKey',
      payload: json.encode({
        'chatUid': chatUid,
        'text': text,
        'messageType': messageType ?? MessageTypes.text,
        'fileData': fileData != null ? base64Encode(fileData) : null,
        'fileName': fileName,
        'duration': duration,
        'waveData': waveData,
      }),
      createdAtMSE: DateTime.now().millisecondsSinceEpoch,
    );
    obx.actionQueues.put(action);
    debugPrint(
        'Queued $messageType message for chat $chatUid until key exchange completes');
  }

  onRecording(Uint8List recordingData, int recordingMicroSeconds,
      List<double> decibels) {
    setState(() {
      this.recordingData = recordingData;
      this.recordingMicroSeconds = recordingMicroSeconds;
      recordingDecibels = decibels;
    });
  }

  onDecibelChange(double normalizedDecibels) {
    if (!isRecording) {
      return;
    }

    // Collect decibel values in real-time during recording
    setState(() {
      recordingDecibels.add(normalizedDecibels.clamp(0.0, 1.0));
      if (recordingDecibels.length > _overlaySampleLimit) {
        recordingDecibels.removeRange(
            0, recordingDecibels.length - _overlaySampleLimit);
      }
    });

    widget.onRecordingStateChange
        ?.call(true, List<double>.from(recordingDecibels));
  }

  void _handleRecordingToggle(bool recording) {
    if (isRecording == recording) {
      return;
    }

    setState(() {
      isRecording = recording;
      if (recording) {
        recordingDecibels = [];
      }
    });
    widget.onRecordingStateChange
        ?.call(recording, recording ? const <double>[] : const <double>[]);
  }

  sendAudio(context) async {
    if (recordingData == null ||
        recordingData!.isEmpty ||
        recordingMicroSeconds == null) {
      return;
    }
    if (sendingFile) {
      return;
    }
    // probably only needed for iOS
    // final storageStatus = await Permission.storage.request();
    // if (storageStatus != PermissionStatus.granted) {
    //   return;
    // }
    String? userId = Auth.user?.uid;
    late Message messageToSend;
    late String fileToSend;

    // Check if user has premium access - if not, send unencrypted
    final bool hasPremium = Auth.getUser?.activated == true;
    if (!hasPremium) {
      messageToSend = Message(
        authorId: userId!,
        messageType: MessageTypes.audio,
        playbackDurationMicroSeconds: recordingMicroSeconds.toString(),
        createdAtMSE: DateTime.now().millisecondsSinceEpoch,
        chatUid: widget.chat.uid,
        withBaseKey: false,
      );
      fileToSend = base64.encode(recordingData!);
    } else if (fullKey != null && fullKey!.isNotEmpty) {
      final encrypted = await encodeRecording(fullKey!, recordingData!);

      final ecnryptedMicroSeconds =
          await encodePayload(recordingMicroSeconds, fullKey!, true);

      if (encrypted != null && ecnryptedMicroSeconds != null) {
        messageToSend = Message(
          authorId: userId!,
          messageType: MessageTypes.audio,
          iv: encrypted.iv,
          mac: encrypted.mac,
          isEncrypted: true,
          playbackDurationMicroSeconds: ecnryptedMicroSeconds['crypted'],
          durationIV: ecnryptedMicroSeconds['iv'],
          durationMAC: ecnryptedMicroSeconds['mac'],
          createdAtMSE: DateTime.now().millisecondsSinceEpoch,
          chatUid: widget.chat.uid,
          withBaseKey: withBaseKey,
        );
        fileToSend = encrypted.cryptedRecording;
      }
    } else {
      // No encryption key available - queue audio message regardless of chat type
      final chat = obx.chats.get(int.parse(widget.chat.uid));
      if (widget.baseKey == null && chat != null) {
        // Queue audio message until key is available
        await _queueMessageUntilKeyExchange(
          chat.uid,
          messageType: MessageTypes.audio,
          fileData: recordingData!,
          duration: recordingMicroSeconds!,
        );

        setState(() {
          sendingFile = false;
          dropRecording();
        });

        // Show user feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(chat.isOneToOne
                  ? 'Audio message queued - waiting for secure connection'
                  : 'Audio message queued - waiting for group encryption key'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      } else {
        // Send unencrypted (fallback case)
        messageToSend = Message(
          authorId: userId!,
          messageType: MessageTypes.audio,
          playbackDurationMicroSeconds: recordingMicroSeconds.toString(),
          createdAtMSE: DateTime.now().millisecondsSinceEpoch,
          chatUid: widget.chat.uid,
          withBaseKey: withBaseKey,
        );
        fileToSend = base64.encode(utf8.encode(recordingData.toString()));
      }
    }
    setState(() {
      sendingFile = true;
    });
    _messageService
        .sendFile(message: messageToSend, file: fileToSend)
        .then((msg) {
      setState(() {
        sendingFile = false;
        dropRecording();
      });
    }).onError((e, s) {
      setState(() {
        sendingFile = false;
        dropRecording();
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not send file',
              style: TextStyle(color: Colors.white)),
          backgroundColor: errorColor,
        ));
      }
    });
  }

  dropRecording() {
    setState(() {
      sendingFile = false;
      recordingData = null;
      recordingMicroSeconds = null;
      recordingDecibels = [];
      isRecording = false;
    });
    widget.onRecordingStateChange?.call(false, const <double>[]);
  }

  _selectFile(BuildContext context) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      final PlatformFile selectedFile = result.files.single;
      if (selectedFile.size > (50 * 1000 * 1000)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('File size should be less than 50MB',
                style: TextStyle(color: Colors.white)),
            dismissDirection: DismissDirection.horizontal,
            showCloseIcon: true,
            backgroundColor: errorColor,
          ));
        }
      } else {
        setState(() {
          file = selectedFile;
        });
      }
    }
  }

  sendFile(context) async {
    if (file == null || file!.bytes == null || file!.bytes!.isEmpty) {
      return;
    }

    String? userId = Auth.user?.uid;
    late Message messageToSend;
    late String fileToSend;

    // Check if user has premium access - if not, send unencrypted
    final bool hasPremium = Auth.getUser?.activated == true;
    if (!hasPremium) {
      messageToSend = Message(
        authorId: userId!,
        messageType: MessageTypes.file,
        text: file!.name,
        createdAtMSE: DateTime.now().millisecondsSinceEpoch,
        chatUid: widget.chat.uid,
        withBaseKey: false,
      );
      fileToSend = base64.encode(file!.bytes!);
    } else if (fullKey != null && fullKey!.isNotEmpty) {
      final ecnrypted = await encodePayload({
        'name': file!.name,
        'bytes': file!.bytes,
      }, fullKey!, true);
      messageToSend = Message(
        authorId: userId!,
        messageType: MessageTypes.file,
        iv: ecnrypted['iv'],
        mac: ecnrypted['mac'],
        isEncrypted: true,
        createdAtMSE: DateTime.now().millisecondsSinceEpoch,
        chatUid: widget.chat.uid,
        withBaseKey: withBaseKey,
      );
      fileToSend = ecnrypted['crypted'];
    } else {
      if (widget.baseKey == null) {
        // Queue file message until key is available
        await _queueMessageUntilKeyExchange(
          widget.chat.uid,
          messageType: MessageTypes.file,
          fileData: file!.bytes!,
          fileName: file!.name,
        );

        setState(() {
          sendingFile = false;
          file = null;
        });

        // Show user feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.chat.isOneToOne
                  ? 'File queued - waiting for secure connection'
                  : 'File queued - waiting for group encryption key'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      } else {
        // Send unencrypted (fallback case)
        messageToSend = Message(
          authorId: userId!,
          messageType: MessageTypes.file,
          text: file!.name,
          createdAtMSE: DateTime.now().millisecondsSinceEpoch,
          chatUid: widget.chat.uid,
          withBaseKey: withBaseKey,
        );
        fileToSend = base64.encode(utf8.encode(file!.bytes.toString()));
      }
    }
    setState(() {
      sendingFile = true;
    });
    _messageService
        .sendFile(message: messageToSend, file: fileToSend)
        .then((msg) {
      setState(() {
        sendingFile = false;
        file = null;
      });
    }).onError((e, s) {
      setState(() {
        sendingFile = false;
        file = null;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not send file',
              style: TextStyle(color: Colors.white)),
          backgroundColor: errorColor,
        ));
      }
    });
  }

  sendImage(Uint8List jpgBytes, BuildContext context) async {
    if (jpgBytes.isEmpty) {
      return;
    }
    if (sendingFile) {
      return;
    }

    String? userId = Auth.user?.uid;
    late Message messageToSend;
    late String fileToSend;

    // Check if user has premium access - if not, send unencrypted
    final bool hasPremium = Auth.getUser?.activated == true;
    if (!hasPremium) {
      messageToSend = Message(
        authorId: userId!,
        messageType: MessageTypes.image,
        text: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        createdAtMSE: DateTime.now().millisecondsSinceEpoch,
        chatUid: widget.chat.uid,
        withBaseKey: false,
      );
      fileToSend = base64.encode(jpgBytes);
    } else if (fullKey != null && fullKey!.isNotEmpty) {
      final encrypted = await encodePayload({
        'name':
            'image_${widget.chat.uid}_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        'bytes': jpgBytes,
      }, fullKey!, true);

      messageToSend = Message(
        authorId: userId!,
        messageType: MessageTypes.image,
        iv: encrypted['iv'],
        mac: encrypted['mac'],
        isEncrypted: true,
        createdAtMSE: DateTime.now().millisecondsSinceEpoch,
        chatUid: widget.chat.uid,
        withBaseKey: withBaseKey,
      );
      fileToSend = encrypted['crypted'];
    } else {
      // No encryption key available - queue image message regardless of chat type
      final chat = obx.chats.get(int.parse(widget.chat.uid));
      if (widget.baseKey == null && chat != null) {
        // Queue image message until key is available
        await _queueMessageUntilKeyExchange(
          chat.uid,
          messageType: MessageTypes.image,
          fileData: jpgBytes,
          fileName:
              'image_${widget.chat.uid}_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        setState(() {
          sendingFile = false;
        });

        // Show user feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(chat.isOneToOne
                  ? 'Image queued - waiting for secure connection'
                  : 'Image queued - waiting for group encryption key'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      } else {
        // Send unencrypted (fallback case)
        messageToSend = Message(
          authorId: userId!,
          messageType: MessageTypes.image,
          text: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          createdAtMSE: DateTime.now().millisecondsSinceEpoch,
          chatUid: widget.chat.uid,
          withBaseKey: withBaseKey,
        );
        fileToSend = base64.encode(jpgBytes);
      }
    }

    setState(() {
      sendingFile = true;
    });

    _messageService
        .sendFile(message: messageToSend, file: fileToSend)
        .then((msg) {
      setState(() {
        sendingFile = false;
      });
    }).onError((e, s) {
      setState(() {
        sendingFile = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not send image',
              style: TextStyle(color: Colors.white)),
          backgroundColor: errorColor,
        ));
      }
    });
  }

  @override
  void dispose() {
    _messageField.dispose();
    // AudioWaveformBars now manages its own player
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            const SizedBox(width: defaultPadding / 2),
            if (sendingFile)
              FadeIcon(
                  position: Position(top: 4, left: 5),
                  icon: const Icon(
                    Icons.upload,
                    color: primaryColor,
                    size: 28,
                  ))
            else if (file != null)
              const Icon(Icons.attach_file, color: primaryColor)
            else if (file == null)
              VoiceRecorderButton(
                pass: fullKey,
                chatId: widget.chat.uid,
                onRecord: onRecording,
                onDecibelChange: onDecibelChange,
                onRecordingStateChange: _handleRecordingToggle,
              ),
            const SizedBox(width: defaultPadding / 4),
            recordingData != null
                ? Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: defaultPadding / 2),
                        padding:
                            const EdgeInsets.only(right: defaultPadding / 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: primaryColor.withAlpha((0.1 * 255).round()),
                        ),
                        width: MediaQuery.of(context).size.width - 115,
                        height: 50,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: AudioWaveformBars(
                                    decibels: recordingDecibels,
                                    width: constraints.maxWidth - 30, // Account for cancel icon
                                    height: 50,
                                    color: primaryColor,
                                    audioData: recordingData,
                                    durationMicroSeconds: recordingMicroSeconds,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    dropRecording();
                                  },
                                  child: Icon(Icons.cancel, color: errorColor),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          sendAudio(context);
                        },
                        icon: const Icon(
                          Icons.send,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  )
                : Expanded(
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            widget.onDelete();
                          },
                          onLongPress: () {},
                          child: Ink(
                            child: const Icon(
                              Icons.delete,
                              color: errorColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: defaultPadding / 4),
                        if (file == null)
                          Expanded(
                            child: EvercryptedTextField(
                              controller: _messageField,
                              hintText: "Type message",
                              suffixIcon: SizedBox(
                                width: 96,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const CameraWidget()))
                                            .then((jpgBytes) {
                                          if (jpgBytes != null) {
                                            if (context.mounted) {
                                              sendImage(jpgBytes, context);
                                            }
                                          }
                                        });
                                      },
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: file != null
                                            ? primaryColor
                                            : Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .color!
                                                .withAlpha(
                                                    (0.64 * 255).round()),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _selectFile(context),
                                      child: Icon(
                                        Icons.attach_file,
                                        color: file != null
                                            ? primaryColor
                                            : Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .color!
                                                .withAlpha(
                                                    (0.64 * 255).round()),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        sendMessage(_messageField.text);
                                      },
                                      onLongPress: () {},
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                            right: defaultPadding / 2),
                                        child: const Icon(Icons.send,
                                            color: primaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  sendMessage(value);
                                }
                              },
                            ),
                          )
                        else ...[
                          Expanded(
                            child: Expanded(
                              child: Row(
                                children: [
                                  const SizedBox(width: defaultPadding / 2),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color: primaryColor
                                              .withAlpha((0.1 * 255).round())),
                                      padding: const EdgeInsets.only(
                                          top: defaultPadding / 4,
                                          bottom: defaultPadding / 4,
                                          left: defaultPadding),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  file!.name,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      file = null;
                                                    });
                                                  },
                                                  icon: const Icon(
                                                    Icons.cancel,
                                                    color: errorColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              sendFile(context);
                                            },
                                            icon: const Icon(
                                              Icons.send,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: defaultPadding / 2),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
