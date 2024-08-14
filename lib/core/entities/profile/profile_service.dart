import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/fernet.dart';
import 'package:isar/isar.dart';

import 'profile_model.dart';

class ProfileService {
  void syncProfile(Profile profile) async {
    final isar = Isar.getInstance();

    final String appKey = await Auth.getAppKey;

    return await isar?.writeTxn(() async {
      return isar.profiles.clear().then((value) async {
        await isar.profiles.put(profile.copyWith(
            email: fernetEncrypt(profile.email, appKey),
            name: fernetEncrypt(profile.name, appKey)));
      });
    });
  }

  void updateProfileEmailVerified({required bool emailVerified}) async {
    final isar = Isar.getInstance();
    final profile = isar?.profiles.where().findFirstSync();
    if (profile != null) {
      profile.emailVerified = emailVerified;
      await isar?.writeTxn(() async {
        isar.profiles.put(profile);
      });
    }
  }

  Profile? getProfile() {
    final isar = Isar.getInstance();
    return isar?.profiles.where().findFirstSync()!;
  }
}
