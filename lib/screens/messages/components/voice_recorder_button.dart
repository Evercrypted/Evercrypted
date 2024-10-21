import 'dart:async';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
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

  int? recordStartTime;
  bool fileWritten = false;
  String? iv;
  String? mac;
  StreamSubscription<Uint8List>? _mRecordingDataSubscription;
  StreamController<Uint8List>? recordingDataController;
  List<Uint8List> recordingData = [];
  int? recordingMicroSeconds;
  bool showPreviewButton = false;

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
  void dispose() async {
    if (_myRecorder != null) {
      _myRecorder!.closeRecorder();
      _myRecorder = null;
    }
    _mRecordingDataSubscription?.cancel();
    recordingDataController?.close();
    controller.dispose();
    super.dispose();
  }

  Future<void> _openRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _myRecorder!.openRecorder();

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }

  Future<void> record() async {
    await _openRecorder();
    recordingData = [];
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
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
    );
    recordStartTime = DateTime.now().microsecondsSinceEpoch;
  }

  Future<void> stopRecorder() async {
    await _myRecorder?.stopRecorder();
    await _myRecorder?.closeRecorder();

    recordingDataController?.close();
    recordingDataController = null;
    final recordEndTime = DateTime.now().microsecondsSinceEpoch;
    recordingMicroSeconds = recordEndTime - recordStartTime!;

    if (recordingData.isNotEmpty && recordingMicroSeconds != null) {
      widget.onRecord(recordingData, recordingMicroSeconds);
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
        stopRecorder();
        controller.reset();
      },
      onTapCancel: () async {
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
        ],
      ),
    );
  }
}
