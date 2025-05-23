import 'dart:convert';

import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/core/helpers/get_random_string.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rxdart/subjects.dart';

class Auth {
  Auth._();

  static BehaviorSubject<bool> authSubject = BehaviorSubject<bool>();

  static ProfileService profileService = ProfileService();

  static AuthUser? user;
  static String? token;
  static String? refreshToken;
  static bool? isOtpActive;
  static String? otpToken;
  static String? appKey;

  static const storage = FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      aOptions: AndroidOptions());

  static setAppKey() async {
    final random = getRandomString(32);
    await storage.write(key: 'appKey', value: random);
    appKey = random;
    return random;
  }

  static Future<String?> get appKeyFromStorage async {
    return await storage.read(key: 'appKey');
  }

  static Future<String> get getAppKey async {
    if (appKey == null) {
      final fromStorage = await storage.read(key: 'appKey');
      appKey = fromStorage;
    }
    return appKey!;
  }

  static setAuth(
      {Profile? profile, String? newToken, bool? newIsOtpActive}) async {
    if (profile != null) {
      profileService.syncProfile(profile);
      Auth.user = AuthUser(
          email: profile.email!,
          uid: profile.uid,
          emailVerified: profile.emailVerified,
          activated: profile.activatedForLife,
          activationTokenQuantity: profile.activationTokenQuantity);
    }
    if (newToken != null) {
      await Auth.setToken(
        newToken: newToken,
        skipNotify: true,
      );
      if (ChatSocket.key != null) {
        final cryptedToken = await encodePayload(newToken, ChatSocket.key);
        if (cryptedToken != null) {
          HttpClient.addAuth(jsonEncode(cryptedToken), getUser!.uid);
        }
      }
    }
    if (newIsOtpActive != null) {
      await Auth.setIsOtpActive(
        isOtpActive: newIsOtpActive,
        skipNotify: true,
      );
    }
    authSubject.add(true);
  }

  static AuthUser? get getUser {
    if (Auth.user == null) {
      final Profile? profile = profileService.getProfile();
      if (profile == null) {
        return null;
      }
      Auth.user = AuthUser(
          email: profile.email!,
          uid: profile.uid,
          emailVerified: profile.emailVerified,
          activated: profile.activatedForLife,
          activationTokenQuantity: profile.activationTokenQuantity);
    }
    return Auth.user;
  }

  static updateEmailVerified({required bool emailVerified}) {
    if (Auth.getUser != null) {
      Auth.user = AuthUser(
          email: Auth.user!.email,
          uid: Auth.user!.uid,
          emailVerified: emailVerified);
    }
    profileService.updateProfileEmailVerified(emailVerified: emailVerified);
    authSubject.add(true);
  }

  static get getToken async {
    try {
      if (token == null) {
        final fromStorage = await storage.read(key: 'token');
        token = fromStorage;
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
    obx.profiles.removeAll();
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
  final bool? activated;
  final int? activationTokenQuantity;

  AuthUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    this.activated,
    this.activationTokenQuantity,
  });
}
