import 'dart:convert';
import 'dart:typed_data';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/cryptography/voice_message.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/widgets/fade_icon.dart';
import 'package:evercrypted/widgets/secret_keyboard/secret_input.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:siri_wave/siri_wave.dart';

import '../../../core/entities/message/message_service.dart';
import '../../../ui_constants.dart';
import 'voice_recorder_button.dart';

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
  final TextEditingController _messageField = TextEditingController();
  final MessageService _messageService = MessageService();
  String? fullKey;
  int? recordingMicroSeconds;
  List<Uint8List>? recordingData;
  bool recordingPlaying = false;
  bool sendingFile = false;
  PlatformFile? file;

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
    print('fullKey ' + fullKey.toString());
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

  sendAudio(context) async {
    if (recordingData == null ||
        recordingData!.isEmpty ||
        recordingMicroSeconds == null) {
      return;
    }
    if (sendingFile) {
      return;
    }
    final storageStatus = await Permission.storage.request();
    if (storageStatus != PermissionStatus.granted) {
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
    // _messageService
    //     .sendFile(message: messageToSend, file: fileToSend)
    //     .then((msg) {
    //   setState(() {
    //     sendingFile = false;
    //     dropRecording();
    //   });
    // }).onError((e, s) {
    //   setState(() {
    //     sendingFile = false;
    //     dropRecording();
    //   });
    //   if (context.mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    //       content: Text('Could not send file',
    //           style: TextStyle(color: Colors.white)),
    //       backgroundColor: errorColor,
    //     ));
    //   }
    // });
  }

  dropRecording() {
    setState(() {
      sendingFile = false;
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
    if (fullKey != null && fullKey!.isNotEmpty) {
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
        chatUid: widget.chatId,
      );
      fileToSend = ecnrypted['crypted'];
    } else {
      messageToSend = Message(
        authorId: userId!,
        messageType: MessageTypes.file,
        text: file!.name,
        createdAtMSE: DateTime.now().millisecondsSinceEpoch,
        chatUid: widget.chatId,
      );
      fileToSend = base64.encode(utf8.encode(file!.bytes.toString()));
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

  @override
  void dispose() {
    _messageField.dispose();
    widget.player.closePlayer();
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
                        padding:
                            const EdgeInsets.only(right: defaultPadding / 2),
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
                                width: MediaQuery.of(context).size.width - 210,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                dropRecording();
                              },
                              child: Icon(Icons.cancel, color: Colors.red[400]),
                            ),
                          ],
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
                        const SizedBox(width: defaultPadding / 4),
                        if (file == null)
                          Expanded(
                            child: TextField(
                              controller: _messageField,
                              decoration: InputDecoration(
                                hintText: "Type message",
                                suffixIcon: SizedBox(
                                  width: 96,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _selectFile(context),
                                        icon: Icon(
                                          Icons.attach_file,
                                          color: file != null
                                              ? primaryColor
                                              : Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .color!
                                                  .withOpacity(0.64),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          sendMessage(_messageField.text);
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
                                          color: primaryColor.withOpacity(0.1)),
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
                                                    color: Colors.red,
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
