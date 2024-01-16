import 'package:flutter/material.dart';

import '../../ui_constants.dart';
import 'components/call_bg.dart';
import 'components/call_option.dart';

class AudioCallingScreen extends StatelessWidget {
  const AudioCallingScreen({super.key});

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
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage("assets/images/user_2.png"),
              ),
              const SizedBox(height: defaultPadding),
              Text(
                "Ralph Edwards",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: Colors.white),
              ),
              const SizedBox(height: defaultPadding / 2),
              const Text(
                "Ringing",
                style: TextStyle(color: Colors.white70),
              ),
              const Spacer(),
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
