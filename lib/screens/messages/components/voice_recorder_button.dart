import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../ui_constants.dart';

class VoiceRecorderButton extends StatefulWidget {
  const VoiceRecorderButton(
      {super.key,
      this.pass,
      required this.chatId,
      required this.onRecord,
      this.onDecibelChange,
      this.onRecordingStateChange});
  final String? pass;
  final String chatId;
  final Function onRecord;
  final Function(double)? onDecibelChange;
  final ValueChanged<bool>? onRecordingStateChange;

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

  StreamSubscription<Uint8List>? _mRecordingDataSubscription;
  StreamSubscription<RecordingDisposition>? _recorderProgressSub;
  StreamController<Uint8List>? recordingDataController;
  BytesBuilder recordingData = BytesBuilder();
  int? recordingMicroSeconds;
  List<double> recordedDecibels = [];

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
    final isRecording = status == AnimationStatus.forward;
    setState(() {
      recording = isRecording;
    });
    widget.onRecordingStateChange?.call(isRecording);
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

    // Keep onProgress subscription just for duration tracking
    _recorderProgressSub = _myRecorder!.onProgress!.listen((e) {
      recordingMicroSeconds = e.duration.inMicroseconds;
    });

    await _myRecorder!
        .setSubscriptionDuration(const Duration(milliseconds: 100)); // 100ms
  }

  Future<void> record() async {
    try {
      await _openRecorder();
    } catch (e) {
      controller.reset();
      widget.onRecordingStateChange?.call(false);
      return;
    }

    widget.onRecordingStateChange?.call(true);
    recordingData.clear();
    recordedDecibels.clear();

    recordingDataController = StreamController<Uint8List>();
    _mRecordingDataSubscription =
        recordingDataController?.stream.listen((data) {
      recordingData.add(data);

      // Calculate amplitude from raw PCM data
      final amplitude = _calculateAmplitudeFromPCM(data);
      recordedDecibels.add(amplitude);
      widget.onDecibelChange?.call(amplitude);
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

  /// Calculate amplitude from PCM Float32 audio data
  /// Returns normalized amplitude value (0.0-1.0)
  double _calculateAmplitudeFromPCM(Uint8List data) {
    if (data.isEmpty) return 0.0;

    // Convert bytes to Float32 samples using ByteData for proper endianness handling
    final byteData = ByteData.sublistView(data);
    final sampleCount = data.length ~/ 4; // 4 bytes per Float32

    // Calculate RMS (Root Mean Square) amplitude
    double sum = 0.0;

    for (int i = 0; i < sampleCount; i++) {
      // Read Float32 in little-endian (standard for most platforms)
      final sample = byteData.getFloat32(i * 4, Endian.little);

      // Skip invalid/NaN/Infinity values
      if (!sample.isFinite) continue;

      sum += sample * sample;
    }

    // Calculate RMS
    double rms = 0.0;
    if (sampleCount > 0 && sum.isFinite) {
      final avgSumOfSquares = sum / sampleCount;
      if (avgSumOfSquares.isFinite && avgSumOfSquares >= 0) {
        rms = sqrt(avgSumOfSquares);
      }
    }

    // Apply a compression curve to make quiet sounds more visible
    return sqrt(rms).clamp(0.0, 1.0);
  }

  Future<void> stopRecorder() async {
    try {
      await _myRecorder?.stopRecorder();
    } catch (_) {
      // recorder might not be started yet
    }

    try {
      await _myRecorder?.closeRecorder();
    } catch (_) {
      // ignore close errors
    }

    await _mRecordingDataSubscription?.cancel();
    _mRecordingDataSubscription = null;

    await _recorderProgressSub?.cancel();
    _recorderProgressSub = null;

    await recordingDataController?.close();
    recordingDataController = null;
    widget.onRecordingStateChange?.call(false);

    if (recordingData.isNotEmpty && recordingMicroSeconds != null) {
      widget.onRecord(
          recordingData.toBytes(), recordingMicroSeconds, recordedDecibels);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        controller.forward().then((value) {
          controller.reset();
        });
        record();
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
        ],
      ),
    );
  }
}
