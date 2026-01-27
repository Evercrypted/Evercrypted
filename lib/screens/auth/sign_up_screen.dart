import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_text_controller.dart';
import 'package:evercrypted/core/services/auth_service.dart';
import 'package:evercrypted/core/services/firebase_auth_service.dart';
import 'package:evercrypted/core/helpers/field_validators.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/widgets/evercrypted_text_field.dart';
import 'package:evercrypted/widgets/social_login_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io' show Platform;

import './sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/primary_button.dart';
import 'package:evercrypted/widgets/terms_and_privacy_links.dart';

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
  bool _googleLoading = false;
  bool _appleLoading = false;
  final EvercryptedTextController _emailController =
      EvercryptedTextController();
  final EvercryptedTextController _confirmController =
      EvercryptedTextController();
  final EvercryptedTextController _passController = EvercryptedTextController();
  final listViewController = ScrollController();

  final AuthService _authService = AuthService();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

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

    // Manual validation since we're using EvercryptedTextField
    final email = _emailController.text;
    final password = _passController.text;
    final confirmPassword = _confirmController.text;

    // Validate email
    final emailError = validateEmail(email);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(emailError, style: const TextStyle(color: Colors.white)),
        backgroundColor: errorColor,
      ));
      return;
    }

    // Validate password
    final passwordError = validatePassword(password);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(passwordError, style: const TextStyle(color: Colors.white)),
        backgroundColor: errorColor,
      ));
      return;
    }

    // Validate confirm password
    if (confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Field should not be empty.',
            style: TextStyle(color: Colors.white)),
        backgroundColor: errorColor,
      ));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Passwords do not match.',
            style: TextStyle(color: Colors.white)),
        backgroundColor: errorColor,
      ));
      return;
    }

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
            content:
                Text(e.toString(), style: const TextStyle(color: Colors.white)),
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

  void _handleGoogleSignIn() async {
    setState(() {
      _googleLoading = true;
    });

    final result = await _firebaseAuthService.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _googleLoading = false;
    });

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          result['error'] ?? 'Google sign-in failed',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: errorColor,
        dismissDirection: DismissDirection.horizontal,
        showCloseIcon: true,
      ));
    }
  }

  void _handleAppleSignIn() async {
    setState(() {
      _appleLoading = true;
    });

    final result = await _firebaseAuthService.signInWithApple();

    if (!mounted) return;

    setState(() {
      _appleLoading = false;
    });

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          result['error'] ?? 'Apple sign-in failed',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: errorColor,
        dismissDirection: DismissDirection.horizontal,
        showCloseIcon: true,
      ));
    }
  }

  @override
  void dispose() {
    shouldShowKeyboard.removeListener(scrollToBottom);
    listViewController.dispose();
    _emailController.dispose();
    _confirmController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                EvercryptedTextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 1,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide.none,
                    ),
                    labelText: 'Email',
                  ),
                ),
                const SizedBox(height: defaultPadding * 1.5),
                EvercryptedTextField(
                  controller: _passController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 1,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide.none,
                    ),
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
                ),
                const SizedBox(height: defaultPadding * 0.75),
                EvercryptedTextField(
                  controller: _confirmController,
                  obscureText: !_confirmPasswordVisible,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 1,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide.none,
                    ),
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
                ),
                const SizedBox(height: defaultPadding * 2),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                  child: PrimaryButton(
                      press: () => submitForm(context),
                      child: _shouldShowLoading
                          ? const SpinKitThreeBounce(
                              color: Colors.white,
                              size: 17,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login, color: Colors.white),
                                SizedBox(width: 8),
                                Text("Sign Up",
                                    style: TextStyle(color: Colors.white))
                              ],
                            )),
                ),
                const OrDivider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialLoginIconButton(
                      provider: SocialProvider.google,
                      onPressed: _handleGoogleSignIn,
                      isLoading: _googleLoading,
                    ),
                    if (Platform.isIOS) ...[
                      const SizedBox(width: defaultPadding * 1.5),
                      Container(
                        height: 30,
                        width: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                      const SizedBox(width: defaultPadding * 1.5),
                      SocialLoginIconButton(
                        provider: SocialProvider.apple,
                        onPressed: _handleAppleSignIn,
                        isLoading: _appleLoading,
                      ),
                    ],
                  ],
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
                const TermsAndPrivacyLinks(),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
