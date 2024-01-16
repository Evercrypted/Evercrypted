import 'package:flutter/material.dart';
import 'package:evercrypted/widgets/primary_button.dart';
import 'package:evercrypted/ui_constants.dart';
import '../../screens/auth/sign_in_screen.dart';
import '../../screens/auth/sign_up_screen.dart';

class SigninOrSignupScreen extends StatelessWidget {
  static const routeName = '/signin-or-signup';

  const SigninOrSignupScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset(
                MediaQuery.of(context).platformBrightness == Brightness.light
                    ? "assets/images/Logo_light.png"
                    : "assets/images/Logo_dark.png",
                height: 146,
              ),
              const Spacer(),
              PrimaryButton(
                text: "Sign In",
                press: () =>
                    Navigator.pushNamed(context, SignInScreen.routeName),
              ),
              const SizedBox(height: defaultPadding * 1.5),
              PrimaryButton(
                color: Theme.of(context).colorScheme.secondary,
                text: "Sign Up",
                press: () =>
                    Navigator.pushNamed(context, SignUpScreen.routeName),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
