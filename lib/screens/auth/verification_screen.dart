import 'dart:async';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/services/auth_service.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'components/logo_with_title.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  VerificationScreenState createState() => VerificationScreenState();
}

class VerificationScreenState extends State<VerificationScreen> {
  int buttonDisableDuration = 0;
  Timer? disableInterval;

  AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    disableInterval?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LogoWithTitle(
        title: 'Verification',
        subText: "Email verification link sent",
        children: [
          const Text(
            "We have sent you a verification link to your email address, please verify your email before continuing.",
            textAlign: TextAlign.center,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.04),
          if (buttonDisableDuration != 0) ...[
            Text(
              'Send verification link again in $buttonDisableDuration seconds',
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .color!
                    .withAlpha((0.64 * 255).round()),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),
          ],
          PrimaryButton(
            press: () {
              if (buttonDisableDuration != 0) return;
              authService.resendVerificationEmail();
              setState(() {
                buttonDisableDuration = 60;
              });
              if (disableInterval != null) disableInterval?.cancel();
              disableInterval = Timer.periodic(
                const Duration(seconds: 1),
                (timer) {
                  setState(
                    () {
                      if (buttonDisableDuration == 0) {
                        disableInterval?.cancel();
                      } else {
                        buttonDisableDuration = buttonDisableDuration - 1;
                      }
                    },
                  );
                },
              );
            },
            text: 'Resend verification email',
            disabled: buttonDisableDuration != 0,
            child: buttonDisableDuration != 0
                ? const SpinKitThreeBounce(
                    color: Colors.white,
                    size: 17,
                  )
                : null,
          ),
          TextButton(
            onPressed: () => Auth.clearAuth(),
            child: Text(
              'Back to Sign In',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
