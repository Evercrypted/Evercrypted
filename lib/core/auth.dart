import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rxdart/subjects.dart';

class Auth {
  Auth._();

  static BehaviorSubject<bool> authSubject = BehaviorSubject<bool>();

  static AuthUser? user;
  static String? token;
  static String? refreshToken;
  static bool? isOtpActive;
  static String? otpToken;

  static const storage = FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      aOptions: AndroidOptions(encryptedSharedPreferences: true));

  static setAuth(
      {AuthUser? newUser, String? newToken, bool? newIsOtpActive}) async {
    Auth.user = newUser ?? user;
    if (newToken != null) {
      await Auth.setToken(newToken);
    }
    if (newIsOtpActive != null) {
      await Auth.setIsOtpActive(newIsOtpActive);
    }
    authSubject.add(true);
  }

  static get getToken async {
    if (token == null) {
      final fromStorage = await storage.read(key: 'token');
      token = fromStorage;
      print('token $token');
    }
    return token;
  }

  static setToken(String newToken) async {
    Auth.token = newToken;
    await storage.write(key: 'token', value: newToken);
    authSubject.add(true);
  }

  static clearToken() async {
    Auth.token = null;
    await storage.delete(key: 'token');
    authSubject.add(true);
  }

  static get getOtpToken async {
    if (otpToken == null) {
      final fromStorage = await storage.read(key: 'otpToken');
      otpToken = fromStorage;
    }
    return otpToken;
  }

  static setOtpToken(String otpToken) async {
    Auth.otpToken = token;
    storage.write(key: 'otpToken', value: otpToken);
    authSubject.add(true);
  }

  static clearOtpToken() async {
    Auth.otpToken = null;
    await storage.delete(key: 'otpToken');
    authSubject.add(true);
  }

  static get getIsOtpActive async {
    if (isOtpActive == null) {
      final fromStorage = await storage.read(key: 'isOtpActive');
      isOtpActive = fromStorage == 'true';
    }
    return isOtpActive;
  }

  static setIsOtpActive(bool isOtpActive) async {
    Auth.isOtpActive = isOtpActive;
    storage.write(key: 'isOtpActive', value: isOtpActive.toString());
    authSubject.add(true);
  }

  static clearAuth() {
    Auth.user = null;
    Auth.token = null;
    Auth.isOtpActive = false;
    Auth.clearOtpToken();
    Auth.clearToken();
    authSubject.add(true);
  }
}

class AuthUser {
  final String uid;
  final String email;
  final bool emailVerified;

  AuthUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
  });
}
