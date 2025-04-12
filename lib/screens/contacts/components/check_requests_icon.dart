import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';

class CheckRequestsIcon extends StatefulWidget {
  const CheckRequestsIcon({super.key, required this.isThereUnread});
  final bool isThereUnread;

  @override
  State<CheckRequestsIcon> createState() => _CheckRequestsIconState();
}

class _CheckRequestsIconState extends State<CheckRequestsIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FadeTransition(
          opacity: widget.isThereUnread
              ? Tween(begin: 0.4, end: 1.0).animate(_controller)
              : const AlwaysStoppedAnimation(1.0),
          child: const Icon(Icons.mark_email_unread_outlined,
              size: 30, color: primaryColor),
        ),
        if (widget.isThereUnread)
          Positioned(
            right: 0,
            top: 1,
            child: Container(
              height: 13,
              width: 13,
              decoration: BoxDecoration(
                color: errorColor,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor, width: 2),
              ),
            ),
          )
      ],
    );
  }
}
