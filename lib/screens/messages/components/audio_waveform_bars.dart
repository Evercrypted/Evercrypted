import 'dart:async';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../../../ui_constants.dart';

class AudioWaveformBars extends StatefulWidget {
  final List<double> decibels;
  final double width;
  final double height;
  final Color color;
  final Uint8List? audioData;
  final int? durationMicroSeconds;

  const AudioWaveformBars({
    super.key,
    required this.decibels,
    required this.width,
    required this.height,
    this.color = primaryColor,
    this.audioData,
    this.durationMicroSeconds,
  });

  @override
  AudioWaveformBarsState createState() => AudioWaveformBarsState();
}

class AudioWaveformBarsState extends State<AudioWaveformBars> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool isPlaying = false;
  double playbackProgress = 0.0;
  Timer? playbackProgressTimer;
  bool wasPlayingBeforeDrag = false;

  @override
  void dispose() {
    playbackProgressTimer?.cancel();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> togglePlayback() async {
    if (widget.audioData == null || widget.durationMicroSeconds == null) {
      return;
    }

    if (isPlaying) {
      await stopPlayback();
    } else {
      // Start from current progress position (in case user dragged while stopped)
      await startPlayback(startPosition: playbackProgress);
    }
  }

  Future<void> startPlayback({double startPosition = 0.0}) async {
    if (widget.audioData == null || widget.durationMicroSeconds == null) {
      return;
    }

    // Cancel any existing timer
    playbackProgressTimer?.cancel();

    await _player.openPlayer();

    // Force audio to play through speaker, not earpiece (iOS)
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
    ));

    setState(() {
      isPlaying = true;
      playbackProgress = startPosition;
    });

    // Calculate the audio data offset based on start position
    // PCM Float32 has 4 bytes per sample
    final int bytesPerSample = 4; // Float32
    final int totalSamples = widget.audioData!.length ~/ bytesPerSample;
    final int startSample = (totalSamples * startPosition).round();
    final int startByte = startSample * bytesPerSample;

    // Create a subset of the audio data starting from the seek position
    final Uint8List audioDataFromPosition = startByte < widget.audioData!.length
        ? Uint8List.sublistView(widget.audioData!, startByte)
        : widget.audioData!;

    // Start progress tracking timer (update every 50ms)
    final totalDuration = Duration(microseconds: widget.durationMicroSeconds!);
    final startTime = DateTime.now();
    final startOffset = Duration(
        microseconds: (widget.durationMicroSeconds! * startPosition).round());

    playbackProgressTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      final elapsed = DateTime.now().difference(startTime) + startOffset;
      final progress = elapsed.inMicroseconds / totalDuration.inMicroseconds;

      if (progress >= 1.0) {
        timer.cancel();
        setState(() {
          playbackProgress = 1.0;
        });
      } else {
        setState(() {
          playbackProgress = progress.clamp(0.0, 1.0);
        });
      }
    });

    await _player.startPlayer(
        fromDataBuffer: audioDataFromPosition,
        codec: Codec.pcmFloat32,
        whenFinished: () async {
          playbackProgressTimer?.cancel();
          await _player.stopPlayer();
          await _player.closePlayer();
          setState(() {
            isPlaying = false;
            playbackProgress = 0.0;
          });
        });
  }

  Future<void> seekToPosition(double position) async {
    if (widget.audioData == null || widget.durationMicroSeconds == null) {
      return;
    }

    final wasPlaying = isPlaying;

    // Stop current playback if playing
    if (isPlaying) {
      playbackProgressTimer?.cancel();
      await _player.stopPlayer();
      await _player.closePlayer();
    }

    // Update progress position - this ensures the line moves even when stopped
    setState(() {
      playbackProgress = position.clamp(0.0, 1.0);
      isPlaying = false;
    });

    // If was playing, restart from new position
    if (wasPlaying) {
      await startPlayback(startPosition: position);
    }
  }

  Future<void> stopPlayback() async {
    playbackProgressTimer?.cancel();
    await _player.stopPlayer();
    await _player.closePlayer();
    setState(() {
      isPlaying = false;
      playbackProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.decibels.isEmpty) {
      return SizedBox(width: widget.width, height: widget.height);
    }

    // Calculate how many bars we can fit in the available width
    const barWidth = 3.0;
    const barSpacing = 2.0;
    final totalBarsCanFit = (widget.width / (barWidth + barSpacing)).floor();

    // Sample the decibels array to fit the available space
    final sampledDecibels = _sampleDecibels(widget.decibels, totalBarsCanFit);

    // Normalize the sampled decibels to enhance visual differences
    final normalizedDecibels = _normalizeForVisualization(sampledDecibels);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        children: [
          // Waveform bars
          Expanded(
            child: SizedBox(
              // Fill the entire height to make tapping easier
              height: widget.height,
              child: GestureDetector(
                behavior:
                    HitTestBehavior.opaque, // Capture taps on empty space too
                onTapDown: (details) {
                  if (widget.audioData == null ||
                      widget.durationMicroSeconds == null) {
                    return;
                  }

                  // Check if tap is on play button area (left 40px if audio data exists)
                  const playButtonWidth = 40.0;
                  if (widget.audioData != null &&
                      details.localPosition.dx < playButtonWidth) {
                    togglePlayback();
                    return;
                  }

                  // Calculate tap position relative to waveform width (excluding button area)
                  final buttonOffset =
                      widget.audioData != null ? playButtonWidth : 0.0;
                  final waveformWidth = widget.width - buttonOffset;
                  final adjustedTapX = details.localPosition.dx - buttonOffset;
                  final tapPosition =
                      (adjustedTapX / waveformWidth).clamp(0.0, 1.0);
                  seekToPosition(tapPosition);
                },
                onHorizontalDragStart: (details) async {
                  if (widget.audioData == null ||
                      widget.durationMicroSeconds == null) {
                    return;
                  }
                  // Save playing state and pause playback while dragging
                  wasPlayingBeforeDrag = isPlaying;
                  if (isPlaying) {
                    playbackProgressTimer?.cancel();
                    await _player.stopPlayer();
                    await _player.closePlayer();
                    setState(() {
                      isPlaying = false;
                    });
                  }
                },
                onHorizontalDragUpdate: (details) {
                  if (widget.audioData == null ||
                      widget.durationMicroSeconds == null) {
                    return;
                  }
                  // Calculate drag position relative to waveform width (excluding button area)
                  const playButtonWidth = 40.0;
                  final buttonOffset =
                      widget.audioData != null ? playButtonWidth : 0.0;
                  final waveformWidth = widget.width - buttonOffset;
                  final adjustedDragX = details.localPosition.dx - buttonOffset;
                  final dragPosition =
                      (adjustedDragX / waveformWidth).clamp(0.0, 1.0);
                  setState(() {
                    playbackProgress = dragPosition;
                  });
                },
                onHorizontalDragEnd: (details) async {
                  if (widget.audioData == null ||
                      widget.durationMicroSeconds == null) {
                    return;
                  }
                  // Resume playback from the dragged position if it was playing before
                  if (wasPlayingBeforeDrag) {
                    await startPlayback(startPosition: playbackProgress);
                    wasPlayingBeforeDrag = false;
                  }
                },
                child: Stack(
                  children: [
                    // Waveform bars with padding for button
                    Padding(
                      padding: EdgeInsets.only(
                        left: widget.audioData != null &&
                                widget.durationMicroSeconds != null
                            ? 40.0
                            : 0.0,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate available width for waveform
                          final availableWidth = constraints.maxWidth;

                          // Ensure we don't try to fit more bars than physically possible
                          final maxPossibleBars =
                              (availableWidth / (barWidth + barSpacing))
                                  .floor();

                          // Re-sample if we have more bars than we can fit
                          final displayDecibels =
                              normalizedDecibels.length > maxPossibleBars
                                  ? _sampleDecibels(
                                      normalizedDecibels, maxPossibleBars)
                                  : normalizedDecibels;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children:
                                List.generate(displayDecibels.length, (index) {
                              final amplitude = displayDecibels[index];
                              // Apply a power curve to make differences more visible
                              final enhancedAmplitude = amplitude * amplitude;
                              // Minimum bar height to make it visible, max 90% of container height
                              final barHeight = (enhancedAmplitude *
                                      widget.height *
                                      0.9)
                                  .clamp(
                                      widget.height * 0.1, widget.height * 0.9);

                              return Container(
                                width: barWidth,
                                height: barHeight,
                                margin: EdgeInsets.symmetric(
                                    horizontal: barSpacing / 2),
                                decoration: BoxDecoration(
                                  color: widget.color,
                                  borderRadius:
                                      BorderRadius.circular(barWidth / 2),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                    // Play/Pause button overlay
                    if (widget.audioData != null &&
                        widget.durationMicroSeconds != null)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Icon(
                            isPlaying ? Icons.stop : Icons.play_arrow,
                            color: widget.color,
                            size: 36,
                          ),
                        ),
                      ),
                    // Progress line
                    if (playbackProgress > 0.0 || isPlaying)
                      Positioned(
                        left: (widget.audioData != null &&
                                    widget.durationMicroSeconds != null
                                ? 40.0
                                : 0.0) +
                            (widget.width -
                                    (widget.audioData != null &&
                                            widget.durationMicroSeconds != null
                                        ? 40.0
                                        : 0.0)) *
                                playbackProgress,
                        top: -2,
                        bottom: -2,
                        child: Container(
                          width: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Normalize decibels to enhance visual differences
  List<double> _normalizeForVisualization(List<double> values) {
    if (values.isEmpty) return values;

    // Find min and max to create better contrast
    double min = values.reduce((a, b) => a < b ? a : b);
    double max = values.reduce((a, b) => a > b ? a : b);

    // If all values are the same, return them as is
    if (max - min < 0.01) {
      return values;
    }

    // Stretch the range to use full 0-1 scale
    return values.map((v) {
      final normalized = (v - min) / (max - min);
      return normalized.clamp(0.0, 1.0);
    }).toList();
  }

  /// Sample the decibels array to fit the target number of bars
  List<double> _sampleDecibels(List<double> source, int targetCount) {
    if (source.length <= targetCount) {
      return source;
    }

    final sampledList = <double>[];
    final step = source.length / targetCount;

    for (int i = 0; i < targetCount; i++) {
      final index = (i * step).floor();
      sampledList.add(source[index]);
    }

    return sampledList;
  }
}
