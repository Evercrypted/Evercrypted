import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../ui_constants.dart';

class VoiceRecorderButton extends StatefulWidget {
  const VoiceRecorderButton(
      {super.key, this.pass, required this.chatId, required this.onRecord});
  final String? pass;
  final String chatId;
  final Function onRecord;

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

  String? iv;
  String? mac;
  StreamSubscription<Uint8List>? _mRecordingDataSubscription;
  StreamSubscription? _recorderProgressSub;
  StreamController<Uint8List>? recordingDataController;
  BytesBuilder recordingData = BytesBuilder();
  int? recordingMicroSeconds;
  bool showPreviewButton = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
        vsync: this, duration: Duration(seconds: voiceMessageDurationSeconds));

    controller.addListener(setProgressToControllerValue);
    controller.addStatusListener(setStatus);
  }

  setProgressToControllerValue() {
    setState(() {
      progress = controller.value;
    });
  }

  setStatus(status) {
    setState(() {
      if (status == AnimationStatus.forward) {
        recording = true;
      } else {
        recording = false;
      }
    });
  }

  @override
  void dispose() async {
    if (_myRecorder != null) {
      _myRecorder!.closeRecorder();
      _myRecorder = null;
    }
    _mRecordingDataSubscription?.cancel();
    _recorderProgressSub?.cancel();
    recordingDataController?.close();
    controller.removeListener(setProgressToControllerValue);
    controller.removeStatusListener(setStatus);
    controller.dispose();
    super.dispose();
  }

  Future<void> _openRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _myRecorder!.openRecorder();

    _recorderProgressSub = _myRecorder!.onProgress!.listen((e) {
      recordingMicroSeconds = e.duration.inMicroseconds;
    });

    await _myRecorder!
        .setSubscriptionDuration(const Duration(milliseconds: 100)); // 100ms
  }

  Future<void> record() async {
    await _openRecorder();
    recordingData.clear();
    recordingDataController = StreamController<Uint8List>();
    _mRecordingDataSubscription =
        recordingDataController?.stream.listen((data) {
      recordingData.add(data);
    }, onDone: () {
      _mRecordingDataSubscription?.cancel();
    }, onError: (error) {
      _mRecordingDataSubscription?.cancel();
    });
    await _myRecorder?.startRecorder(
      toStream: recordingDataController!.sink,
      codec: Codec.pcmFloat32,
      audioSource: AudioSource.defaultSource,
    );
  }

  Future<void> stopRecorder() async {
    await _myRecorder?.stopRecorder();
    await _myRecorder?.closeRecorder();

    await _mRecordingDataSubscription?.cancel();
    _mRecordingDataSubscription = null;

    recordingDataController?.close();
    recordingDataController = null;

    if (recordingData.isNotEmpty && recordingMicroSeconds != null) {
      widget.onRecord(recordingData.toBytes(), recordingMicroSeconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) async {
        controller.forward().then((value) {
          controller.reset();
        });
        record();
      },
      onTapUp: (_) async {
        Future.delayed(Duration(milliseconds: 200)).then((value) {
          stopRecorder();
        });
        controller.reset();
      },
      onTapCancel: () async {
        Future.delayed(Duration(milliseconds: 200)).then((value) {
          stopRecorder();
        });
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
        ],
      ),
    );
  }
}
