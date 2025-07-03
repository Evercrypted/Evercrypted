import 'dart:async';
import 'dart:ui';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/screens/activation/activation_mainscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../ui_constants.dart';

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    this.text = '',
    required this.press,
    this.child,
    this.color = primaryColor,
    this.textColor = Colors.white,
    this.padding = const EdgeInsets.all(defaultPadding),
    this.disabled = false,
    this.textBold = false,
    this.needsActivation = false,
    this.width = double.infinity,
  });

  final String text;
  final VoidCallback press;
  final Color color;
  final Color textColor;
  final bool textBold;
  final EdgeInsets padding;
  final Widget? child;
  final bool disabled;
  final bool needsActivation;
  final double width;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool isActivated = Auth.getUser?.activated ?? false;
  StreamSubscription? authListener;

  @override
  void initState() {
    super.initState();
    if (widget.needsActivation) {
      authListener = Auth.authSubject.distinct().listen((shouldFire) {
        setState(() {
          isActivated = Auth.getUser?.activated ?? false;
        });
      });
    }
  }

  @override
  void dispose() {
    authListener?.cancel();
    super.dispose();
  }

  openActivationDialog() {
    Navigator.pushNamed(context, ActivationMainScreen.routeName);
  }

  get content =>
      widget.child ??
      Text(
        widget.text,
        style: TextStyle(
            color: widget.textColor,
            fontWeight:
                widget.textBold || (widget.needsActivation && !isActivated)
                    ? FontWeight.bold
                    : FontWeight.normal),
      );
  @override
  Widget build(BuildContext context) {
    final bool showActivationBadge = widget.needsActivation && !isActivated;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = showActivationBadge
        ? (isDark ? Colors.white : Colors.black87)
        : widget.textColor;
    final Gradient? activationGradient = showActivationBadge
        ? (isDark
            ? LinearGradient(
                colors: [Color(0xFF23272F), Color(0xFF353A45)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Color(0xFFF8F9FA), Color(0xFFE0E3E7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ))
        : null;
    return SizedBox(
      width: widget.width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: widget.disabled ? 0.5 : 1,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32.0), // pill shape
                ),
                padding: showActivationBadge
                    ? EdgeInsets.symmetric(
                        horizontal: defaultPadding,
                        vertical: defaultPadding / 2)
                    : widget.padding,
                backgroundColor: showActivationBadge ? null : widget.color,
                shadowColor: showActivationBadge ? Colors.black12 : null,
                elevation: showActivationBadge ? 4 : null,
              ).copyWith(
                backgroundColor:
                    showActivationBadge ? MaterialStateProperty.all(
                        // Soft gradient using a container below
                        Colors.transparent) : null,
                elevation:
                    showActivationBadge ? MaterialStateProperty.all(4) : null,
              ),
              onPressed: showActivationBadge
                  ? openActivationDialog
                  : widget.disabled
                      ? null
                      : widget.press,
              child: Ink(
                decoration: showActivationBadge
                    ? BoxDecoration(
                        gradient: activationGradient,
                        borderRadius: BorderRadius.circular(32.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      )
                    : null,
                child: Container(
                  alignment: Alignment.center,
                  child: widget.child ??
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: widget.textBold ||
                                  (widget.needsActivation && !isActivated)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                  padding: showActivationBadge
                      ? EdgeInsets.symmetric(vertical: 12)
                      : null,
                ),
              ),
            ),
          ),
          if (showActivationBadge)
            Positioned(
              top: -10,
              right: -10,
              child: GestureDetector(
                onTap: openActivationDialog,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.orange, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Activate',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
