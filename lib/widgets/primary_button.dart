import 'package:flutter/material.dart';

import '../ui_constants.dart';

class PrimaryButton extends StatelessWidget {
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
  });

  final String text;
  final VoidCallback press;
  final Color color;
  final Color textColor;
  final bool textBold;
  final EdgeInsets padding;
  final Widget? child;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0)),
            padding: padding,
            backgroundColor: color,
          ),
          onPressed: press,
          child: child ??
              Text(
                text,
                style: TextStyle(
                    color: textColor,
                    fontWeight: textBold ? FontWeight.bold : FontWeight.normal),
              ),
        ),
      ),
    );
  }
}
