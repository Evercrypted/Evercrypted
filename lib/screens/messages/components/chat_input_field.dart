import 'dart:convert';
import 'dart:typed_data';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/cryptography/voice_message.dart';
import 'package:evercrypted/core/entities/message/message_isar.dart';
import 'package:evercrypted/widgets/fade_icon.dart';
import 'package:evercrypted/widgets/secret_keyboard/secret_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:siri_wave/siri_wave.dart';

import '../../../core/entities/message/message_service.dart';
import '../../../ui_constants.dart';
import 'voice_recorder_button.dart';
import 'message_attachment.dart';

class ChatInputField extends StatefulWidget {
  final String chatId;
  final String? pass;
  final String? baseKey;
  final FlutterSoundPlayer player;
  const ChatInputField(
      {super.key,
      required this.chatId,
      required this.player,
      this.pass,
      this.baseKey});

  @override
  ChatInputFieldState createState() => ChatInputFieldState();
}

class ChatInputFieldState extends State<ChatInputField> {
  bool _showAttachment = false;
  final TextEditingController _messageField = TextEditingController();
  final MessageService _messageService = MessageService();
  String? fullKey;
  int? recordingMicroSeconds;
  List<Uint8List>? recordingData;
  bool recordingPlaying = false;
  bool sendingFile = false;

  IOS7SiriWaveformController waveFromController = IOS7SiriWaveformController(
    amplitude: 0,
    color: primaryColor,
    frequency: 15,
    speed: 0.15,
  );

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
    if (widget.baseKey != null) {
      if (widget.pass != null) {
        fullKey = widget.baseKey!.substring(0, 32 - widget.pass!.length) +
            widget.pass!;
      } else {
        fullKey = widget.baseKey!;
      }
    } else {
      if (widget.pass != null) {
        if (widget.pass!.length < 32) {
          fullKey = widget.pass! + '0' * (32 - widget.pass!.length);
        } else {
          fullKey = widget.pass!;
        }
      } else {
        fullKey = null;
      }
    }
  }

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

    if (fullKey != null) {
      encr = await encodePayload(message, fullKey, true);
    }
    _messageService.sendMessage(encr, widget.chatId);
    _messageField.clear();
  }

  onRecording(List<Uint8List> recordingData, int recordingMicroSeconds) {
    setState(() {
      this.recordingData = recordingData;
      this.recordingMicroSeconds = recordingMicroSeconds;
    });
  }

  playRecording() async {
    if (recordingData == null ||
        recordingData!.isEmpty ||
        recordingMicroSeconds == null) {
      return;
    }
    await widget.player.openPlayer();
    await widget.player.startPlayerFromStream(
        codec: Codec.pcm16, numChannels: 1, sampleRate: 16000);

    Future.delayed(Duration(microseconds: recordingMicroSeconds!))
        .then((dur) async {
      await widget.player.stopPlayer();
      await widget.player.closePlayer();
      setState(() {
        recordingPlaying = false;
        waveFromController = IOS7SiriWaveformController(
          amplitude: 0,
          color: primaryColor,
          frequency: 15,
          speed: 0.15,
        );
      });
    });
    for (final Uint8List data in recordingData!) {
      await widget.player.feedFromStream(data);
    }
  }

  sendFile() async {
    if (recordingData == null ||
        recordingData!.isEmpty ||
        recordingMicroSeconds == null) {
      return;
    }
    String? userId = Auth.user?.uid;
    late Message messageToSend;
    late String fileToSend;
    if (fullKey != null && fullKey!.isNotEmpty) {
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
          chatUid: widget.chatId,
        );
        fileToSend = encrypted.cryptedRecording;
      }
    } else {
      messageToSend = Message(
        authorId: userId!,
        messageType: MessageTypes.audio,
        playbackDurationMicroSeconds: recordingMicroSeconds.toString(),
        createdAtMSE: DateTime.now().millisecondsSinceEpoch,
        chatUid: widget.chatId,
      );
      fileToSend = base64.encode(utf8.encode(recordingData.toString()));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Could not send file', style: TextStyle(color: Colors.white)),
        backgroundColor: errorColor,
      ));
    });
  }

  dropRecording() {
    setState(() {
      recordingData = null;
      recordingMicroSeconds = null;
      recordingPlaying = false;
      waveFromController = IOS7SiriWaveformController(
        amplitude: 0,
        color: primaryColor,
        frequency: 15,
        speed: 0.15,
      );
    });
  }

  @override
  void dispose() {
    _messageField.dispose();
    widget.player.closePlayer();
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
                if (sendingFile)
                  const FadeIcon(
                      icon: Icon(
                    Icons.upload,
                    color: primaryColor,
                    size: 30,
                  ))
                else
                  VoiceRecorderButton(
                    pass: fullKey,
                    chatId: widget.chatId,
                    onRecord: onRecording,
                  ),
                const SizedBox(width: defaultPadding / 4),
                recordingData != null
                    ? Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: defaultPadding / 2),
                            padding: const EdgeInsets.only(
                                right: defaultPadding / 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: primaryColor.withOpacity(0.1),
                            ),
                            width: MediaQuery.of(context).size.width - 115,
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      recordingPlaying = !recordingPlaying;
                                      if (recordingPlaying) {
                                        waveFromController =
                                            IOS7SiriWaveformController(
                                          amplitude: 0.7,
                                          color: primaryColor,
                                          frequency: 15,
                                          speed: 0.15,
                                        );
                                        playRecording();
                                      } else {
                                        waveFromController =
                                            IOS7SiriWaveformController(
                                          amplitude: 0,
                                          color: primaryColor,
                                          frequency: 15,
                                          speed: 0.15,
                                        );
                                        widget.player.stopPlayer();
                                        widget.player.closePlayer();
                                      }
                                    });
                                  },
                                  child: recordingPlaying
                                      ? const Icon(
                                          Icons.stop,
                                          color: primaryColor,
                                          size: 36,
                                        )
                                      : const Icon(
                                          Icons.play_arrow,
                                          color: primaryColor,
                                          size: 36,
                                        ),
                                ),
                                SiriWaveform.ios7(
                                  controller: waveFromController,
                                  options: IOS7SiriWaveformOptions(
                                    height: 50,
                                    width:
                                        MediaQuery.of(context).size.width - 210,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    dropRecording();
                                  },
                                  child: Icon(Icons.cancel,
                                      color: Colors.red[400]),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              sendFile();
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
                if (_showAttachment) const MessageAttachment(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
