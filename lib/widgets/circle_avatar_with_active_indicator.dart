import 'package:flutter/material.dart';

import '../ui_constants.dart';

class CircleAvatarWithActiveIndicator extends StatelessWidget {
  const CircleAvatarWithActiveIndicator(
      {super.key,
      this.image,
      this.radius = 24,
      this.isActive = false,
      this.name,
      this.initialsSize = 0.8});

  final String? image;
  final double? radius;
  final bool? isActive;
  final String? name;
  final double initialsSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: image != null && image!.startsWith('http')
              ? NetworkImage(image!)
              : null,
          child: name != null
              ? Text(
                  name!.substring(0, 2).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: radius! * initialsSize,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        if (isActive != null && isActive! == true)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              height: 16,
              width: 16,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor, width: 3),
              ),
            ),
          )
      ],
    );
  }
}
