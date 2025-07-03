import 'dart:async';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/core/navigation/navigation_state.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/screens/auth/components/reset_password.dart';
import 'package:evercrypted/screens/profile/components/keyboard_settings.dart';
import 'package:evercrypted/screens/profile/otp_screen.dart';
import 'package:evercrypted/screens/activation/activation_mainscreen.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:evercrypted/widgets/primary_button.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../ui_constants.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  static const routeName = '/profile-screen';

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Color dialogPickerColor;
  bool isActivated = Auth.getUser?.activated ?? false;
  StreamSubscription? authListener;

  Future<void> _signOut() async {
    await Auth.clearAuth();
  }

  @override
  void initState() {
    super.initState();
    dialogPickerColor = errorColor;

    // Set navigation state to profile when this screen is active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationProvider.notifier).navigateToProfile();
    });

    authListener = Auth.authSubject.distinct().listen((shouldFire) {
      setState(() {
        isActivated = Auth.getUser?.activated ?? false;
      });
    });
  }

  @override
  void dispose() {
    authListener?.cancel();
    super.dispose();
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: CircleAvatarWithActiveIndicator(
                image: profile?.avatar?.pic,
                name: profile?.name ?? profile?.email?.split('@')[0],
                isActive: false,
              ),
              title: Text(
                profile?.name ?? profile?.email?.split('@')[0] ?? '',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                profile?.email ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              trailing: Icon(
                Icons.qr_code,
                color: primaryColor,
                size: 28,
              ),
              onTap: () {
                showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height *
                          0.8, // 80% of screen height
                    ),
                    builder: (context) => SingleChildScrollView(
                        child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(defaultPadding * 2),
                                topRight: Radius.circular(defaultPadding * 2),
                              ),
                              color: Theme.of(context).scaffoldBackgroundColor,
                            ),
                            padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom),
                            child: Container(
                              margin: const EdgeInsets.all(defaultPadding),
                              padding: const EdgeInsets.fromLTRB(
                                defaultPadding,
                                0,
                                defaultPadding,
                                defaultPadding,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Scan this QR code to add me as a contact',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: defaultPadding),
                                  Container(
                                    margin: const EdgeInsets.only(
                                        top: 10,
                                        left: 20,
                                        right: 20,
                                        bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: QrImageView(
                                      data: profile!.email!,
                                      version: QrVersions.auto,
                                      embeddedImage:
                                          AssetImage('assets/icons/logo.png'),
                                      size: MediaQuery.of(context).size.width *
                                          0.7,
                                    ),
                                  ),
                                  Text(
                                    profile.email!,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: defaultPadding),
                                  Padding(
                                    padding:
                                        const EdgeInsets.all(defaultPadding),
                                    child: PrimaryButton(
                                        text: 'Close',
                                        press: () {
                                          Navigator.pop(context);
                                        }),
                                  ),
                                ],
                              ),
                            ))));
              },
            ),
            const SizedBox(height: 10),
            // Account Section
            Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha((255 * 0.1).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.key,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Password',
                    style: TextStyle(fontSize: 16),
                  ),
                  subtitle: const Text(
                    'Change password',
                    style: TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height *
                            0.8, // 80% of screen height
                      ),
                      builder: (BuildContext context) => const ResetPassword(),
                    );
                  },
                ),
                ListTile(
                  leading: Opacity(
                    opacity: isActivated ? 1.0 : 0.5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.lock,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                  title: Opacity(
                    opacity: isActivated ? 1.0 : 0.5,
                    child: const Text(
                      'Two-factor authentication',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  subtitle: Opacity(
                    opacity: isActivated ? 1.0 : 0.5,
                    child: Text(
                      isActivated
                          ? (Auth.isOtpActive!
                              ? 'Enabled'
                              : 'Add extra security to your account')
                          : 'Needs activation',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  trailing: isActivated
                      ? null
                      : const Icon(Icons.lock_outline, color: Colors.grey),
                  onTap: () {
                    if (isActivated) {
                      Navigator.pushNamed(context, OtpScreen.routeName);
                    } else {
                      Navigator.pushNamed(
                          context, ActivationMainScreen.routeName);
                    }
                  },
                ),
                ListTile(
                  leading: Opacity(
                    opacity: isActivated ? 1.0 : 0.5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.keyboard,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                  title: Opacity(
                    opacity: isActivated ? 1.0 : 0.5,
                    child: const Text(
                      'In-App Keyboard',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  subtitle: Opacity(
                    opacity: isActivated ? 1.0 : 0.5,
                    child: Text(
                      isActivated
                          ? 'Secure keyboard settings'
                          : 'Needs activation',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  trailing: isActivated
                      ? null
                      : const Icon(Icons.lock_outline, color: Colors.grey),
                  onTap: () {
                    if (isActivated) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const KeyboardSettingsScreen(),
                        ),
                      );
                    } else {
                      Navigator.pushNamed(
                          context, ActivationMainScreen.routeName);
                    }
                  },
                ),
              ],
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.storage,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              title: const Text(
                'Storage and data',
                style: TextStyle(fontSize: 16),
              ),
              subtitle: const Text(
                'Clear local storage',
                style: TextStyle(fontSize: 13),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Clear Storage'),
                      content: const Text(
                          'Are you sure you want to clear all local data?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Clear all ObjectBox boxes
                            obx.messages.removeAll();
                            obx.chats.removeAll();
                            obx.contacts.removeAll();
                            obx.profiles.removeAll();

                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('All local data cleared')),
                            );
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha((255 * 0.1).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Help',
                    style: TextStyle(fontSize: 16),
                  ),
                  subtitle: const Text(
                    'Help center, contact us, privacy policy',
                    style: TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    // Handle help tap
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Sign Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextButton(
                onPressed: () => _signOut(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // App Version
            Center(
              child: Text(
                'Evercrypted\nVersion 1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
