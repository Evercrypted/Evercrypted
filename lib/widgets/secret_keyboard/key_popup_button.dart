import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A button widget that displays an iOS-style key popup when pressed.
/// Shows a magnified preview of the key character above the pressed key.
/// On long press, shows a horizontal row of alternative characters (e.g., accented characters)
/// that can be selected by sliding the finger.
class KeyPopupButton extends StatefulWidget {
  const KeyPopupButton({
    super.key,
    required this.keyLabel,
    required this.onPressed,
    this.style,
    this.textStyle,
    this.width,
    this.height = 45,
    this.alternatives,
    this.onAlternativeSelected,
  });

  final String keyLabel;
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final TextStyle? textStyle;
  final double? width;
  final double height;

  /// List of alternative characters (e.g., accented characters) to show on long press
  final List<String>? alternatives;

  /// Callback when an alternative character is selected
  final Function(String)? onAlternativeSelected;

  @override
  State<KeyPopupButton> createState() => _KeyPopupButtonState();
}

class _KeyPopupButtonState extends State<KeyPopupButton>
    with SingleTickerProviderStateMixin {
  bool isPressed = false;
  bool isLongPressed = false;
  int? selectedAlternativeIndex;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Store the center X position of the key when long press starts
  double? _keyCenterX;

  // Store the horizontal offset needed to keep popup within screen bounds
  double _popupHorizontalOffset = 0.0;

  // Width of each alternative key in the popup (base value)
  static const _alternativeKeyWidth = 30.0;

  // Calculate the effective key width for the popup
  double _getEffectiveKeyWidth() {
    if (!_hasAlternatives) return _alternativeKeyWidth;

    final alternativesCount = widget.alternatives!.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxPopupWidth = screenWidth - 20;
    const minKeyWidth = 28.0;
    const maxKeyWidth = 40.0;
    const horizontalPadding = 8.0;

    final idealKeyWidth = _alternativeKeyWidth.clamp(minKeyWidth, maxKeyWidth);
    final idealPopupWidth =
        alternativesCount * idealKeyWidth + horizontalPadding * 2;
    return idealPopupWidth > maxPopupWidth
        ? (maxPopupWidth - horizontalPadding * 2) / alternativesCount
        : idealKeyWidth;
  }

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

  bool get _hasAlternatives =>
      widget.alternatives != null && widget.alternatives!.isNotEmpty;

  // Note: onPointerDown in Listener handles immediate press visual feedback

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    setState(() => isPressed = false);
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  void _onTapCancel() {
    _animationController.reverse();
    setState(() => isPressed = false);
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!_hasAlternatives) {
      // No alternatives, just trigger normal press
      widget.onPressed();
      return;
    }

    HapticFeedback.mediumImpact();

    // Get the key's render box to find its center position on screen
    final RenderBox box = context.findRenderObject() as RenderBox;
    final keyPosition = box.localToGlobal(Offset.zero);
    _keyCenterX = keyPosition.dx + box.size.width / 2;

    // Calculate the popup width and offset needed to keep it on screen
    final screenWidth = MediaQuery.of(context).size.width;
    final alternativesCount = widget.alternatives!.length;
    final effectiveKeyWidth = _getEffectiveKeyWidth();
    const horizontalPadding = 8.0;
    final popupWidth =
        alternativesCount * effectiveKeyWidth + horizontalPadding * 2;

    // Calculate where the popup would be if centered on the key
    final popupLeftEdge = _keyCenterX! - popupWidth / 2;
    final popupRightEdge = _keyCenterX! + popupWidth / 2;

    // Calculate offset to keep popup within screen bounds (with 10px margin)
    const screenMargin = 10.0;
    double offset = 0.0;

    if (popupLeftEdge < screenMargin) {
      // Popup extends beyond left edge - shift right
      offset = screenMargin - popupLeftEdge;
    } else if (popupRightEdge > screenWidth - screenMargin) {
      // Popup extends beyond right edge - shift left
      offset = (screenWidth - screenMargin) - popupRightEdge;
    }

    setState(() {
      isLongPressed = true;
      isPressed = false;
      // Start with the first alternative selected
      selectedAlternativeIndex = 0;
      _popupHorizontalOffset = offset;
    });
    _animationController.forward();
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!isLongPressed || !_hasAlternatives || _keyCenterX == null) return;

    final fingerX = details.globalPosition.dx;
    final alternativesCount = widget.alternatives!.length;
    final effectiveKeyWidth = _getEffectiveKeyWidth();

    // Calculate the popup's left edge X position
    // The popup is centered on the key, plus any offset to keep it on screen
    final popupWidth = alternativesCount * effectiveKeyWidth;
    final popupLeftX = _keyCenterX! - popupWidth / 2 + _popupHorizontalOffset;

    // Calculate which alternative the finger is over
    final fingerOffsetInPopup = fingerX - popupLeftX;
    int newIndex = (fingerOffsetInPopup / effectiveKeyWidth).floor();

    // Clamp to valid range
    newIndex = newIndex.clamp(0, alternativesCount - 1);

    if (newIndex != selectedAlternativeIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        selectedAlternativeIndex = newIndex;
      });
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!isLongPressed) return;

    _animationController.reverse();

    // Select the highlighted alternative
    if (selectedAlternativeIndex != null &&
        _hasAlternatives &&
        selectedAlternativeIndex! < widget.alternatives!.length) {
      final selected = widget.alternatives![selectedAlternativeIndex!];
      if (widget.onAlternativeSelected != null) {
        widget.onAlternativeSelected!(selected);
      }
    }

    setState(() {
      isLongPressed = false;
      selectedAlternativeIndex = null;
      _keyCenterX = null;
      _popupHorizontalOffset = 0.0;
    });
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
              child: isLongPressed && _hasAlternatives
                  ? Transform.translate(
                      offset: Offset(_popupHorizontalOffset, 0),
                      child: _AlternativesPopup(
                        alternatives: widget.alternatives!,
                        selectedIndex: selectedAlternativeIndex ?? 0,
                        keyWidth: _alternativeKeyWidth,
                        tailOffset: -_popupHorizontalOffset,
                      ),
                    )
                  : _KeyPopup(
                      keyLabel: widget.keyLabel,
                      width: popupWidth,
                      height: popupHeight,
                      bubbleTailHeight: bubbleTailHeight,
                    ),
            ),
          ),
          // The actual button - wrapped in Listener for immediate popup response
          Positioned.fill(
            child: Listener(
              // Use Listener for immediate pointer events (bypasses gesture disambiguation)
              onPointerDown: (_) {
                setState(() => isPressed = true);
                _animationController.forward();
              },
              onPointerUp: (_) {
                // Only handle if not in long press mode (GestureDetector handles that)
                if (!isLongPressed) {
                  _animationController.reverse();
                  setState(() => isPressed = false);
                }
              },
              onPointerCancel: (_) {
                if (!isLongPressed) {
                  _animationController.reverse();
                  setState(() => isPressed = false);
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Remove onTapDown - Listener handles immediate response
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onLongPressStart: _hasAlternatives ? _onLongPressStart : null,
                onLongPressMoveUpdate:
                    _hasAlternatives ? _onLongPressMoveUpdate : null,
                onLongPressEnd: _hasAlternatives ? _onLongPressEnd : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
                  decoration: BoxDecoration(
                    color: isPressed || isLongPressed
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
          ),
        ],
      ),
    );
  }
}

/// Popup showing alternative characters in a horizontal row
class _AlternativesPopup extends StatelessWidget {
  const _AlternativesPopup({
    required this.alternatives,
    required this.selectedIndex,
    required this.keyWidth,
    this.tailOffset = 0.0,
  });

  final List<String> alternatives;
  final int selectedIndex;
  final double keyWidth;
  final double tailOffset;

  static const _popupBackgroundColor = Color(0xFF2A2A2A);
  static const _popupBorderColor = Color(0xFF4A4A4A);
  static const _selectedColor = Color(0xFF007AFF);
  static const _minKeyWidth = 28.0;
  static const _maxKeyWidth = 40.0;
  static const _horizontalPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    // Calculate dynamic width based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final maxPopupWidth = screenWidth - 20; // 10px margin on each side

    // Calculate ideal width per alternative
    final idealKeyWidth = keyWidth.clamp(_minKeyWidth, _maxKeyWidth);
    final idealPopupWidth =
        alternatives.length * idealKeyWidth + _horizontalPadding * 2;

    // If ideal width exceeds max, shrink each key proportionally
    final effectiveKeyWidth = idealPopupWidth > maxPopupWidth
        ? (maxPopupWidth - _horizontalPadding * 2) / alternatives.length
        : idealKeyWidth;

    final popupWidth =
        alternatives.length * effectiveKeyWidth + _horizontalPadding * 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main popup bubble with alternatives
        Container(
          width: popupWidth,
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding / 2),
          decoration: BoxDecoration(
            color: _popupBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _popupBorderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.5).round()),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(alternatives.length, (index) {
              final isSelected = index == selectedIndex;
              return Container(
                width: effectiveKeyWidth,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? _selectedColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  alternatives[index],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSelected ? 22 : 18,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              );
            }),
          ),
        ),
        // Bubble tail (pointing down) - offset to point at the original key
        Transform.translate(
          offset: Offset(tailOffset, 0),
          child: CustomPaint(
            size: const Size(42, 8),
            painter: _BubbleTailPainter(
              backgroundColor: _popupBackgroundColor,
              borderColor: _popupBorderColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// The popup bubble that appears above the pressed key (single character)
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
