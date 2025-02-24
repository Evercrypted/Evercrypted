import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';

class PasswordDialogIcon extends StatefulWidget {
  const PasswordDialogIcon(
      {super.key,
      required this.settingsDialogOpen,
      required this.pass,
      required this.openPasswordDialog,
      required this.chat,
      required this.baseKey});
  final bool settingsDialogOpen;
  final String? pass;
  final Function() openPasswordDialog;
  final Chat chat;
  final String? baseKey;

  @override
  State<PasswordDialogIcon> createState() => _PasswordDialogIconState();
}

class _PasswordDialogIconState extends State<PasswordDialogIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _flickerController;

  @override
  void initState() {
    super.initState();
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        children: [
          IconButton(
              visualDensity: VisualDensity.compact,
              style: ButtonStyle(
                  padding: WidgetStateProperty.all<EdgeInsets>(
                      const EdgeInsets.all(0)),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          side: BorderSide(
                              width: 2,
                              color: widget.pass == null
                                  ? Colors.redAccent
                                  : primaryColor)))),
              icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => RotationTransition(
                        turns: child.key == ValueKey('icon1')
                            ? Tween<double>(begin: 1, end: 0.75).animate(anim)
                            : Tween<double>(begin: 0.75, end: 1).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                  child: widget.settingsDialogOpen
                      ? FadeTransition(
                          opacity: widget.settingsDialogOpen && widget.pass == null
                              ? Tween(begin: 0.3, end: 1.0)
                                  .animate(_flickerController)
                              : const AlwaysStoppedAnimation(1.0),
                          child: Icon(Icons.policy,
                              size: 22,
                              color: widget.pass == null
                                  ? Colors.redAccent
                                  : primaryColor))
                      : FadeTransition(
                          opacity: const AlwaysStoppedAnimation(1.0),
                          child: Icon(Icons.security, size: 22, color: widget.pass == null ? Colors.redAccent : primaryColor))),
              onPressed: () {
                widget.openPasswordDialog();
              }),
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              height: 12,
              width: 12,
              decoration: BoxDecoration(
                color: !widget.chat.isOneToOne
                    ? Colors.grey
                    : widget.baseKey == null
                        ? Colors.redAccent
                        : primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor, width: 2),
              ),
            ),
          )
        ],
      ),
    );
  }
}
