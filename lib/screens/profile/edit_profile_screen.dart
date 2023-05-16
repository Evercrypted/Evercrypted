import 'package:flutter/material.dart';

import '../../widgets/primary_button.dart';
import '../../ui_constants.dart';
import '../search/components/body.dart';
import 'components/profile_pic.dart';
import 'components/user_info_edit_field.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        child: Column(
          children: [
            ProfilePic(
              image: demoContactsImage[0],
              imageUploadBtnPress: () {},
            ),
            const Divider(),
            Form(
              child: Column(
                children: [
                  UserInfoEditField(
                    text: "Name",
                    child: TextFormField(
                      initialValue: "Annette Black",
                    ),
                  ),
                  UserInfoEditField(
                    text: "Email",
                    child: TextFormField(
                      initialValue: "annette@gmail.com",
                    ),
                  ),
                  UserInfoEditField(
                    text: "Phone",
                    child: TextFormField(
                      initialValue: "(316) 555-0116",
                    ),
                  ),
                  UserInfoEditField(
                    text: "Address",
                    child: TextFormField(
                      initialValue: "New York, NVC",
                    ),
                  ),
                  UserInfoEditField(
                    text: "Old Password",
                    child: TextFormField(
                      obscureText: true,
                      initialValue: "demopass",
                      decoration: const InputDecoration(
                        suffixIcon: Icon(
                          Icons.visibility_off,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  UserInfoEditField(
                    text: "New Password",
                    child: TextFormField(
                      decoration: const InputDecoration(hintText: "New Password"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: defaultPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 100,
                  child: PrimaryButton(
                    padding: const EdgeInsets.all(5),
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .color!
                        .withOpacity(0.08),
                    text: "Cancel",
                    press: () {},
                  ),
                ),
                const SizedBox(width: defaultPadding),
                SizedBox(
                  width: 130,
                  child: PrimaryButton(
                    padding: const EdgeInsets.all(5),
                    text: "Save Update",
                    press: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
