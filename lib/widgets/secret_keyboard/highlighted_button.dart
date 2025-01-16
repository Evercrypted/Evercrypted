import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';

class HighlightedButton extends StatefulWidget {
  const HighlightedButton({
    super.key,
    this.style,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.isActive = false,
  });

  final ButtonStyle? style;
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final bool isActive;

  @override
  State<HighlightedButton> createState() => _HighlightedButtonState();
}

class _HighlightedButtonState extends State<HighlightedButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: isPressed
              ? Colors.white.withOpacity(0.3)
              : widget.backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isActive
                ? Colors.white.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
