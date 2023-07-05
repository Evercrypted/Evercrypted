import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsService {
  static const String otpTokenPrefix = 'otpToken-';
  final storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true));

  final currentUser = FirebaseAuth.instance.currentUser;

  getOtpToken() {
    return storage.read(key: otpTokenPrefix + currentUser!.uid);
  }

  updateOtpToken(String otpToken) {
    return storage.write(
        key: otpTokenPrefix + currentUser!.uid, value: otpToken);
  }

  deleteOtpToken() {
    return storage.delete(key: otpTokenPrefix + currentUser!.uid);
  }
}
