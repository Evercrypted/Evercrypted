import 'dart:typed_data';

import 'package:evercrypted/core/cryptography/voice_message.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/widgets/fade_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import '../../../ui_constants.dart';
import '../../../models/chat_message.dart';

class AudioMessage extends StatefulWidget {
  final ChatMessage message;
  final FlutterSoundPlayer player;

  const AudioMessage({super.key, required this.message, required this.player});

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage>
    with SingleTickerProviderStateMixin {
  AnimationController? controller;
  int? durationLeft;
  String? fileString;
  bool needDownload = false;
  bool downloadInProgress = false;

  MessageService messageService = MessageService();

  @override
  void initState() {
    super.initState();

    setFile();

    setDurationLeft(0);

    if (widget.message.decodedDuration != null) {
      controller = AnimationController(
          vsync: this,
          duration: Duration(microseconds: widget.message.decodedDuration!));

      controller?.addListener(setDurationToControllerValue);
    }
  }

  setDurationToControllerValue() {
    if (controller != null) {
      setDurationLeft(controller!.value);
    }
  }

  @override
  void dispose() {
    controller?.removeListener(setDurationToControllerValue);
    controller?.dispose();
    controller = null;
    super.dispose();
  }

  @override
  didUpdateWidget(AudioMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    setFile();

    setDurationLeft(0);

    if (widget.message.decodedDuration != null) {
      durationLeft = widget.message.decodedDuration!;
      if (controller != null) {
        controller!.duration =
            Duration(microseconds: widget.message.decodedDuration!);
      } else {
        controller = AnimationController(
            vsync: this,
            duration: Duration(microseconds: widget.message.decodedDuration!));

        controller!.addListener(setDurationToControllerValue);
      }
    }
  }

  setFile() async {
    if (widget.message.queueId != null) {
      fileString =
          await messageService.getMessageFile(queueId: widget.message.queueId);
    } else {
      fileString = await messageService.getMessageFile(
          chatUid: widget.message.chatUid, msgUid: widget.message.uid);
      if (fileString == null) {
        setState(() {
          needDownload = true;
        });
      }
    }
  }

  playFile() async {
    if (fileString == null) {
      return;
    }
    late final List<Uint8List> recording;
    if (widget.message.pass != null &&
        widget.message.iv != null &&
        widget.message.mac != null) {
      recording = await decodeRecording(
          key: widget.message.pass!,
          iv: widget.message.iv!,
          mac: widget.message.mac!,
          cryptedRecording: fileString!);
    } else {
      recording = await decodeRecording(
          cryptedRecording: fileString!, isEncrypted: false);
    }
    await widget.player.openPlayer();
    await widget.player.startPlayerFromStream(
        codec: Codec.pcm16, numChannels: 1, sampleRate: 16000);

    Future.delayed(Duration(microseconds: widget.message.decodedDuration!))
        .then((dur) async {
      await widget.player.stopPlayer();
      await widget.player.closePlayer();
    });
    for (final Uint8List data in recording) {
      await widget.player.feedUint8FromStream(data);
    }
  }

  setDurationLeft(controllerValue) {
    if (widget.message.decodedDuration == null) {
      return;
    }
    setState(() {
      if (controllerValue > 0 && controllerValue < 1) {
        durationLeft =
            (widget.message.decodedDuration! - (controllerValue * durationLeft))
                .round();
      } else {
        durationLeft = widget.message.decodedDuration!;
      }
    });
  }

  play() {
    playFile();
    controller!.reset();
    controller!.forward();
  }

  stop() async {
    await widget.player.stopPlayer();
    await widget.player.closePlayer();
    controller!.stop();
    controller!.reset();
  }

  downloadFile(context) {
    setState(() {
      downloadInProgress = true;
    });
    if (widget.message.uid == null) {
      return;
    }
    messageService
        .downloadFile(widget.message.chatUid, widget.message.uid!)
        .then((resp) {
      fileString = resp;
      setState(() {
        downloadInProgress = false;

        needDownload = false;
      });
    }).catchError((error) {
      setState(() {
        downloadInProgress = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not download file',
              style: TextStyle(color: Colors.white)),
          backgroundColor: errorColor,
          dismissDirection: DismissDirection.horizontal,
          showCloseIcon: true,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.55,
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding * 0.75,
        vertical: defaultPadding / 2.5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: primaryColor
            .withAlpha(255 * (widget.message.isSender ? 1 : 0.1).round()),
      ),
      child: Row(
        children: [
          if (needDownload)
            if (downloadInProgress)
              FadeIcon(
                position: Position(top: 7.5, left: 7.2),
                icon: Icon(
                  Icons.download,
                  color: widget.message.isSender ? Colors.white : primaryColor,
                  size: 24,
                ),
              )
            else
              IconButton(
                onPressed: () {
                  downloadFile(context);
                },
                icon: Icon(
                  Icons.download,
                  color: widget.message.isSender ? Colors.white : primaryColor,
                  size: 30,
                ),
              )
          else
            IconButton(
              onPressed: () {
                if (controller != null) {
                  if (controller!.isAnimating) {
                    stop();
                  } else {
                    play();
                  }
                }
              },
              icon: Icon(
                controller != null && controller!.isAnimating
                    ? Icons.stop
                    : Icons.play_arrow,
                color: widget.message.isSender ? Colors.white : primaryColor,
              ),
            ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: defaultPadding / 2),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (needDownload)
                    Positioned(
                      bottom: 5,
                      child: Text(
                        downloadInProgress ? "Downloading..." : "Download",
                        style: TextStyle(
                            color: widget.message.isSender
                                ? Colors.white
                                : Colors.black54,
                            fontSize: 12),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    height: 2,
                    color: widget.message.isSender
                        ? Colors.white
                        : primaryColor.withOpacity(0.4),
                  ),
                  Positioned(
                    left: controller == null
                        ? 0
                        : controller!.value == 1
                            ? 0
                            : MediaQuery.of(context).size.width *
                                0.55 *
                                0.5 *
                                controller!.value,
                    child: Container(
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(
                        color: widget.message.isSender
                            ? Colors.white
                            : primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          if (durationLeft != null)
            Text(
              "${(Duration(microseconds: durationLeft!).inMilliseconds / 1000).round()}s",
              style: TextStyle(
                  fontSize: 12,
                  color: widget.message.isSender ? Colors.white : null),
            ),
        ],
      ),
    );
  }
}
