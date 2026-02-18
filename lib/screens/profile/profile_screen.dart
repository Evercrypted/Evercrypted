import 'dart:async';
import 'dart:io';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/deep_link/app_link_service.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/core/navigation/navigation_state.dart';
import 'package:evercrypted/core/obx_init.dart';
import 'package:evercrypted/services/biometric_service.dart';
import 'package:evercrypted/services/profanity_filter_service.dart';
import 'package:evercrypted/screens/auth/components/reset_password.dart';
import 'package:evercrypted/screens/profile/components/keyboard_settings.dart';
import 'package:evercrypted/screens/profile/delete_account_screen.dart';
import 'package:evercrypted/screens/profile/otp_screen.dart';
import 'package:evercrypted/screens/activation/activation_mainscreen.dart';
import 'package:evercrypted/screens/blocked_users/blocked_users_screen.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:evercrypted/widgets/avatar_editor_bottom_sheet.dart';
import 'package:evercrypted/widgets/primary_button.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:evercrypted/widgets/terms_and_privacy_links.dart';

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
  bool _biometricEnabled = false;
  bool _profanityFilterEnabled = true;
  StreamSubscription? authListener;

  @override
  void initState() {
    super.initState();
    dialogPickerColor = errorColor;
    _loadBiometricState();
    _loadProfanityFilterState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationProvider.notifier).navigateToProfile();
    });
    authListener = Auth.authSubject.listen((shouldFire) {
      if (mounted) {
        setState(() {
          isActivated = Auth.getUser?.activated ?? false;
        });
      }
    });
  }

  Future<void> _loadBiometricState() async {
    final enabled =
        await ref.read(biometricServiceProvider).isBiometricEnabled();
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<void> _loadProfanityFilterState() async {
    final enabled = await ref.read(profanityFilterServiceProvider).isEnabled();
    if (mounted) setState(() => _profanityFilterEnabled = enabled);
  }

  Future<void> _clearAllLocalData() async {
    // Clear all ObjectBox boxes
    ObxInit.obx.messages.removeAll();
    ObxInit.obx.chats.removeAll();
    ObxInit.obx.profiles.removeAll();
    ObxInit.obx.contactRequests.removeAll();
    ObxInit.obx.actionQueues.removeAll();
    ObxInit.obx.settings.removeAll();

    // Clear files and cache directories
    final directory = await getApplicationDocumentsDirectory();
    final cacheDirectory = await getTemporaryDirectory();

    // Delete all files in documents directory
    if (await directory.exists()) {
      await directory.list(recursive: true).forEach((entity) async {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (e) {
            debugPrint('Error deleting file: $e');
          }
        } else if (entity is Directory && entity.path != directory.path) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            debugPrint('Error deleting directory: $e');
          }
        }
      });
    }

    // Delete all files in cache/temp directory
    if (await cacheDirectory.exists()) {
      await cacheDirectory.list(recursive: true).forEach((entity) async {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (e) {
            debugPrint('Error deleting cache file: $e');
          }
        } else if (entity is Directory && entity.path != cacheDirectory.path) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            debugPrint('Error deleting cache directory: $e');
          }
        }
      });
    }
  }

  Future<void> _signOut() async {
    final bool? shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true) {
      await Auth.clearAuth();
    }
  }

  void _deleteAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeleteAccountScreen(),
      ),
    );
  }

  @override
  void dispose() {
    authListener?.cancel();
    super.dispose();
  }

  String _getSubscriptionSubtitle(dynamic profile) {
    if (profile?.subscription?.endDate != null) {
      try {
        final endDate = DateTime.parse(profile.subscription.endDate);
        final formattedDate = '${endDate.day}/${endDate.month}/${endDate.year}';
        final autoRenew = profile.subscription.autoRenew ?? true;

        if (autoRenew) {
          return 'Renews on $formattedDate';
        } else {
          return 'Expires on $formattedDate';
        }
      } catch (e) {
        return 'Active subscription';
      }
    }
    return 'View your subscription status';
  }

  void _openProfileAvatarEditor(dynamic profile) async {
    final result = await AvatarEditorBottomSheet.show(
      context,
      showNameField: true,
      nameLabel: 'Display Name',
      initialName: profile?.name ?? '',
      initialColor: profile?.avatar?.color != null
          ? Color(int.parse(profile!.avatar!.color!))
          : Colors.blueGrey,
      initialIconCodePoint: profile?.avatar?.icon != null
          ? int.tryParse(profile!.avatar!.icon!)
          : null,
    );

    if (result != null) {
      final avatarMap = <String, dynamic>{
        'color': result.color?.toARGB32().toString(),
        if (result.iconCodePoint != null)
          'icon': result.iconCodePoint.toString(),
      };

      final profileService = ProfileService();
      final updatedProfile = await profileService.updateProfileOnServer(
        name: result.name?.isNotEmpty ?? false
            ? result.name
            : profile?.name.isNotEmpty ?? false
                ? profile?.name
                : profile?.email.split('@')[0],
        avatar: avatarMap,
      );

      if (updatedProfile != null) {
        ref.read(profileProvider.notifier).setProfile(updatedProfile);
      }
    }
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
        actions: [
          if (profile != null) ...[
            GestureDetector(
              onTap: () {
                // Navigate to subscription screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivationMainScreen(),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (profile.subscription?.isActive == true
                          ? primaryColor
                          : secondaryColor)
                      .withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (profile.subscription?.isActive == true
                            ? primaryColor
                            : secondaryColor)
                        .withAlpha((255 * 0.3).round()),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      profile.subscription?.isActive == true
                          ? Icons.verified
                          : Icons.person,
                      color: profile.subscription?.isActive == true
                          ? primaryColor
                          : secondaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      profile.subscription?.isActive == true
                          ? 'Premium'
                          : 'Free',
                      style: TextStyle(
                        fontSize: 14,
                        color: profile.subscription?.isActive == true
                            ? primaryColor
                            : secondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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
              leading: GestureDetector(
                onTap: () => _openProfileAvatarEditor(profile),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatarWithActiveIndicator(
                      image: profile?.avatar?.pic,
                      name: profile?.name ?? profile?.email?.split('@')[0],
                      isActive: false,
                      avatarColor: profile?.avatar?.color != null
                          ? Color(int.parse(profile!.avatar!.color!))
                          : null,
                      avatarIcon: profile?.avatar?.icon != null
                          ? IconData(int.parse(profile!.avatar!.icon!),
                              fontFamily: 'MaterialIcons')
                          : null,
                    ),
                    const Positioned(
                      right: -7,
                      bottom: -7,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 12,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: primaryColor,
                          child: Icon(
                            Icons.edit_sharp,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(
                profile!.name!.isNotEmpty
                    ? profile.name!
                    : (profile.email?.split('@')[0] ?? ''),
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      color: primaryColor,
                      size: 28,
                    ),
                    onPressed: () {
                      final email = profile?.email ?? '';
                      if (email.isNotEmpty) {
                        final shareUrl = AppLinkService.buildShareLink(email);
                        SharePlus.instance.share(
                          ShareParams(
                            text: 'Add me on EverCrypted! $shareUrl',
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      Icons.qr_code,
                      color: primaryColor,
                      size: 28,
                    ),
                    onPressed: () {
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
                                      topLeft:
                                          Radius.circular(defaultPadding * 2),
                                      topRight:
                                          Radius.circular(defaultPadding * 2),
                                    ),
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                  ),
                                  padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context)
                                          .viewInsets
                                          .bottom),
                                  child: Container(
                                    margin:
                                        const EdgeInsets.all(defaultPadding),
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
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: QrImageView(
                                            data: profile!.email!,
                                            version: QrVersions.auto,
                                            embeddedImage: AssetImage(
                                                'assets/icons/logo.png'),
                                            size: MediaQuery.of(context)
                                                    .size
                                                    .width *
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
                                          padding: const EdgeInsets.all(
                                              defaultPadding),
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
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Account Section
            Column(
              children: [
                // Subscription - Featured at top when not activated
                if (!isActivated)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withAlpha((255 * 0.15).round()),
                          primaryColor.withAlpha((255 * 0.05).round()),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withAlpha((255 * 0.3).round()),
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        'Get Premium',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      subtitle: const Text(
                        'Unlock all premium features',
                        style: TextStyle(fontSize: 14),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: primaryColor,
                        size: 18,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActivationMainScreen(),
                          ),
                        );
                      },
                    ),
                  )
                else
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.verified,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'Manage Subscription',
                      style: TextStyle(fontSize: 16),
                    ),
                    subtitle: Text(
                      _getSubscriptionSubtitle(profile),
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActivationMainScreen(),
                        ),
                      );
                    },
                  ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActivationMainScreen(),
                        ),
                      );
                    }
                  },
                ),

                Consumer(builder: (context, ref, child) {
                  final biometricService = ref.read(biometricServiceProvider);
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.fingerprint,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'Biometric Unlock',
                      style: TextStyle(fontSize: 16),
                    ),
                    subtitle: Text(
                      _biometricEnabled ? 'Enabled' : 'Disabled',
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Switch(
                      value: _biometricEnabled,
                      activeTrackColor: primaryColor,
                      onChanged: (value) async {
                        final canCheck =
                            await biometricService.isBiometricAvailable();
                        if (!canCheck) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Biometric authentication not available on this device')),
                            );
                          }
                          return;
                        }

                        final authenticated =
                            await biometricService.authenticate();
                        if (authenticated) {
                          await biometricService.setBiometricEnabled(value);
                          if (mounted) {
                            setState(() {
                              _biometricEnabled = value;
                            });
                          }
                        }
                      },
                    ),
                  );
                }),
                Consumer(builder: (context, ref, child) {
                  final profanityService =
                      ref.read(profanityFilterServiceProvider);
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.block,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'Profanity Filter',
                      style: TextStyle(fontSize: 16),
                    ),
                    subtitle: Text(
                      _profanityFilterEnabled
                          ? 'Block inappropriate words'
                          : 'Disabled',
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Switch(
                      value: _profanityFilterEnabled,
                      activeTrackColor: primaryColor,
                      onChanged: (value) async {
                        await profanityService.setEnabled(value);
                        if (mounted) {
                          setState(() {
                            _profanityFilterEnabled = value;
                          });
                        }
                      },
                    ),
                  );
                }),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha((255 * 0.1).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_off,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Blocked Users',
                    style: TextStyle(fontSize: 16),
                  ),
                  subtitle: const Text(
                    'Manage blocked users',
                    style: TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BlockedUsersScreen(),
                      ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActivationMainScreen(),
                        ),
                      );
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
                          onPressed: () async {
                            try {
                              await _clearAllLocalData();

                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('All local data cleared')),
                                );
                                await _signOut();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error clearing data: $e'),
                                      backgroundColor: errorColor),
                                );
                              }
                            }
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

            const SizedBox(height: 30),

            // Sign Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton(
                onPressed: () => _signOut(),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout,
                      size: 20,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
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

            const SizedBox(height: 10),

            // Delete Account Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextButton(
                onPressed: () => _deleteAccount(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: TermsAndPrivacyLinks(),
            ),
          ],
        ),
      ),
    );
  }
}
