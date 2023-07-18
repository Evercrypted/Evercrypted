import 'package:dio/dio.dart';
import 'package:evercrypted/core/http.dart';
import 'package:isar/isar.dart';

import 'profile_model.dart';

class ProfileService {
  Future<Response> checkProfileExists(String token) async {
    return dio.post('/users/checkUserExists', data: {});
  }

  void syncProfile(Profile profile) async {
    final isar = Isar.getInstance();
    return await isar?.writeTxn(() async {
      return isar.profiles.clear().then((value) async {
        await isar.profiles.put(profile);
      });
    });
  }
}
