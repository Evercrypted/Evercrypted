import 'package:flutter/material.dart';

/// A button widget that displays an iOS-style key popup when pressed.
/// Shows a magnified preview of the key character above the pressed key.
/// Uses a simple overflow approach that works in any context.
class KeyPopupButton extends StatefulWidget {
  const KeyPopupButton({
    super.key,
    required this.keyLabel,
    required this.onPressed,
    this.style,
    this.textStyle,
    this.width,
    this.height = 45,
  });

  final String keyLabel;
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final TextStyle? textStyle;
  final double? width;
  final double height;

  @override
  State<KeyPopupButton> createState() => _KeyPopupButtonState();
}

class _KeyPopupButtonState extends State<KeyPopupButton>
    with SingleTickerProviderStateMixin {
  bool isPressed = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 60),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    setState(() => isPressed = false);
    widget.onPressed();
  }

  void _onTapCancel() {
    _animationController.reverse();
    setState(() => isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    // Popup dimensions - smaller and more subtle
    const popupWidth = 42.0;
    const popupHeight = 44.0;
    const bubbleTailHeight = 8.0;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // The popup that appears above the key
          Positioned(
            bottom: widget.height + 2,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) => Transform.scale(
                scale: _scaleAnimation.value,
                alignment: Alignment.bottomCenter,
                child: Opacity(
                  opacity: _scaleAnimation.value,
                  child: child,
                ),
              ),
              child: _KeyPopup(
                keyLabel: widget.keyLabel,
                width: popupWidth,
                height: popupHeight,
                bubbleTailHeight: bubbleTailHeight,
              ),
            ),
          ),
          // The actual button
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                decoration: BoxDecoration(
                  color: isPressed
                      ? Colors.white.withAlpha((255 * 0.35).round())
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.keyLabel,
                  style: widget.textStyle ??
                      const TextStyle(color: Colors.white, fontSize: 20),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The popup bubble that appears above the pressed key
class _KeyPopup extends StatelessWidget {
  const _KeyPopup({
    required this.keyLabel,
    required this.width,
    required this.height,
    required this.bubbleTailHeight,
  });

  final String keyLabel;
  final double width;
  final double height;
  final double bubbleTailHeight;

  // Dark background matching keyboard style
  static const _popupBackgroundColor = Color(0xFF2A2A2A);
  static const _popupBorderColor = Color(0xFF4A4A4A);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main popup bubble
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: _popupBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _popupBorderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.5).round()),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            keyLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w500,
            ),
            textDirection: TextDirection.ltr,
          ),
        ),
        // Bubble tail (pointing down)
        CustomPaint(
          size: Size(width, bubbleTailHeight),
          painter: _BubbleTailPainter(
            backgroundColor: _popupBackgroundColor,
            borderColor: _popupBorderColor,
          ),
        ),
      ],
    );
  }
}

/// Paints the triangular tail of the popup bubble
class _BubbleTailPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;

  _BubbleTailPainter({
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(size.width / 2 - 8, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + 8, 0);

    // Draw shadow
    canvas.drawShadow(path, Colors.black, 2, false);
    // Draw background
    canvas.drawPath(path, backgroundPaint);
    // Draw border on sides only (not top)
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
