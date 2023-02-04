import 'package:flutter/material.dart';

import '../ui_constants.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    Key? key,
    this.text = '',
    required this.press,
    this.child,
    this.color = primaryColor,
    this.textColor = Colors.white,
    this.padding = const EdgeInsets.all(defaultPadding),
    this.disabled = false,
  }) : super(key: key);

  final String text;
  final VoidCallback press;
  final Color color;
  final Color textColor;
  final EdgeInsets padding;
  final Widget? child;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: disabled
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0)),
                  side: BorderSide(color: color)),
              onPressed: press,
              child: child ??
                  Text(
                    text,
                    style: TextStyle(color: color),
                  ))
          : ElevatedButton(
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
                    style: TextStyle(color: textColor),
                  ),
            ),
    );
  }
}
