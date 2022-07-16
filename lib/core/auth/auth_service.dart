import 'package:evercrypted/core/profile/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthForm {
  String? email;
  String? password;

  AuthForm({this.email, this.password});
}

class AuthService {
  final ProfileService _profileService = ProfileService();

  Future signUp(AuthForm formValues) async {
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

  Future singIn(AuthForm formValues) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: formValues.email!,
        password: formValues.password!,
      );
      return {'success': true, 'result': credential};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return {'success': false, 'message': 'No user found for that email.'};
      } else if (e.code == 'wrong-password') {
        return {
          'success': false,
          'message': 'Wrong password provided for that user.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
