import 'package:evercrypted/core/services/auth_service.dart';
import 'package:evercrypted/core/helpers/field_validators.dart';
import 'package:evercrypted/widgets/secret_keyboard/secret_input.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../widgets/primary_button.dart';
import '../../ui_constants.dart';
import './forgot_password_screen.dart';
import './sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SignInScreen extends StatefulWidget {
  static const routeName = '/sign-in';

  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _shouldShowLoading = false;
  AuthForm formValues = AuthForm();
  final TextEditingController _emailField = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final _passFocus = FocusNode();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    // TODO: implement dispose
    _emailField.dispose();
    _passController.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void submitForm(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_form.currentState!.validate()) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Column(
                children: [
                  SizedBox(height: constraints.maxHeight * 0.1),
                  SvgPicture.asset(logoTheme, width: 150),
                  SizedBox(height: constraints.maxHeight * 0.1),
                  Text(
                    "Sign In",
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
                          controller: _emailField,
                          validator: validateEmail,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                          ),
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.none,
                          onTap: () {
                            openSecretInput(
                                fieldName: 'Email',
                                context: context,
                                controller: _emailField,
                                isSingleLine: true,
                                done: (val) {
                                  formValues.email = val.text;
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
                                          formValues.password = val.text;
                                          submitForm(context);
                                        });
                                  }
                                });
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: defaultPadding),
                          child: TextFormField(
                            controller: _passController,
                            focusNode: _passFocus,
                            textInputAction: TextInputAction.next,
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
                                  isPasswordLike: true,
                                  isSingleLine: true,
                                  context: context,
                                  controller: _passController,
                                  done: (val) {
                                    formValues.password = val.text;
                                    submitForm(context);
                                  });
                            },
                          ),
                        ),
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
                          onPressed: () => Navigator.pushNamed(
                            context,
                            ForgotPasswordScreen.routeName,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                                context, SignUpScreen.routeName);
                          },
                          child: Text.rich(
                            TextSpan(
                              text: "Don’t have an account? ",
                              children: [
                                TextSpan(
                                  text: "Sign Up",
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor),
                                ),
                              ],
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
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
          },
        ),
      ),
    );
  }
}
