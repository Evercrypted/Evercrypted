import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';

class HighlightedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onHover;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? hoverColor;
  final Widget child;
  final ButtonStyle? style;

  const HighlightedButton({
    super.key,
    this.onPressed,
    this.onHover,
    this.onLongPress,
    this.backgroundColor = primaryColor,
    this.hoverColor = secondaryColor,
    required this.child,
    this.style,
  });

  @override
  HighlightedButtonState createState() => HighlightedButtonState();
}

class HighlightedButtonState extends State<HighlightedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        _isPressed ? widget.hoverColor : widget.backgroundColor;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: ElevatedButton(
        onPressed: widget.onPressed,
        onLongPress: widget.onLongPress,
        style: widget.style != null
            ? widget.style?.merge(ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                elevation: 0,
                side: const BorderSide(color: Colors.white),
                shadowColor: Colors.white,
                backgroundColor: backgroundColor,
              ))
            : ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                elevation: 0,
                side: const BorderSide(color: Colors.white),
                shadowColor: Colors.white,
                backgroundColor: backgroundColor,
              ),
        child: widget.child,
      ),
    );
  }
}
