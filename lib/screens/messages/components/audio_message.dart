import 'dart:convert';
import 'dart:typed_data';

import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/cryptography/voice_message.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/widgets/fade_icon.dart';
import 'package:flutter/material.dart';

import '../../../ui_constants.dart';
import '../../../models/chat_message.dart';
import 'audio_waveform_bars.dart';

class AudioMessage extends StatefulWidget {
  final ChatMessage message;

  const AudioMessage({super.key, required this.message});

  @override
  State<AudioMessage> createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  String? fileString;
  bool needDownload = false;
  bool downloadInProgress = false;
  Uint8List? audioData;
  List<double> decibels = [];

  MessageService messageService = MessageService();

  @override
  void initState() {
    super.initState();
    setFile();
  }

  @override
  void didUpdateWidget(AudioMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.uid != widget.message.uid) {
      setFile();
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

    // Extract metadata (duration, decibels) and audio data for playback
    if (fileString != null) {
      await _extractMetadataAndAudio();
    }
  }

  Future<void> _extractMetadataAndAudio() async {
    try {
      Map<String, dynamic>? decodedPayload;

      if (widget.message.pass != null && widget.message.iv != null) {
        // Encrypted: decrypt to get metadata and audio
        decodedPayload = await decodePayload(
          fileString!,
          widget.message.iv!,
          widget.message.pass!,
          true,
        );
      } else {
        // Not encrypted: parse JSON
        try {
          final decodedBytes = base64.decode(fileString!);
          final jsonString = utf8.decode(decodedBytes);
          decodedPayload = json.decode(jsonString);
        } catch (e) {
          // Old format without metadata - ignore
        }
      }

      if (decodedPayload != null) {
        final parsed = parseRecordingPayload(decodedPayload);

        setState(() {
          // Extract duration
          if (decodedPayload!['duration'] != null &&
              widget.message.decodedDuration == null) {
            widget.message.decodedDuration = decodedPayload['duration'];
          }

          // Extract decibels
          if (parsed['decibels'] != null) {
            decibels = List<double>.from(parsed['decibels']);
          }

          // Extract audio data
          audioData = parsed['recording'];
        });
      }
    } catch (e) {
      // Metadata extraction failed - will show basic waveform
      debugPrint('Failed to extract audio metadata: $e');
    }
  }

  downloadFile(context) {
    setState(() {
      downloadInProgress = true;
    });
    if (widget.message.uid == null) {
      return;
    }
    messageService
        .downloadFile(widget.message.chatUid, widget.message.uid!,
            widget.message.fileKey!)
        .then((resp) {
      fileString = resp;
      setState(() {
        downloadInProgress = false;
        needDownload = false;
      });
      // Extract metadata after download
      _extractMetadataAndAudio();
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
    // Use default decibels if none extracted
    final displayDecibels = decibels.isNotEmpty
        ? decibels
        : List.generate(40, (index) => 0.5 + (index % 3) * 0.15);

    return Container(
      width: MediaQuery.of(context).size.width * 0.55,
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding * 0.75,
        vertical: defaultPadding / 2.5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: primaryColor
            .withAlpha((255 * (widget.message.isSender ? 1 : 0.05)).round()),
      ),
      child: needDownload
          ? Row(
              children: [
                if (downloadInProgress)
                  FadeIcon(
                    position: Position(top: 7.5, left: 7.2),
                    icon: Icon(
                      Icons.download,
                      color:
                          widget.message.isSender ? Colors.white : primaryColor,
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
                      color:
                          widget.message.isSender ? Colors.white : primaryColor,
                      size: 30,
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    downloadInProgress
                        ? "Downloading audio message..."
                        : "Audio message - Click to download",
                    style: TextStyle(
                      color:
                          widget.message.isSender ? Colors.white : primaryColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: AudioWaveformBars(
                    decibels: displayDecibels,
                    width: MediaQuery.of(context).size.width * 0.55 * 0.8,
                    height: 40,
                    color:
                        widget.message.isSender ? Colors.white : primaryColor,
                    audioData: audioData,
                    durationMicroSeconds: widget.message.decodedDuration,
                  ),
                ),
              ],
            ),
    );
  }
}
