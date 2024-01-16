import 'package:flutter/material.dart';

import '../../ui_constants.dart';
import 'components/call_bg.dart';
import 'components/call_option.dart';

class VideoCallingScreen extends StatelessWidget {
  const VideoCallingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: CallBg(
        image: Image.asset(
          "assets/images/call_bg.png",
          fit: BoxFit.cover,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              // Preview of my camera
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.all(defaultPadding),
                  height: 120,
                  width: 96,
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.all(Radius.circular(defaultPadding)),
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(0, 24),
                        blurRadius: 40,
                        color: Colors.black38,
                      ),
                    ],
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage("assets/images/call_bg.png"),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: defaultPadding * 2, vertical: defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CallOption(
                      icon: const Icon(Icons.volume_down),
                      press: () {},
                    ),
                    CallOption(
                      icon: const Icon(Icons.mic),
                      press: () {},
                    ),
                    CallOption(
                      icon: const Icon(Icons.videocam_off),
                      press: () {},
                    ),
                    CallOption(
                      icon: const Icon(Icons.call_end),
                      color: errorColor,
                      press: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
