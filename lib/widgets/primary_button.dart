import 'dart:async';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/screens/activation/activation_mainscreen.dart';
import 'package:flutter/material.dart';

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
    return SizedBox(
      width: widget.width,
      child: Opacity(
        opacity: widget.disabled ? 0.5 : 1,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            padding: (widget.needsActivation && !isActivated)
                ? EdgeInsets.symmetric(
                    horizontal: defaultPadding, vertical: defaultPadding / 2)
                : widget.padding,
            backgroundColor: widget.needsActivation && !isActivated
                ? Colors.grey
                : widget.color,
          ),
          onPressed: widget.needsActivation && !isActivated
              ? openActivationDialog
              : widget.disabled
                  ? null
                  : widget.press,
          child: widget.needsActivation && !isActivated
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      content,
                      Text('Needs Activation',
                          style:
                              TextStyle(color: widget.textColor, fontSize: 10)),
                    ],
                  ))
              : content,
        ),
      ),
    );
  }
}
