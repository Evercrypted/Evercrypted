import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_text_controller.dart';
import 'package:evercrypted/core/services/auth_service.dart';
import 'package:evercrypted/core/services/firebase_auth_service.dart';
import 'package:evercrypted/core/helpers/field_validators.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/screens/auth/components/reset_password.dart';
import 'package:evercrypted/widgets/evercrypted_text_field.dart';
import 'package:evercrypted/widgets/social_login_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io' show Platform;

import '../../widgets/primary_button.dart';
import '../../ui_constants.dart';
import '../../widgets/terms_and_privacy_links.dart';
import '../../widgets/terms_checkbox.dart';
import './sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SignInScreen extends ConsumerStatefulWidget {
  static const routeName = '/sign-in';

  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _shouldShowLoading = false;
  bool _googleLoading = false;
  bool _appleLoading = false;
  bool _agreedToTerms = false;
  AuthForm formValues = AuthForm();
  final EvercryptedTextController _emailField = EvercryptedTextController();
  final EvercryptedTextController _passController = EvercryptedTextController();
  final AuthService _authService = AuthService();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  final listViewController = ScrollController();

  @override
  void initState() {
    super.initState();
    shouldShowKeyboard.addListener(scrollToBottom);
  }

  @override
  void dispose() {
    shouldShowKeyboard.removeListener(scrollToBottom);
    listViewController.dispose();
    _emailField.dispose();
    _passController.dispose();
    super.dispose();
  }

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

  void submitForm(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    // Manual validation since we're using EvercryptedTextField
    final email = _emailField.text;
    final password = _passController.text;

    // Validate email
    final emailError = validateEmail(email);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(emailError, style: const TextStyle(color: Colors.white)),
        backgroundColor: errorColor,
      ));
      return;
    }

    // Set form values
    formValues.email = email;
    formValues.password = password;

    if (formValues.email != null && formValues.password != null) {
      setState(() {
        _shouldShowLoading = true;
      });

      _authService.singIn(formValues).then((result) {
        if (result['success'] == true) {
          formValues = AuthForm();
          setState(() {
            _shouldShowLoading = false;
          });
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  result == null ? 'Could not login' : result['error'],
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

  void _showTermsWarning() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
        'Please agree to the Terms of Service to continue',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: errorColor,
      dismissDirection: DismissDirection.horizontal,
      showCloseIcon: true,
    ));
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
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: ListView(
        controller: listViewController,
        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
        children: [
          SizedBox(height: defaultPadding * 5),
          SvgPicture.asset(logoTheme, width: 150),
          Center(
            child: Text('More Than E2E Encryption'),
          ),
          SizedBox(height: defaultPadding * 3),
          Text(
            "Sign-In",
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: defaultPadding / 1.5),
          Form(
            key: _form,
            child: Column(
              children: [
                EvercryptedTextField(
                  controller: _emailField,
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
                  onChanged: (val) {
                    setState(() {
                      formValues.email = val;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                  child: EvercryptedTextField(
                    controller: _passController,
                    obscureText: !_passwordVisible,
                    hintText: 'Password',
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
                    onChanged: (val) {
                      setState(() {
                        formValues.password = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: defaultPadding * 2),
                PrimaryButton(
                  press: () => submitForm(context),
                  child: _shouldShowLoading
                      ? const SpinKitThreeBounce(
                          color: Colors.white,
                          size: 17,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.login,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sign In',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                ),
                const OrDivider(),
                TermsCheckbox(
                  value: _agreedToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreedToTerms = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: defaultPadding * 1.5),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, SignUpScreen.routeName);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Sign up with email',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: defaultPadding * 1.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialLoginIconButton(
                      provider: SocialProvider.google,
                      onPressed: _handleGoogleSignIn,
                      isLoading: _googleLoading,
                      disabled: !_agreedToTerms,
                      onDisabledTap: _showTermsWarning,
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
                        disabled: !_agreedToTerms,
                        onDisabledTap: _showTermsWarning,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: defaultPadding * 1.5),
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height *
                            0.8, // 80% of screen height
                      ),
                      builder: (BuildContext context) => const ResetPassword(),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
                const SizedBox(height: defaultPadding * 2),
                const TermsAndPrivacyLinks(),
                SizedBox(height: defaultPadding * 2),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
