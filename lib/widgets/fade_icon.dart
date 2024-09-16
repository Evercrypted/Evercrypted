import 'dart:async';
import 'package:flutter/material.dart';

class FadeIcon extends StatefulWidget {
  const FadeIcon({super.key, required this.icon});
  final Widget icon;

  @override
  State<FadeIcon> createState() => _FadeIcon();
}

class _FadeIcon extends State<FadeIcon> {
  double opacity = 1;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        opacity = opacity == 1 ? 0 : 1;
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
        duration: const Duration(seconds: 1),
        opacity: opacity,
        child: widget.icon);
  }
}
