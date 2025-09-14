import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_text_controller.dart';
import 'package:evercrypted/core/services/auth_service.dart';
import 'package:evercrypted/core/helpers/field_validators.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/screens/auth/components/reset_password.dart';
import 'package:evercrypted/widgets/evercrypted_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../widgets/primary_button.dart';
import '../../ui_constants.dart';
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
  AuthForm formValues = AuthForm();
  final EvercryptedTextController _emailField = EvercryptedTextController();
  final EvercryptedTextController _passController = EvercryptedTextController();
  final AuthService _authService = AuthService();
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
          SvgPicture.asset(logoTheme, width: 150),
          SizedBox(height: defaultPadding * 2),
          Center(
            child: Text(
              "Sign In",
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
                  controller: _emailField,
                  decoration: const InputDecoration(
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
                    onChanged: (val) {
                      setState(() {
                        formValues.password = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: defaultPadding * 2),
                PrimaryButton(
                  text: 'Sign In',
                  press: () => submitForm(context),
                  child: _shouldShowLoading
                      ? const SpinKitThreeBounce(
                          color: Colors.white,
                          size: 17,
                        )
                      : null,
                ),
                const SizedBox(height: defaultPadding),
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
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, SignUpScreen.routeName);
                  },
                  child: Text.rich(
                    TextSpan(
                      text: "Don’t have an account? ",
                      children: [
                        TextSpan(
                          text: "Sign Up",
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
