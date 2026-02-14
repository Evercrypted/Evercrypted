const requiredField = "This field is required.";
const invalidEmail = "Enter a valid email address.";
const badPass =
    'Passwords must be at least 8 characters and include an uppercase letter, a lowercase letter, a number, and a special character.';

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
  }

  final missing = <String>[];

  if (pass.length < 8) {
    missing.add('at least 8 characters');
  }
  if (!RegExp(r'[A-Z]').hasMatch(pass)) {
    missing.add('an uppercase letter');
  }
  if (!RegExp(r'[a-z]').hasMatch(pass)) {
    missing.add('a lowercase letter');
  }
  if (!RegExp(r'\d').hasMatch(pass)) {
    missing.add('a number');
  }
  if (!RegExp(r'[@$!%*?&]').hasMatch(pass)) {
    missing.add('a special character (@\$!%*?&)');
  }

  if (missing.isNotEmpty) {
    return 'Password must include: ${missing.join(', ')}.';
  }

  return null;
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
