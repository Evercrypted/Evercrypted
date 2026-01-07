import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:evercrypted/core/auth.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService(
    LocalAuthentication(),
  );
});

class BiometricService {
  final LocalAuthentication _auth;

  BiometricService(this._auth);

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access Evercrypted',
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await Auth.setBiometricEnabled(enabled);
  }

  Future<bool> isBiometricEnabled() async {
    return await Auth.getIsBiometricEnabled;
  }
}
