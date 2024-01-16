import 'package:evercrypted/core/helpers/field_validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../widgets/primary_button.dart';
import './components/logo_with_title.dart';
import 'package:flutter/material.dart';

import '../../ui_constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const routeName = '/forgot-password';

  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  bool _shouldShowLoading = false;

  submitForm(email) {
    setState(() {
      _shouldShowLoading = true;
    });
    FirebaseAuth.instance.sendPasswordResetEmail(email: email).then((value) {
      setState(() {
        _shouldShowLoading = false;
      });
      Navigator.pop(context);
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(e.toString(), style: const TextStyle(color: Colors.white)),
        backgroundColor: errorColor,
      ));
      setState(() {
        _shouldShowLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LogoWithTitle(
        title: 'Forgot Password',
        subText: "Request password reset email.",
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            child: Form(
              key: _form,
              child: TextFormField(
                validator: validateEmail,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onSaved: submitForm,
              ),
            ),
          ),
          PrimaryButton(
            text: 'Send Email',
            press: () {
              if (_form.currentState!.validate()) {
                _form.currentState!.save();
              }
            },
            child: _shouldShowLoading
                ? const SpinKitThreeBounce(
                    color: Colors.white,
                    size: 17,
                  )
                : null,
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Go Back',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          )
        ],
      ),
    );
  }
}
