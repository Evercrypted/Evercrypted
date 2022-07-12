import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../screens/auth/sign_up_screen.dart';

class AuthService {
  Future signUp(SignUpForm formValues) async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: formValues.email!,
        password: formValues.password!,
      );
      return {'success': true, 'result': credential};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return {
          'success': false,
          'message': 'The password provided is too weak.'
        };
      } else if (e.code == 'email-already-in-use') {
        return {
          'success': false,
          'message': 'The account already exists for that email.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
