class Auth {
  Auth._();
  static AuthUser? user;

  static setAuth(String uid, String email, String token, emailVerified) {
    Auth.user = AuthUser(
        uid: uid, email: email, token: token, emailVerified: emailVerified);
  }

  static clearAuth() {
    Auth.user = null;
  }
}

class AuthUser {
  AuthUser({
    required this.uid,
    required this.email,
    required this.token,
    required this.emailVerified,
  });
  final String uid;
  final String email;
  final String token;
  final bool emailVerified;
}
