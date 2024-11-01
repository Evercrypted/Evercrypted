import 'package:evercrypted/core/services/auth_service.dart';
import 'package:evercrypted/core/helpers/field_validators.dart';
import 'package:evercrypted/widgets/secret_keyboard/secret_input.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import './sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/primary_button.dart';

class SignUpScreen extends StatefulWidget {
  static const routeName = '/sign-up';

  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _shouldShowLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  final AuthService _authService = AuthService();

  void submitForm(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_form.currentState!.validate()) {
      _form.currentState!.save();

      if (_emailController.text.isNotEmpty &&
          _passController.text.isNotEmpty &&
          _confirmController.text.isNotEmpty &&
          _passController.text == _confirmController.text) {
        setState(() {
          _shouldShowLoading = true;
        });

        _authService
            .signUp(AuthForm(
                email: _emailController.text, password: _passController.text))
            .then((result) {
          if (result['success']) {
            setState(() {
              _shouldShowLoading = false;
            });
            if (context.mounted) {
              Navigator.pop(context);
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result['message'],
                    style: const TextStyle(color: Colors.white)),
                backgroundColor: errorColor,
                dismissDirection: DismissDirection.horizontal,
                showCloseIcon: true,
              ));
            }
            setState(() {
              _shouldShowLoading = false;
            });
          }
        }).catchError((e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString(),
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: errorColor,
              dismissDirection: DismissDirection.horizontal,
              showCloseIcon: true,
            ));
          }
          setState(() {
            _shouldShowLoading = false;
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _confirmController.dispose();
    _passController.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
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
                  width: 150,
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
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                        keyboardType: TextInputType.none,
                        onTap: () {
                          openSecretInput(
                              isSingleLine: true,
                              fieldName: 'Email',
                              context: context,
                              controller: _emailController,
                              done: (val) {
                                _emailController.text = val.text;
                                if (_passController.text.isEmpty) {
                                  FocusScope.of(context)
                                      .requestFocus(_passFocus);
                                  openSecretInput(
                                      fieldName: 'Password',
                                      isPasswordLike: true,
                                      isSingleLine: true,
                                      context: context,
                                      controller: _passController,
                                      done: (val) {
                                        _passController.text = val.text;
                                        if (_confirmController.text.isEmpty) {
                                          FocusScope.of(context)
                                              .requestFocus(_confirmFocus);
                                          openSecretInput(
                                              fieldName: 'Confirm Password',
                                              isPasswordLike: true,
                                              isSingleLine: true,
                                              context: context,
                                              controller: _confirmController,
                                              done: (val) {
                                                _confirmController.text =
                                                    val.text;
                                                submitForm(context);
                                              });
                                        }
                                      });
                                }
                              });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: defaultPadding),
                        child: TextFormField(
                          validator: validatePassword,
                          controller: _passController,
                          focusNode: _passFocus,
                          keyboardType: TextInputType.none,
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
                          onTap: () {
                            openSecretInput(
                                fieldName: 'Password',
                                isSingleLine: true,
                                isPasswordLike: true,
                                context: context,
                                controller: _passController,
                                done: (val) {
                                  _passController.text = val.text;
                                  if (_confirmController.text.isEmpty) {
                                    FocusScope.of(context)
                                        .requestFocus(_confirmFocus);
                                    openSecretInput(
                                        fieldName: 'Confirm Password',
                                        isSingleLine: true,
                                        isPasswordLike: true,
                                        context: context,
                                        controller: _confirmController,
                                        done: (val) {
                                          _confirmController.text = val.text;
                                          submitForm(context);
                                        });
                                  }
                                });
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
                            } else if (val != _passController.text) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.none,
                          controller: _confirmController,
                          focusNode: _confirmFocus,
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
                          onTap: () {
                            openSecretInput(
                                fieldName: 'Confirm Password',
                                isPasswordLike: true,
                                isSingleLine: true,
                                context: context,
                                controller: _confirmController,
                                done: (val) {
                                  _confirmController.text = val.text;
                                  submitForm(context);
                                });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: defaultPadding),
                        child: PrimaryButton(
                            text: 'Sign up',
                            press: () => submitForm(context),
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
