import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsService {
  final storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true));

  getOtpToken() {
    return storage.read(key: 'otpToken');
  }

  updateOtpToken(String otpToken) {
    return storage.write(key: 'otpToken', value: otpToken);
  }

  deleteOtpToken() {
    return storage.delete(key: 'otpToken');
  }
}
