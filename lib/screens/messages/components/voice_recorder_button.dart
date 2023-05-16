import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import '../../../ui_constants.dart';

class VoiceRecorderButton extends StatefulWidget {
  const VoiceRecorderButton({Key? key}) : super(key: key);

  @override
  VoiceRecorderButtonState createState() => VoiceRecorderButtonState();
}

class VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  int voiceMessageDurationSeconds = 30;
  FlutterSoundRecorder? myRecorder;

  void disposeRecorder() {
    myRecorder?.closeRecorder();
    myRecorder = null;
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
        vsync: this, duration: Duration(seconds: voiceMessageDurationSeconds));
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    disposeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) async {
        myRecorder = await FlutterSoundRecorder().openRecorder();

        controller.forward().then((value) {
          disposeRecorder();
          controller.reset();
        });
      },
      onTapUp: (_) {
        disposeRecorder();
        controller.reset();
      },
      onTapCancel: () {
        disposeRecorder();
        controller.reset();
      },
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            value: 1.0,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade200),
          ),
          CircularProgressIndicator(
            value: controller.value,
            valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
          ),
          if (controller.status == AnimationStatus.forward)
            Text(
              (controller.value * voiceMessageDurationSeconds)
                  .round()
                  .toString(),
              style:
                  const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
            )
          else
            const Icon(Icons.mic, color: primaryColor)
        ],
      ),
    );
  }
}
