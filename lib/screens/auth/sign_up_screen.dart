import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_keyboard_riverpod.dart';
import 'package:evercrypted/core/services/auth_service.dart';
import 'package:evercrypted/core/helpers/field_validators.dart';
import 'package:evercrypted/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import './sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/primary_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  static const routeName = '/sign-up';

  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _form = GlobalKey<FormState>();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _shouldShowLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final listViewController = ScrollController();

  final AuthService _authService = AuthService();

  scrollToBottom() {
    if (shouldShowKeyboard.value) {
      Future.delayed(const Duration(milliseconds: 100), () {
        listViewController.animateTo(
          listViewController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    shouldShowKeyboard.addListener(scrollToBottom);
  }

  void submitForm(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(keyboardProvider.notifier).close();

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
    shouldShowKeyboard.removeListener(scrollToBottom);
    listViewController.dispose();
    _emailController.dispose();
    _confirmController.dispose();
    _passController.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardNotifier = ref.read(keyboardProvider.notifier);
    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: ListView(
        controller: listViewController,
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        children: [
          SizedBox(height: defaultPadding * 8),
          SvgPicture.asset(
            logoTheme,
            width: 150,
          ),
          SizedBox(height: defaultPadding * 2),
          Center(
            child: Text(
              "Sign Up",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: defaultPadding * 2),
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
                    keyboardNotifier.openKeyboard(
                        controller: _emailController,
                        onChange: (val) {
                          _emailController.text = val;
                        });
                  },
                ),
                const SizedBox(height: defaultPadding * 1.5),
                TextFormField(
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
                    keyboardNotifier.openKeyboard(
                        controller: _passController,
                        onChange: (val) {
                          _passController.text = val;
                        });
                  },
                ),
                const SizedBox(height: defaultPadding * 0.75),
                TextFormField(
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
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                      icon: Icon(_confirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                    ),
                  ),
                  obscureText: !_confirmPasswordVisible,
                  onTap: () {
                    keyboardNotifier.openKeyboard(
                        controller: _confirmController,
                        onChange: (val) {
                          _confirmController.text = val;
                        });
                  },
                ),
                const SizedBox(height: defaultPadding * 2),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: defaultPadding),
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
                          style:
                              TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .color!
                              .withAlpha((255 * 0.64).round()),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
