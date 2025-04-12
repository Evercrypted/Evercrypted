import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/screens/auth/components/reset_password.dart';
import 'package:evercrypted/screens/profile/components/keyboard_settings.dart';
import 'package:evercrypted/screens/profile/otp_screen.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/primary_button.dart';
import '../../ui_constants.dart';
import 'components/info.dart';
import 'components/profile_pic.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Color dialogPickerColor;

  Future<void> _signOut() async {
    await Auth.clearAuth();
  }

  @override
  void initState() {
    super.initState();
    dialogPickerColor = errorColor;
  }

  Future<bool> colorPickerDialog() async {
    return ColorPicker(
      // Use the dialogPickerColor as start color.
      color: dialogPickerColor,
      // Update the dialogPickerColor using the callback.
      onColorChanged: (Color color) =>
          setState(() => dialogPickerColor = color),
      width: 40,
      height: 40,
      borderRadius: 4,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: Text(
        'Select color',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subheading: Text(
        'Select color shade',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      wheelSubheading: Text(
        'Selected color and its shades',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      showMaterialName: true,
      showColorName: true,
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        longPressMenu: true,
      ),
      materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: true,
        ColorPickerType.wheel: true,
      },
    ).showPickerDialog(
      context,
      // New in version 3.0.0 custom transitions support.
      transitionBuilder: (BuildContext context, Animation<double> a1,
          Animation<double> a2, Widget widget) {
        final double curvedValue =
            Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: widget,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      constraints:
          const BoxConstraints(minHeight: 460, minWidth: 300, maxWidth: 320),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        child: Column(
          children: [
            ProfilePic(
              image: profile?.avatar?.pic,
              name: profile?.name ?? profile?.email?.split('@')[0],
              btnPress: () {
                // colorPickerDialog().then((value) => debugPrint(dialogPickerColor));
              },
            ),
            Text(
              profile?.name ?? '',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Info(
              infoKey: "Email Address",
              info: profile?.email ?? '',
            ),
            const SizedBox(height: defaultPadding),
            PrimaryButton(
                padding: const EdgeInsets.all(5),
                text: "Reset Password",
                press: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(25.0)),
                    ),
                    builder: (BuildContext context) => const ResetPassword(),
                  );
                }),
            PrimaryButton(
              padding: const EdgeInsets.all(5),
              text: Auth.isOtpActive! ? "Deactivate 2FA" : "Activate 2FA",
              press: () => Navigator.pushNamed(context, OtpScreen.routeName),
            ),
            PrimaryButton(
              padding: const EdgeInsets.all(5),
              text: "Keyboard Settings",
              press: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KeyboardSettingsScreen(),
                ),
              ),
            ),
            PrimaryButton(
              padding: const EdgeInsets.all(5),
              text: "Clear OBX",
              press: () {
                // Clear all ObjectBox boxes
                obx.messages.removeAll();
                obx.chats.removeAll();
                obx.contacts.removeAll();
                obx.profiles.removeAll();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All ObjectBox data cleared')),
                );
              },
            ),
            PrimaryButton(
                padding: const EdgeInsets.all(5),
                text: "Sign Out",
                press: () => _signOut()),
          ],
        ),
      ),
    );
  }
}
