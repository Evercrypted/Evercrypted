import 'package:dio/dio.dart';
import 'package:evercrypted/core/socket/event_types/settings_event_types.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../http.dart';

class SettingsService {
  static const String otpTokenPrefix = 'otpToken-';
  final storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true));

  final currentUser = FirebaseAuth.instance.currentUser;

  Future<Response<dynamic>> otpLogin(String otpCode) {
    return dio.post('/settings', data: {
      'type': SettingsEventTypes.login2FA,
      'payload': {'code': otpCode}
    });
  }

  getOtpToken() {
    return storage.read(key: otpTokenPrefix + currentUser!.uid);
  }

  updateOtpToken(String otpToken) async {
    await storage.delete(key: otpTokenPrefix + currentUser!.uid);
    return storage.write(
        key: otpTokenPrefix + currentUser!.uid, value: otpToken);
  }

  deleteOtpToken() {
    return storage.delete(key: otpTokenPrefix + currentUser!.uid);
  }
}
