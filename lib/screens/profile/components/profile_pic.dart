import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:flutter/material.dart';

import '../../../ui_constants.dart';

class ProfilePic extends StatelessWidget {
  const ProfilePic({
    super.key,
    this.name,
    this.image,
    this.color,
    this.isShowPhotoUpload = false,
    this.btnPress,
    this.icon = Icons.edit,
    this.radius = 50,
    this.iconsSize = 20,
    this.circleRadius = 17,
    this.iconBackgroundColor = primaryColor,
    this.iconColor = Colors.white,
    this.iconBorderColor = Colors.white,
  });

  final String? image;
  final Color? color;
  final String? name;
  final bool isShowPhotoUpload;
  final VoidCallback? btnPress;
  final IconData icon;
  final double radius;
  final double iconsSize;
  final double circleRadius;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color iconBorderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      margin: const EdgeInsets.symmetric(vertical: defaultPadding),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color:
              Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.08),
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatarWithActiveIndicator(
            image: image,
            radius: radius,
            name: name,
          ),
          InkWell(
            onTap: btnPress,
            child: CircleAvatar(
              radius: circleRadius,
              backgroundColor: iconBorderColor,
              child: CircleAvatar(
                radius: circleRadius - 2,
                backgroundColor: iconBackgroundColor,
                child: Icon(
                  icon,
                  color: iconColor,
                  size: iconsSize,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
