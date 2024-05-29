import 'package:isar/isar.dart';

import 'profile_model.dart';

class ProfileService {
  void syncProfile(Profile profile) async {
    final isar = Isar.getInstance();
    return await isar?.writeTxn(() async {
      return isar.profiles.clear().then((value) async {
        await isar.profiles.put(profile);
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
}
