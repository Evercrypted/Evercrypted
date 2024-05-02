import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/screens/auth/forgot_password_screen.dart';
import 'package:evercrypted/screens/profile/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/settings_service.dart';
import '../../widgets/primary_button.dart';
import '../../ui_constants.dart';
import 'components/info.dart';
import 'components/profile_pic.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  ProfileScreen({super.key});
  final SettingsService settingsService = SettingsService();

  Future<void> _signOut() async {
    await Auth.clearAuth();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        child: Column(
          children: [
            ProfilePic(
              image: "assets/images/user_2.png",
              imageUploadBtnPress: () {},
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
              text: "Edit Profile",
              press: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ),
            ),
            PrimaryButton(
              padding: const EdgeInsets.all(5),
              text: "Forgot Password?",
              press: () =>
                  Navigator.pushNamed(context, ForgotPasswordScreen.routeName),
            ),
            PrimaryButton(
              padding: const EdgeInsets.all(5),
              text: Auth.isOtpActive! ? "Deactivate 2FA" : "Activate 2FA",
              press: () => Navigator.pushNamed(context, OtpScreen.routeName),
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
