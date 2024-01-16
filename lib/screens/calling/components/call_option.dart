import 'package:flutter/material.dart';

class CallOption extends StatelessWidget {
  const CallOption({
    super.key,
    required this.icon,
    required this.press,
    this.color = Colors.white10,
  });

  final Icon icon;
  final VoidCallback press;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: icon,
      ),
    );
  }
}
