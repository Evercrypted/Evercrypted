import 'dart:async';

import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/primary_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'components/logo_with_title.dart';

class VerificationScreen extends StatefulWidget {
  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  int buttonDisableDuration = 0;
  Timer? disableInterval;

  final User? user = FirebaseAuth.instance.currentUser;

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
                    .bodyText1!
                    .color!
                    .withOpacity(0.64),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),
          ],
          PrimaryButton(
            press: () {
              if (buttonDisableDuration != 0) return;
              user?.sendEmailVerification().catchError((e) {
                return;
              });
              setState(() {
                buttonDisableDuration = 60;
              });
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
                    color: primaryColor,
                    size: 17,
                  )
                : null,
          )
        ],
      ),
    );
  }
}
