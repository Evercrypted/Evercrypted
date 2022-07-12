import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/primary_button.dart';
import '../../ui_constants.dart';
import 'components/info.dart';
import 'components/profile_pic.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              "Annette Black",
              style: Theme.of(context).textTheme.headline6,
            ),
            const Divider(height: defaultPadding * 2),
            Info(
              infoKey: "User ID",
              info: "@annette.me",
            ),
            Info(
              infoKey: "Location",
              info: "New York, NYC",
            ),
            Info(
              infoKey: "Phone",
              info: "(239) 555-0108",
            ),
            Info(
              infoKey: "Email Address",
              info: "demo@mail.com",
            ),
            const SizedBox(height: defaultPadding),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 120,
                child: PrimaryButton(
                  padding: EdgeInsets.all(5),
                  text: "Edit Profile",
                  press: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 120,
                child: PrimaryButton(
                    padding: EdgeInsets.all(5),
                    text: "Sign Out",
                    press: () => _signOut()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
