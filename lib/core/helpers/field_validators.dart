const requiredField = "This field is required.";
const invalidEmail = "Enter a valid email address.";
const badPass =
    'Passwords must have at least one uppercase letter, one lowercase letter, one number and one special character.';

String? validateEmail(String? email) {
  RegExp regex = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  if (email == null) {
    return null;
  } else if (!regex.hasMatch(email)) {
    return invalidEmail;
  } else {
    return null;
  }
}

String? validatePassword(String? pass) {
  if (pass == null) {
    return null;
  } else if (!RegExp(
          r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
      .hasMatch(pass)) {
    return badPass;
  } else {
    return null;
  }
}

String? requiredValidator(String? val) {
  if (val == null) {
    return null;
  } else if (val.isEmpty) {
    return requiredField;
  } else {
    return null;
  }
}

String? minLengthValidator(String? val, int minLength) {
  if (val == null) {
    return null;
  } else if (val.length < minLength) {
    return "This field must be at least $minLength characters long.";
  } else {
    return null;
  }
}

String? maxLengthValidator(String? val, int maxLength) {
  if (val == null) {
    return null;
  }
  if (val.length > maxLength) {
    return "This field must be at most $maxLength characters long.";
  } else {
    return null;
  }
}
