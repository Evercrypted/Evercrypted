import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue_model.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/core/obx_init.dart';
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
import 'package:evercrypted/services/profanity_filter_service.dart';
import 'audio_waveform_bars.dart';
import 'voice_recorder_button.dart';

class ChatInputField extends ConsumerStatefulWidget {
  final Chat chat;
  final String? pass;
  final String? baseKey;
  final FlutterSoundPlayer player;
  final Widget? passwordDialogWidget;
  const ChatInputField({
    super.key,
    required this.chat,
    required this.player,
    this.pass,
    this.baseKey,
    this.passwordDialogWidget,
  });

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
  bool sendingMessage = false;
  PlatformFile? file;
  bool withBaseKey = false;
  List<double> recordingDecibels = [];
  bool isRecording = false;
  int? liveRecordingMicroseconds;
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
    if (sendingMessage) {
      return;
    }

    // Check profanity filter
    final profanityService = ref.read(profanityFilterServiceProvider);
    final isFilterEnabled = await profanityService.isEnabled();
    if (isFilterEnabled) {
      final detectedWord = profanityService.containsProfanity(message);
      if (detectedWord != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Message contains inappropriate content and cannot be sent.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: errorColor,
              dismissDirection: DismissDirection.horizontal,
              showCloseIcon: true,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      sendingMessage = true;
    });

    try {
      // Check if user has premium access - if not, send unencrypted
      final bool hasPremium = Auth.getUser?.activated == true;
      debugPrint(
          'userLog: sendMessage called for chat ${widget.chat.uid}. hasPremium: $hasPremium, fullKey: ${fullKey != null ? "present" : "null"}, baseKey: ${widget.baseKey != null ? "present" : "null"}, pass: ${widget.pass != null ? "present" : "null"}. User: ${Auth.user?.uid}');

      if (!hasPremium) {
        debugPrint(
            'userLog: Sending unencrypted message (non-premium user) for chat ${widget.chat.uid}. User: ${Auth.user?.uid}');
        await _messageService.sendMessage(message, widget.chat.uid, false);
        _messageField.clear();
        return;
      }

      // Check if we have a key for encryption
      if (fullKey != null) {
        // We have the key - encrypt and send normally
        debugPrint(
            'userLog: Sending encrypted message with fullKey for chat ${widget.chat.uid}. User: ${Auth.user?.uid}');
        dynamic encr = message;
        try {
          encr = await encodePayload(message, fullKey, true);
        } catch (e) {
          rethrow;
        }
        await _messageService.sendMessage(encr, widget.chat.uid, withBaseKey);
        _messageField.clear();
      } else {
        // No encryption key available - queue message regardless of chat type
        debugPrint(
            'userLog: No fullKey available for chat ${widget.chat.uid}. Checking if should queue... User: ${Auth.user?.uid}');
        if (widget.baseKey == null) {
          debugPrint(
              'userLog: baseKey is null, queueing message for chat ${widget.chat.uid}. User: ${Auth.user?.uid}');
          // Queue message until key is available (works for both one-to-one and group chats)
          await _queueMessageUntilKeyExchange(
            widget.chat.uid,
            text: message,
            messageType: MessageTypes.text,
          );
          _messageField.clear();
        } else {
          // Send normally (fallback case)
          debugPrint(
              'userLog: baseKey is present but fullKey is null - sending unencrypted (fallback) for chat ${widget.chat.uid}. User: ${Auth.user?.uid}');
          await _messageService.sendMessage(
              message, widget.chat.uid, withBaseKey);
          _messageField.clear();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          sendingMessage = false;
        });
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
    final actionId = ObxInit.obx.actionQueues.put(action);
    debugPrint(
        'userLog: Queued $messageType message (actionId: $actionId) for chat $chatUid until key exchange completes. User: ${Auth.user?.uid}');

    // For audio/file/image messages, save the file locally for immediate display
    String? filepath;
    bool isEncrypted =
        false; // Start as unencrypted, will be encrypted when sent

    if (messageType == MessageTypes.audio &&
        fileData != null &&
        duration != null) {
      // Create the recording payload and save it locally (unencrypted for now)
      final payload =
          createRecordingPayload(fileData, duration, waveData ?? []);
      final jsonString = json.encode(payload);
      final fileToSave = base64.encode(utf8.encode(jsonString));

      // Save file with queueId for temporary storage
      filepath = await _messageService.saveFile(
        file: fileToSave,
        queueId: actionId,
      );
    }

    // Create optimistic UI message entry to show the queued message
    final optimisticMessage = Message(
      authorId: Auth.user!.uid,
      text: text ?? fileName,
      messageType: messageType ?? MessageTypes.text,
      createdAtMSE: DateTime.now().millisecondsSinceEpoch,
      chatUid: chatUid,
      queueId: actionId,
      successfullySent: false, // Mark as not sent yet
      uniqueId: '${DateTime.now().millisecondsSinceEpoch}$chatUid$actionId',
      withBaseKey: true, // Will be encrypted when key arrives
      isEncrypted:
          isEncrypted, // False for now, will be true when encrypted and sent
      filepath: filepath, // For audio/file/image messages to be accessible
    );

    // Save to ObjectBox for immediate UI display
    await _messageService.writeNewMessageToObx(optimisticMessage);
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
  }

  void _handleRecordingToggle(bool recording) {
    if (isRecording == recording) {
      return;
    }

    setState(() {
      isRecording = recording;
      if (recording) {
        recordingDecibels = [];
        liveRecordingMicroseconds = 0;
      } else {
        liveRecordingMicroseconds = null;
      }
    });
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

    // Create combined payload with recording, duration, and decibels
    final payload = createRecordingPayload(
      recordingData!,
      recordingMicroSeconds!,
      recordingDecibels,
    );

    if (!hasPremium) {
      // Non-premium: Send as base64-encoded JSON (same format as encrypted['crypted'])
      final jsonString = json.encode(payload);
      fileToSend = base64.encode(utf8.encode(jsonString));

      messageToSend = Message(
        authorId: userId!,
        messageType: MessageTypes.audio,
        createdAtMSE: DateTime.now().millisecondsSinceEpoch,
        chatUid: widget.chat.uid,
        withBaseKey: false,
      );
    } else if (fullKey != null && fullKey!.isNotEmpty) {
      // Premium: Encrypt the combined payload using encodePayload
      // This does: JSON -> UTF-8 -> Encrypt -> Base64
      final encrypted = await encodePayload(payload, fullKey!, true);

      if (encrypted != null) {
        messageToSend = Message(
          authorId: userId!,
          messageType: MessageTypes.audio,
          iv: encrypted['iv'],
          isEncrypted: true,
          createdAtMSE: DateTime.now().millisecondsSinceEpoch,
          chatUid: widget.chat.uid,
          withBaseKey: withBaseKey,
        );
        fileToSend = encrypted['crypted'];
      }
    } else {
      // No encryption key available - queue audio message regardless of chat type
      if (widget.baseKey == null) {
        debugPrint(
            'userLog: Queueing audio message for chat ${widget.chat.uid}. User: ${Auth.user?.uid}');
        // Queue audio message until key is available
        await _queueMessageUntilKeyExchange(
          widget.chat.uid,
          messageType: MessageTypes.audio,
          fileData: recordingData!,
          duration: recordingMicroSeconds!,
          waveData: recordingDecibels,
        );

        setState(() {
          sendingFile = false;
          dropRecording();
        });
        return;
      } else {
        // Send unencrypted (fallback case)
        debugPrint(
            'userLog: Sending unencrypted audio (fallback) for chat ${widget.chat.uid}. User: ${Auth.user?.uid}');
        // Create payload and encode it
        final fallbackPayload = createRecordingPayload(
          recordingData!,
          recordingMicroSeconds!,
          recordingDecibels,
        );
        final jsonString = json.encode(fallbackPayload);
        fileToSend = base64.encode(utf8.encode(jsonString));

        messageToSend = Message(
          authorId: userId!,
          messageType: MessageTypes.audio,
          createdAtMSE: DateTime.now().millisecondsSinceEpoch,
          chatUid: widget.chat.uid,
          withBaseKey: withBaseKey,
        );
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
      final chat = ObxInit.obx.chats.get(int.parse(widget.chat.uid));
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
            if (widget.passwordDialogWidget != null)
              widget.passwordDialogWidget!,
            if (sendingFile)
              Container(
                margin: const EdgeInsets.only(left: defaultPadding / 2),
                child: FadeIcon(
                    position: Position(top: 4, left: 5),
                    icon: const Icon(
                      Icons.upload,
                      color: primaryColor,
                      size: 28,
                    )),
              )
            else if (file != null)
              Container(
                  margin: const EdgeInsets.only(left: defaultPadding / 2),
                  child: const Icon(Icons.attach_file, color: primaryColor))
            else if (file == null)
              VoiceRecorderButton(
                pass: fullKey,
                chatId: widget.chat.uid,
                onRecord: onRecording,
                onDecibelChange: onDecibelChange,
                onRecordingStateChange: _handleRecordingToggle,
                onDurationChange: (microseconds) {
                  setState(() {
                    liveRecordingMicroseconds = microseconds;
                  });
                },
              ),
            const SizedBox(width: defaultPadding / 4),
            // Show waveform during active recording
            isRecording && recordingData == null
                ? Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: defaultPadding / 2),
                      padding: const EdgeInsets.only(right: defaultPadding / 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: primaryColor.withAlpha((0.1 * 255).round()),
                      ),
                      height: 50,
                      child: AudioWaveformBars(
                        decibels: recordingDecibels,
                        width: MediaQuery.of(context).size.width - 100,
                        height: 50,
                        color: primaryColor,
                        audioData: null,
                        durationMicroSeconds: liveRecordingMicroseconds,
                        isRecording: true,
                      ),
                    ),
                  )
                : recordingData != null
                    ? Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: defaultPadding / 2),
                                padding: const EdgeInsets.only(
                                    right: defaultPadding / 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: primaryColor
                                      .withAlpha((0.1 * 255).round()),
                                ),
                                height: 50,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: AudioWaveformBars(
                                            decibels: recordingDecibels,
                                            width: constraints.maxWidth -
                                                30, // Account for cancel icon
                                            height: 50,
                                            color: primaryColor,
                                            audioData: recordingData,
                                            durationMicroSeconds:
                                                recordingMicroSeconds,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            dropRecording();
                                          },
                                          child: Icon(Icons.cancel,
                                              color: errorColor),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: sendingFile
                                  ? Center(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: FadeIcon(
                                          position: Position(top: 6, left: 8),
                                          icon: const Icon(
                                            Icons.send,
                                            color: primaryColor,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      onPressed: () {
                                        sendAudio(context);
                                      },
                                      icon: const Icon(
                                        Icons.send,
                                        color: primaryColor,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      )
                    : Expanded(
                        child: Row(
                          children: [
                            const SizedBox(width: defaultPadding / 4),
                            if (file == null)
                              Expanded(
                                child: EvercryptedTextField(
                                  controller: _messageField,
                                  hintText: "Type message",
                                  onDone: () {
                                    sendMessage(_messageField.text);
                                  },
                                  isMultiLine: true,
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
                                        GestureDetector(
                                          onTap: sendingMessage || sendingFile
                                              ? null
                                              : () {
                                                  sendMessage(
                                                      _messageField.text);
                                                },
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            margin: const EdgeInsets.only(
                                                right: defaultPadding / 2),
                                            child: sendingMessage || sendingFile
                                                ? FadeIcon(
                                                    position: Position(
                                                        top: 6, left: 8),
                                                    icon: const Icon(
                                                      Icons.send,
                                                      color: primaryColor,
                                                      size: 18,
                                                    ),
                                                  )
                                                : const Icon(Icons.send,
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
                                              color: primaryColor.withAlpha(
                                                  (0.1 * 255).round())),
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
                                              SizedBox(
                                                width: 48,
                                                height: 48,
                                                child: sendingFile
                                                    ? Center(
                                                        child: SizedBox(
                                                          width: 30,
                                                          height: 30,
                                                          child: FadeIcon(
                                                            position: Position(
                                                                top: 6,
                                                                left: 8),
                                                            icon: const Icon(
                                                              Icons.send,
                                                              color:
                                                                  primaryColor,
                                                              size: 18,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : IconButton(
                                                        onPressed: () {
                                                          sendFile(context);
                                                        },
                                                        icon: const Icon(
                                                          Icons.send,
                                                          color: primaryColor,
                                                        ),
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
