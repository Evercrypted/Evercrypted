import 'dart:io';
import 'dart:typed_data';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:evercrypted/core/cryptography/file.dart';
import 'package:evercrypted/core/helpers/get_random_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

import '../../../ui_constants.dart';

class VoiceRecorderButton extends StatefulWidget {
  const VoiceRecorderButton({super.key, this.pass, required this.chatId});
  final String? pass;
  final String chatId;

  @override
  VoiceRecorderButtonState createState() => VoiceRecorderButtonState();
}

class VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  int voiceMessageDurationSeconds = 30;
  bool recording = false;
  double progress = 0;
  FlutterSoundRecorder? _myRecorder = FlutterSoundRecorder();
  FlutterSoundPlayer? _myPlayer = FlutterSoundPlayer();
  RecorderController? waveFormController;
  List<double>? waveData;
  bool wavePlaying = false;
  DateTime? recordStartTime;
  DateTime? recordEndTime;
  String? filePath;
  bool fileWritten = false;
  String? iv;
  String? mac;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
        vsync: this, duration: Duration(seconds: voiceMessageDurationSeconds));

    controller.addListener(() {
      setState(() {
        progress = controller.value;
      });
    });
    controller.addStatusListener((status) {
      setState(() {
        if (status == AnimationStatus.forward) {
          recording = true;
        } else {
          recording = false;
        }
      });
    });
  }

  @override
  void dispose() {
    // closeRecorder();
    // closePlayer();
    controller.dispose();
    super.dispose();
  }

  void closeRecorder() async {
    _myRecorder?.closeRecorder();
    _myRecorder = null;
  }

  void closePlayer() async {
    await _myPlayer?.closePlayer();
    _myPlayer = null;
  }

  Future<void> record() async {
    waveFormController = RecorderController();
    setState(() {
      wavePlaying = true;
    });
    await waveFormController?.record();
    var tempDir = await getTemporaryDirectory();
    filePath =
        '${tempDir.path}/${widget.chatId}-${DateTime.now().millisecondsSinceEpoch}-${getRandomString(16)}.aac';
    await _myRecorder?.startRecorder(
      toFile: filePath,
      codec: Codec.aacADTS,
    );
    recordStartTime = DateTime.now();
  }

  Future<void> stopRecorder() async {
    waveFormController?.stop();
    setState(() {
      wavePlaying = false;
    });
    waveData = waveFormController?.waveData;
    waveFormController?.dispose();
    waveFormController = null;
    final String? url = await _myRecorder?.stopRecorder();
    recordEndTime = DateTime.now();
    final int microSeconds =
        recordEndTime!.difference(recordStartTime!).inMicroseconds;

    if (url != null) {
      closeRecorder();
      if (widget.pass != null &&
          widget.pass!.isNotEmpty == true &&
          filePath != null) {
        final encrypted = await encodeFile(widget.pass!, filePath!);
        if (encrypted != null) {
          await File(filePath!).delete();
        }
        // iv = encrypted.iv;
        // mac = encrypted.mac;
        // var tempDir = await getTemporaryDirectory();
        // await File('${tempDir.path}/crypted')
        //     .writeAsBytes(encrypted.cryptedFile);
        // setState(() {
        //   fileWritten = true;
        // });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) async {
        controller.forward().then((value) {
          controller.reset();
        });
        _myRecorder?.openRecorder();
        await record();
      },
      onTapUp: (_) {
        stopRecorder();
        controller.reset();
      },
      onTapCancel: () {
        stopRecorder();
        controller.reset();
      },
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CircularProgressIndicator(
                value: 1.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade200),
              ),
              CircularProgressIndicator(
                value: progress,
                valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              if (recording)
                Text(
                  (progress * voiceMessageDurationSeconds).round().toString(),
                  style: const TextStyle(
                      color: primaryColor, fontWeight: FontWeight.bold),
                )
              else
                const Icon(Icons.mic, color: primaryColor),
            ],
          ),
          if (wavePlaying)
            AudioWaveforms(
              enableGesture: true,
              size: const Size(50, 50),
              recorderController: waveFormController!,
              waveStyle: const WaveStyle(
                  spacing: 4,
                  waveThickness: 3,
                  waveColor: primaryColor,
                  extendWaveform: true,
                  showMiddleLine: false,
                  scaleFactor: 100),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.only(left: 10),
              margin: const EdgeInsets.only(left: 10),
            ),
          // if (fileWritten)
          //   IconButton(
          //       onPressed: () async {
          //         var tempDir = await getTemporaryDirectory();
          //         final Uint8List file =
          //             File('${tempDir.path}/crypted').readAsBytesSync();
          //         final decrypted =
          //             await decodeFile(widget.pass!, iv!, mac!, file, true);
          //         print(decrypted);
          //         await _myPlayer?.openPlayer();
          //         final Duration? dur = await _myPlayer?.startPlayer(
          //             fromDataBuffer: decrypted, codec: Codec.aacADTS);
          //         if (dur != null) {
          //           Future.delayed(dur, () {
          //             closePlayer();
          //           });
          //         }
          //       },
          //       icon: const Icon(Icons.play_arrow))
        ],
      ),
    );
  }
}
