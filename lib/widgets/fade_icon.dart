import 'dart:async';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';

class Position {
  final double top;
  final double left;

  Position({this.top = 0, this.left = 0});
}

class FadeIcon extends StatefulWidget {
  const FadeIcon({super.key, required this.icon, this.position});
  final Widget icon;
  final Position? position;

  @override
  State<FadeIcon> createState() => _FadeIcon();
}

class _FadeIcon extends State<FadeIcon> with TickerProviderStateMixin {
  double opacity = 1;
  late Timer timer;
  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        setState(() {});
      });
    controller.repeat();
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        opacity = opacity == 1 ? 0 : 1;
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
            top: widget.position?.top ?? 0,
            left: widget.position?.left ?? 0,
            child: AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: opacity,
                child: widget.icon)),
        Padding(
          padding: const EdgeInsets.all(1),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: primaryColor,
            value: controller.value,
            semanticsLabel: 'Circular progress indicator',
          ),
        ),
      ],
    );
  }
}
