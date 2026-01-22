import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        HapticFeedback.lightImpact();
        widget.onPressed();
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: isPressed
              ? Colors.white.withAlpha((255 * 0.3).round())
              : widget.backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isActive
                ? Colors.white.withAlpha((255 * 0.2).round())
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
