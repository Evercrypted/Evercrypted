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
      aOptions: AndroidOptions(encryptedSharedPreferences: true));

  static setAuth({AuthUser? newUser, String? newToken, bool? newIsOtpActive}) {
    Auth.user = newUser ?? user;
    Auth.token = newToken ?? token;
    Auth.isOtpActive = newIsOtpActive ?? isOtpActive;
    authSubject.add(true);
  }

  static get getToken async {
    if (token == null) {
      final fromStorage = await storage.read(key: 'token');
      token = fromStorage;
    }
    return token;
  }

  static setToken(String token) async {
    Auth.token = token;
    await storage.delete(key: 'token');
    storage.write(key: 'token', value: token);
    authSubject.add(true);
  }

  static clearToken() {
    Auth.token = null;
    storage.delete(key: 'token');
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
    await storage.delete(key: 'otpToken');
    storage.write(key: 'otpToken', value: otpToken);
    authSubject.add(true);
  }

  static clearOtpToken() {
    Auth.otpToken = null;
    storage.delete(key: 'otpToken');
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
    await storage.delete(key: 'isOtpActive');
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
