import 'package:evercrypted/core/helpers/field_validators.dart';

import '../../widgets/primary_button.dart';
import './components/logo_with_title.dart';
import '../chats/chats_screen.dart';
import 'package:flutter/material.dart';

import '../../ui_constants.dart';
import 'sign_in_screen.dart';

class ChangePasswordScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  static const routeName = '/change-password';

  ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String password = '';
    return Scaffold(
      body: LogoWithTitle(
        title: "Change Password",
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  obscureText: true,
                  validator: validatePassword,
                  decoration: const InputDecoration(hintText: 'Password'),
                  onSaved: (passaword) {
                    // Save it
                  },
                  onChanged: (value) {
                    password = value;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                  child: TextFormField(
                    validator: (value) {
                      if (value != password) {
                        return 'Passwords do not match';
                      } else {
                        return null;
                      }
                    },
                    obscureText: true,
                    decoration:
                        const InputDecoration(hintText: 'Confirm Password'),
                    onSaved: (passaword) {
                      // Save it
                    },
                  ),
                ),
              ],
            ),
          ),
          PrimaryButton(
            text: 'Change Password',
            press: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatsScreen(),
                  ),
                );
              }
            },
          ),
          TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, SignInScreen.routeName),
            child: Text.rich(
              TextSpan(
                text: "Already have an account? ",
                children: [
                  TextSpan(
                    text: "Sign in",
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .color!
                        .withOpacity(0.64),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
