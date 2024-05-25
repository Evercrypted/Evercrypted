import 'package:evercrypted/core/socket/socket.dart';
import 'package:flutter/material.dart';
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
      await Auth.setToken(
        newToken: newToken,
        skipNotify: true,
      );
    }
    if (newIsOtpActive != null) {
      await Auth.setIsOtpActive(
        isOtpActive: newIsOtpActive,
        skipNotify: true,
      );
    }
    authSubject.add(true);
  }

  static get getToken async {
    try {
      if (token == null) {
        final fromStorage = await storage.read(key: 'token');
        token = fromStorage;
        print('token $token');
      }
      return token;
    } catch (e) {
      return null;
    }
  }

  static setToken({newToken, skipNotify = false}) async {
    Auth.token = newToken;
    await storage.write(key: 'token', value: newToken);
    if (skipNotify) {
      return;
    }
    authSubject.add(true);
  }

  static clearToken({skipNotify = false}) async {
    Auth.token = null;
    try {
      await storage.delete(key: 'token');
    } catch (e) {
      debugPrint('Error clearing token');
    }
    if (skipNotify) {
      return;
    }
    authSubject.add(true);
  }

  static get getOtpToken async {
    try {
      if (otpToken == null) {
        final fromStorage = await storage.read(key: 'otpToken');
        otpToken = fromStorage;
      }
      return otpToken;
    } catch (e) {
      return null;
    }
  }

  static setOtpToken({otpToken, skipNotify = false}) async {
    Auth.otpToken = otpToken;
    storage.write(key: 'otpToken', value: otpToken);
    if (skipNotify) {
      return;
    }
    authSubject.add(true);
  }

  static clearOtpToken({skipNotify = false}) async {
    Auth.otpToken = null;
    try {
      await storage.delete(key: 'otpToken');
    } catch (e) {
      debugPrint('Error clearing otp token');
    }
    if (skipNotify) {
      return;
    }
    authSubject.add(true);
  }

  static get getIsOtpActive async {
    try {
      if (isOtpActive == null) {
        final fromStorage = await storage.read(key: 'isOtpActive');
        isOtpActive = fromStorage == 'true';
      }
      return isOtpActive;
    } catch (e) {
      return null;
    }
  }

  static setIsOtpActive({isOtpActive, skipNotify = false}) async {
    Auth.isOtpActive = isOtpActive;
    storage.write(key: 'isOtpActive', value: isOtpActive.toString());
    if (skipNotify) {
      return;
    }
    authSubject.add(true);
  }

  static clearAuth() async {
    Auth.user = null;
    Auth.isOtpActive = false;
    await Auth.clearOtpToken(skipNotify: true);
    await Auth.clearToken(skipNotify: true);
    ChatSocket.disconnectWS();
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
