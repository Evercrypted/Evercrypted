import 'package:evercrypted/core/auth/auth_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../widgets/primary_button.dart';
import '../../ui_constants.dart';
import './forgot_password_screen.dart';
import './sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:form_field_validator/form_field_validator.dart';

class SignInScreen extends StatefulWidget {
  static const routeName = '/sign-in';

  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();

  bool _passwordVisible = false;
  bool _shouldShowLoading = false;

  AuthForm formValues = AuthForm();

  final AuthService _authService = AuthService();

  void submitForm() async {
    FocusManager.instance.primaryFocus?.unfocus();
    formValues = AuthForm();

    if (_form.currentState!.validate()) {
      _form.currentState!.save();

      if (formValues.email != null && formValues.password != null) {
        setState(() {
          _shouldShowLoading = true;
        });

        _authService.singIn(formValues).then((result) {
          if (result['success']) {
            setState(() {
              _shouldShowLoading = false;
            });
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
          if (!mounted) return;
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
                        .headline5!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.05),
                  Form(
                    key: _form,
                    child: Column(
                      children: [
                        TextFormField(
                          validator: EmailValidator(errorText: requiredField),
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
                        PrimaryButton(
                          text: 'Sign In',
                          press: submitForm,
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
                            Navigator.pushReplacementNamed(
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
                            style:
                                Theme.of(context).textTheme.bodyText2!.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyText1!
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
