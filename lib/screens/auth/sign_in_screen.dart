import '../../widgets/primary_button.dart';
import '../../ui_constants.dart';
import './forgot_password_screen.dart';
import './sign_up_screen.dart';
import '../main/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:form_field_validator/form_field_validator.dart';

class SignInScreen extends StatelessWidget {
  static const routeName = '/sign-in';
  final _formKey = GlobalKey<FormState>();
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
                  SvgPicture.asset(
                    MediaQuery.of(context).platformBrightness == Brightness.dark
                        ? logoDarkTheme
                        : logoLightTheme,
                  ),
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
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          validator:
                              RequiredValidator(errorText: requiredField),
                          decoration: InputDecoration(hintText: 'Phone'),
                          keyboardType: TextInputType.phone,
                          onSaved: (phone) {
                            // Save it
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: defaultPadding),
                          child: TextFormField(
                            validator: passwordValidator,
                            obscureText: true,
                            decoration: InputDecoration(hintText: 'Password'),
                            onSaved: (passaword) {
                              // Save it
                            },
                          ),
                        ),
                        PrimaryButton(
                          text: 'Sign in',
                          press: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MainScreen(),
                                ),
                              );
                            }
                          },
                        ),
                        SizedBox(height: defaultPadding),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgotPasswordScreen(),
                            ),
                          ),
                          child: Text(
                            'Forgot Password?',
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
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignUpScreen(),
                              ),
                            );
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
