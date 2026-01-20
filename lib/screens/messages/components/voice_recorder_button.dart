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
      this.onRecordingStateChange,
      this.onDurationChange});
  final String? pass;
  final String chatId;
  final Function onRecord;
  final Function(double)? onDecibelChange;
  final ValueChanged<bool>? onRecordingStateChange;
  final ValueChanged<int>? onDurationChange;

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
  bool _isRecorderOpen = false;
  Completer<void>? _recordingStartCompleter;

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
    _isRecorderOpen = true;

    // Keep onProgress subscription just for duration tracking
    _recorderProgressSub = _myRecorder!.onProgress!.listen((e) {
      recordingMicroSeconds = e.duration.inMicroseconds;
      // Report duration change to parent
      widget.onDurationChange?.call(e.duration.inMicroseconds);
    });

    await _myRecorder!
        .setSubscriptionDuration(const Duration(milliseconds: 100)); // 100ms
  }

  Future<void> record() async {
    // Create a completer to track when recording setup is complete
    _recordingStartCompleter = Completer<void>();

    try {
      await _openRecorder();
    } catch (e) {
      _recordingStartCompleter?.complete();
      _recordingStartCompleter = null;
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

    try {
      await _myRecorder?.startRecorder(
        toStream: recordingDataController!.sink,
        codec: Codec.pcmFloat32,
        audioSource: AudioSource.defaultSource,
      );
    } catch (e) {
      // Recorder might have been closed during startup
      debugPrint('startRecorder error: $e');
    } finally {
      // Signal that recording setup is complete (success or failure)
      _recordingStartCompleter?.complete();
      _recordingStartCompleter = null;
    }
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
    // Wait for record() to finish starting up before we try to stop
    if (_recordingStartCompleter != null) {
      await _recordingStartCompleter!.future;
    }

    // Only try to stop if recorder was actually opened
    if (_isRecorderOpen) {
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
      _isRecorderOpen = false;
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

  void _startRecording() {
    controller.forward().then((value) {
      // Auto-stop when time limit reached
      if (recording) {
        _stopRecording();
      }
    });
    record();
  }

  void _stopRecording() {
    stopRecorder();
    controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.only(
              left: recording ? 16 : 8, right: recording ? 4 : 0),
          child: AnimatedScale(
            scale: recording ? 1.5 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CircularProgressIndicator(
                  value: 1.0,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.grey.shade200),
                  strokeWidth: recording ? 8 : 5,
                ),
                CircularProgressIndicator(
                  value: progress,
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                  strokeWidth: 8,
                ),
                if (recording)
                  // Stop button overlay when recording
                  GestureDetector(
                    onTap: _stopRecording,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                else
                  // Mic button to start recording
                  GestureDetector(
                    onTap: _startRecording,
                    child: const Icon(Icons.mic, color: primaryColor),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
