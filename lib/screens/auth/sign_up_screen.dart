import 'package:evercrypted/core/services/auth_service.dart';
import 'package:evercrypted/core/helpers/field_validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import './sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/primary_button.dart';

class SignUpScreen extends StatefulWidget {
  static const routeName = '/sign-up';

  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _shouldShowLoading = false;
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  AuthForm formValues = AuthForm();

  void submitForm() async {
    FocusManager.instance.primaryFocus?.unfocus();
    formValues = AuthForm();

    if (_form.currentState!.validate()) {
      _form.currentState!.save();

      if (formValues.email != null && formValues.password != null) {
        setState(() {
          _shouldShowLoading = true;
        });

        _authService.signUp(formValues).then((result) {
          if (result['success']) {
            FirebaseAuth.instance.currentUser?.sendEmailVerification();
            setState(() {
              _shouldShowLoading = false;
            });
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(result['message'],
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: errorColor,
            ));
            setState(() {
              _shouldShowLoading = false;
            });
          }
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
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Column(
              children: [
                SizedBox(height: constraints.maxHeight * 0.08),
                SvgPicture.asset(
                  logoTheme,
                ),
                SizedBox(height: constraints.maxHeight * 0.08),
                Text(
                  "Sign Up",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: constraints.maxHeight * 0.05),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      TextFormField(
                        validator: validateEmail,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        onSaved: (value) {
                          formValues.email = value;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: defaultPadding),
                        child: TextFormField(
                          validator: validatePassword,
                          controller: _passwordController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            errorMaxLines: 3,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                              icon: Icon(_passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                            ),
                          ),
                          obscureText: !_passwordVisible,
                          onSaved: (value) {
                            formValues.password = value;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: defaultPadding),
                        child: TextFormField(
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Field should not be empty.';
                            } else if (val != _passwordController.text) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _confirmPasswordVisible =
                                      !_confirmPasswordVisible;
                                });
                              },
                              icon: Icon(_confirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                            ),
                          ),
                          obscureText: !_confirmPasswordVisible,
                          onFieldSubmitted: (_) {
                            submitForm();
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: defaultPadding),
                        child: PrimaryButton(
                            text: 'Sign up',
                            press: submitForm,
                            child: _shouldShowLoading
                                ? const SpinKitThreeBounce(
                                    color: Colors.white,
                                    size: 17,
                                  )
                                : null),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, SignInScreen.routeName),
                        child: Text.rich(
                          TextSpan(
                            text: "Already have an account? ",
                            children: [
                              TextSpan(
                                text: "Sign in",
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor),
                              ),
                            ],
                          ),
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
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
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
