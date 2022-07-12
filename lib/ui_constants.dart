import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

const primaryColor = Color(0xFF00BF6D);
const secondaryColor = Color(0xFFFE9901);
const contentColorLightTheme = Color(0xFF1D1D35);
const contentColorDarkTheme = Color(0xFFF5FCF9);
const warninngColor = Color(0xFFF3BB1C);
const errorColor = Color(0xFFF03738);

const defaultPadding = 16.0;

const logoDarkTheme = "assets/icons/Only_logo_dark_theme.svg";
const logoLightTheme = "assets/icons/Only_logo_light_theme.svg";

const requiredField = "This field is required";
const invalidEmail = "Enter a valid email address";

final passwordValidator = MultiValidator(
  [
    RequiredValidator(errorText: requiredField),
    MinLengthValidator(8, errorText: 'Password must be at least 8 digits long'),
    PatternValidator(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
        errorText:
            'Passwords must have at least one uppercase letter, one lowercase letter, one number and one special character.')
  ],
);

const InputDecoration otpInputDecoration = InputDecoration(
  filled: false,
  border: UnderlineInputBorder(),
  hintText: "0",
);
