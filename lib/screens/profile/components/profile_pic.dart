import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:flutter/material.dart';

import '../../../ui_constants.dart';

class ProfilePic extends StatelessWidget {
  const ProfilePic(
      {super.key,
      this.name,
      this.image,
      this.color,
      this.avatarColor,
      this.avatarIcon,
      this.isShowPhotoUpload = false,
      this.btnPress,
      this.icon = Icons.edit,
      this.radius = 50,
      this.iconsSize = 20,
      this.circleRadius = 17,
      this.iconBackgroundColor = primaryColor,
      this.iconColor = Colors.white,
      this.iconBorderColor = Colors.white,
      this.confirmText});

  final String? image;
  final Color? color;
  final Color? avatarColor;
  final IconData? avatarIcon;
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
  final String? confirmText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      margin: const EdgeInsets.symmetric(vertical: defaultPadding),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).textTheme.bodyLarge!.color!.withAlpha(
                (255 * 0.08).round(),
              ),
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatarWithActiveIndicator(
            image: image,
            radius: radius,
            name: name,
            avatarColor: avatarColor,
            avatarIcon: avatarIcon,
          ),
          if (btnPress != null)
            InkWell(
              onTap: confirmText == null
                  ? btnPress
                  : () => showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Are you sure?'),
                          content: Text(confirmText!),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      ).then((value) {
                        if (value == null) return;
                        if (value) {
                          btnPress!();
                        }
                      }),
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
